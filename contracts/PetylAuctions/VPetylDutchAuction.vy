# @version ^0.2.2


# ----------------------------------------------------------------------------
#  Petyl Dutch Auction 
# 
#  MVP prototype in Vyper. DO NOT USE!
#                         
#  (c) Adrian Guerrera. Deepyr Pty Ltd.                            
#  July 23 2020   
#                               
#  SPDX-License-Identifier: MIT
# ----------------------------------------------------------------------------


ETH_ADDRESS: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
TENPOW18: constant(uint256) = pow_mod256(10,18)

interface IERC20:
    def decimals() -> uint256: view
    def balanceOf(addr: address) -> uint256: view
    def approve(spender: address, amount: uint256) -> bool: nonpayable
    def transfer(to: address, amount: uint256) -> bool: nonpayable
    def transferFrom(spender: address, to: address, amount: uint256) -> bool: nonpayable


event AddedCommitment:
    addr: indexed(address)
    commitment: indexed(uint256)
    price: uint256


amountRaised: public(uint256)
startDate: public(uint256)
endDate: public(uint256)
startPrice: public(uint256)
minimumPrice: public(uint256)
tokenSupply: public(uint256)
finalised: public(bool)
auctionToken: public(address)
paymentCurrency: public(address)
wallet: public(address) 
commitments: HashMap[address, uint256]

@external
def initDutchAuction(
    _funder: address, _token: address, 
    _tokenSupply: uint256, _startDate: uint256,
    _endDate: uint256, 
    _paymentCurrency: address , 
    _startPrice: uint256, 
    _minimumPrice: uint256, 
    _wallet: address   
    ):

    assert _endDate > _startDate
    assert _startPrice > _minimumPrice
    assert _minimumPrice > 0 

    self.auctionToken = _token
    self.paymentCurrency = _paymentCurrency

    assert IERC20(self.auctionToken).transferFrom(_funder, self, _tokenSupply)

    self.tokenSupply =_tokenSupply
    self.startDate = _startDate
    self.endDate = _endDate
    self.startPrice = _startPrice
    self.minimumPrice = _minimumPrice 
    self.wallet = _wallet

    # // Dutch Auction Price Function
    # // ============================
    # //  
    # // Start Price ----- 
    # //                   \ 
    # //                    \
    # //                     \
    # //                      \ ------------ Clearing Price
    # //                     / \            = AmountRaised/TokenSupply
    # //      Token Price  --   \
    # //                  /      \ 
    # //                --        ----------- Minimum Price
    # // Amount raised /          End Time
    # //

    self.finalised = False


@internal
@view
def _tokenPrice() -> uint256:
    return self.amountRaised * TENPOW18 / self.tokenSupply

@internal
@view
def _priceGradient() -> uint256:
    """
    @notice Token price decreases at this rate during auction.
    """
    numerator: uint256 = self.startPrice - self.minimumPrice
    denominator: uint256 = self.endDate - self.startDate
    return numerator / denominator

@internal
@view
def _priceFunction() -> uint256:
    """
    @notice Returns price during the auction 
    @dev Return Auction Price
    """

    if (block.timestamp <= self.startDate):
        return self.startPrice

    if (block.timestamp >= self.endDate):
        return self.minimumPrice
    
    timeDiff: uint256 = (block.timestamp - self.startDate)
    price: uint256 = self.startPrice - timeDiff * self._priceGradient()
    return price

@internal
@view
def _clearingPrice() -> uint256:
    """
    @notice The current clearing price of the Dutch auction.
    @dev If auction successful, return tokenPrice
    """

    if (self._tokenPrice() > self._priceFunction()):
        return self._tokenPrice()
    else:
        return self._priceFunction()


@internal
@view
def _tokensClaimable(_user: address) -> uint256:
    """
    @notice How many tokens the user is able to claim
    """
    return self.commitments[_user] * TENPOW18 / self._clearingPrice()


@internal
@view
def _totalTokensCommitted() -> uint256:
    """
    @notice Total amount of tokens committed at current auction price
    """
    return self.amountRaised * TENPOW18 / self._clearingPrice()


@internal
@view
def _auctionSuccessful() -> bool:
    """
    @notice Successful if tokens sold equals tokenSupply
    """
    return self._totalTokensCommitted() >= self.tokenSupply and self._tokenPrice() >= self.minimumPrice


@internal
@view
def _auctionEnded() -> bool:
    """
    @notice Returns bool if successful or time has ended
    """
    return self._auctionSuccessful() or block.timestamp > self.endDate


# --------------------------------------------------------
# Commit to buying tokens 
# --------------------------------------------------------

@internal
@view
def _calculateCommitment( _commitment: uint256) -> uint256:
    """
    @notice Returns the amout able to be committed during an auction
    """

    maxCommitment: uint256 = self.tokenSupply * self._clearingPrice() / TENPOW18
    if (self.amountRaised + _commitment > maxCommitment):
        return maxCommitment - self.amountRaised
    else:
        return _commitment


@internal
def _addCommitment(_addr: address, _commitment: uint256):
    """
    @notice Commits to an amount during an auction
    """

    assert block.timestamp >= self.startDate and block.timestamp <= self.endDate
    self.commitments[_addr] = self.commitments[_addr] + _commitment
    self.amountRaised = self.amountRaised + _commitment
    log AddedCommitment(_addr, _commitment, self._tokenPrice())


@internal
def _commitEth(_from: address, _amount: uint256):
    """
    @notice Internal commit ETH to buy tokens on sale
    """

    assert self.paymentCurrency == ETH_ADDRESS
    #  Get ETH able to be committed
    ethToTransfer: uint256 = self._calculateCommitment( _amount)

    #  Accept ETH Payments
    ethToRefund: uint256 = _amount - ethToTransfer
    if (ethToTransfer > 0):
        self._addCommitment(_from, ethToTransfer)

    # // Return any ETH to be refunded
    if (ethToRefund > 0):
        send(_from, ethToRefund)


@internal
def _commitTokensFrom(_from: address, _amount: uint256):
    """
    @dev Users must approve contract prior to committing tokens to auction
    """

    assert self.paymentCurrency != ETH_ADDRESS

    tokensToTransfer: uint256 = self._calculateCommitment(_amount)
    if (tokensToTransfer > 0):
        assert IERC20(self.paymentCurrency).transferFrom(_from, self, _amount)
        self._addCommitment(_from, tokensToTransfer)


# --------------------------------------------------------
# Externals functions for token commitments
# --------------------------------------------------------

@external
@payable
@nonreentrant("lock")
def __default__():
    """
    @notice Buy Tokens by committing ETH to this contract address 
    """
    self._commitEth(msg.sender, msg.value)


@external
@payable
@nonreentrant("lock")
def commitEth(_from: address):
    """
    @notice Commit ETH to buy tokens on sale
    """
    self._commitEth(_from, msg.value)


@external
@nonreentrant("lock")
def commitTokens(_amount: uint256):
    """
    @notice Commit approved ERC20 tokens to buy tokens on sale
    """
    self._commitTokensFrom(msg.sender, _amount)



# --------------------------------------------------------
#  Finalise Auction
# --------------------------------------------------------

@internal
def _tokenPayment(_token: address, _to: address, _amount: uint256):
    """
    @dev Helper function to handle both ETH and ERC20 payments
    """

    if (_token == ETH_ADDRESS):
        send(_to, _amount)
    else:
        assert IERC20(_token).transfer(_to, _amount)

@external
@payable
@nonreentrant("lock")
def finaliseAuction():
    """
    @notice Auction finishes successfully above the reserve
    @dev Transfer contract funds to initialised wallet. 
    """

    assert not self.finalised 
        
    # @notice Auction did not meet reserve price.
    if( self._auctionEnded() and self._tokenPrice() < self.minimumPrice ):
        self._tokenPayment(self.auctionToken, self.wallet, self.tokenSupply)
        self.finalised = True
        return
    
    # @notice Successful auction! Transfer tokens bought.
    if (self._auctionSuccessful()):
        self._tokenPayment(self.paymentCurrency, self.wallet, self.amountRaised)
        self.finalised = True


@external
@payable
@nonreentrant("lock")
def withdrawTokens():
    """
    @notice Withdraw your tokens once the Auction has ended.
    """

    fundsCommitted: uint256 = self.commitments[ msg.sender]
    tokensToClaim: uint256 = self._tokensClaimable(msg.sender)
    self.commitments[ msg.sender] = 0

    # /// @notice Auction did not meet reserve price.
    # /// @dev Return committed funds back to user.
    if( self._auctionEnded() and self._tokenPrice() < self.minimumPrice ):
        self._tokenPayment(self.paymentCurrency, msg.sender, fundsCommitted)      
        return

    # /// @notice Successful auction! Transfer tokens bought.
    # /// @dev AG: Should hold and distribute tokens vs mint
    # /// @dev AG: Could be only > min to allow early withdraw  
    if (self._auctionSuccessful() and tokensToClaim > 0 ):
        self._tokenPayment(self.auctionToken, msg.sender, tokensToClaim)



# --------------------------------------------------------
#  External Getter Functions
# --------------------------------------------------------

@external
@view
def tokenPrice() -> uint256:
    return self._tokenPrice()

@external
@view
def priceGradient() -> uint256:
    """
    @notice Token price decreases at this rate during auction.
    """
    return self._priceGradient()


@external
@view
def priceFunction() -> uint256:
    """
    @notice Returns price during the auction 
    @dev Return Auction Price
    """
    return self._priceFunction()


@external
@view
def clearingPrice() -> uint256:
    """
    @notice The current clearing price of the Dutch auction.
    """
    return self._clearingPrice()


@external
@view
def tokensClaimable(_user: address) -> uint256:
    """
    @notice How many tokens the user is able to claim
    """
    return self._tokensClaimable(_user)


@external
@view
def totalTokensCommitted() -> uint256:
    """
    @notice Total amount of tokens committed at current auction price
    """
    return self._totalTokensCommitted()


@external
@view
def auctionSuccessful() -> bool:
    """
    @notice Successful if tokens sold equals tokenSupply
    """
    return self._auctionSuccessful()


@external
@view
def auctionEnded() -> bool:
    """
    @notice Returns bool if successful or time has ended
    """
    return self._auctionEnded()
