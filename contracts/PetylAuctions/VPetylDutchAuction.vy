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
    addr: indexed(uint256)
    commitment: indexed(address)
    price: uint256


amountRaised: public(uint256)
startDate: public(uint256)
endDate: public(uint256)
startPrice: public(uint256)
minimumPrice: public(uint256)
tokenSupply: public(uint256)
finalised: public(bool)
auctionToken: public(IERC20)
paymentCurrency: public(IERC20)
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

    self.auctionToken = IERC20(_token)
    self.paymentCurrency = IERC20(_paymentCurrency)

    assert IERC20(self.auctionToken).transferFrom(_funder, address(this), _tokenSupply))

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

    self.finalised = false


@external
@view
def tokenPrice() -> uint256:
    return self.amountRaised * TENPOW18 / self.tokenSupply

@external
@view
def priceGradient() -> uint256:
    """
    @notice Token price decreases at this rate during auction.
    """
    numerator: uint256 = self.startPrice - self.minimumPrice
    denominator: uint256 = self.endDate - self.startDate
    return numerator / denominator

@external
@view
def priceFunction() -> uint256:
    """
    @notice Returns price during the auction 
    @dev Return Auction Price
    """

    if (block.timestamp <= self.startDate):
        return startPrice

    if (block.timestamp >= self.endDate):
        return minimumPrice
    
    priceDiff: uint256 = (block.timestamp - self.startDate) * priceGradient()
    price: uint256 = self.startPrice - priceDiff
    return price

@external
@view
def clearingPrice() -> uint256:
    """
    @notice The current clearing price of the Dutch auction.
    @dev If auction successful, return tokenPrice
    """
    if (tokenPrice() > priceFunction()):
        return tokenPrice()
    else:
        return priceFunction()

@external
@view
def tokensClaimable(_user: address) -> uint256:
    """
    @notice How many tokens the user is able to claim
    """
    return self.commitments[_user] * TENPOW18 / clearingPrice()


@external
@view
def totalTokensCommitted() -> uint256:
    """
    @notice Total amount of tokens committed at current auction price
    """
    return self.amountRaised * TENPOW18 / clearingPrice()


@external
@view
def auctionSuccessful() -> bool:
    """
    @notice Successful if tokens sold equals tokenSupply
    """
    return totalTokensCommitted() >= self.tokenSupply and tokenPrice() >= self.minimumPrice


@external
@view
def auctionEnded() -> bool:
    """
    @notice Returns bool if successful or time has ended
    """
    return auctionSuccessful() or block.timestamp > self.endDate


# --------------------------------------------------------
# Commit to buying tokens 
# --------------------------------------------------------

@external
@payable
def __default__():
    """
    @notice Buy Tokens by committing ETH to this contract address 
    """
    commitEth(msg.sender)


@external
@payable
def commitEth(_from: address):
    """
    @notice Commit ETH to buy tokens on sale
    """

    assert address(self.paymentCurrency) == ETH_ADDRESS
    #  Get ETH able to be committed
    ethToTransfer: uint256 = calculateCommitment( msg.value)

    #  Accept ETH Payments
    ethToRefund: uint256 = msg.value - self.ethToTransfer
    if (ethToTransfer > 0):
        addCommitment(_from, ethToTransfer)

    # // Return any ETH to be refunded
    if (ethToRefund > 0):
        _from.transfer(ethToRefund)


@internal
def addCommitment(_addr: address, _commitment: uint256):
    """
    @notice Commits to an amount during an auction
    """

    assert block.timestamp >= self.startDate && block.timestamp <= self.endDate)
    self.commitments[_addr] = self.commitments[_addr] + _commitment
    self.amountRaised = self.amountRaised + _commitment
    log AddedCommitment(_addr, _commitment, tokenPrice())
    

@external
def commitTokens(_amount: uint256):
    """
    @notice Commit approved ERC20 tokens to buy tokens on sale
    """
    commitTokensFrom(msg.sender, _amount)


@external
def commitTokensFrom(_from: address, _amount: uint256):
    """
    @dev Users must approve contract prior to committing tokens to auction
    """

    assert address(self.paymentCurrency) != ETH_ADDRESS

    tokensToTransfer: uint256 = calculateCommitment(_amount)
    if (tokensToTransfer > 0):
        assert IERC20(self.paymentCurrency).transferFrom(_from, address(this), _amount))
        addCommitment(_from, tokensToTransfer)


@external
@view
def calculateCommitment( _commitment: uint256) -> uint256:
    """
    @notice Returns the amout able to be committed during an auction
    """

    maxCommitment: uint256 = self.tokenSupply * clearingPrice() / TENPOW18
    if (self.amountRaised + _commitment > maxCommitment):
        return maxCommitment - self.amountRaised
    
    return _commitment


# --------------------------------------------------------
#  Finalise Auction
# --------------------------------------------------------


@external
@payable
def finaliseAuction():
    """
    @notice Auction finishes successfully above the reserve
    @dev Transfer contract funds to initialised wallet. 
    """

    assert finalised != True 
        
    # @notice Auction did not meet reserve price.
    if( auctionEnded() and tokenPrice() < self.minimumPrice ):
        _tokenPayment(self.auctionToken, self.wallet, self.tokenSupply)
        self.finalised = true
        return;      
    
    # @notice Successful auction! Transfer tokens bought.
    if (auctionSuccessful()):
        _tokenPayment(self.paymentCurrency, self.wallet, self.amountRaised)
        self.finalised = true


@external
@payable
def withdrawTokens():
    """
    @notice Withdraw your tokens once the Auction has ended.
    """

    fundsCommitted: uint256 = self.commitments[ msg.sender]
    tokensToClaim: uint256 = tokensClaimable(msg.sender)
    self.commitments[ msg.sender] = 0

    # /// @notice Auction did not meet reserve price.
    # /// @dev Return committed funds back to user.
    if( auctionEnded() and tokenPrice() < self.minimumPrice ):
        _tokenPayment(self.paymentCurrency, msg.sender, fundsCommitted)      
        return

    # /// @notice Successful auction! Transfer tokens bought.
    # /// @dev AG: Should hold and distribute tokens vs mint
    # /// @dev AG: Could be only > min to allow early withdraw  
    if (auctionSuccessful() and self.tokensToClaim > 0 ):
        _tokenPayment(self.auctionToken, msg.sender, tokensToClaim)


@internal
def _tokenPayment(IERC20 _token, address payable _to, uint256 _amount):
    """
    @dev Helper function to handle both ETH and ERC20 payments
    """

    if (address(_token) == ETH_ADDRESS):
        _to.transfer(_amount)
    else:
        assert _token.transfer(_to, _amount)

