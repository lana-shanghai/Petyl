pragma solidity ^0.6.2;

import "../Misc/SafeMath.sol";
import "../../interfaces/IPetylToken.sol";
import "../../interfaces/IERC20.sol";


// ----------------------------------------------------------------------------
// Petyl Dutch Auction
//
//
// MVP prototype. DO NOT USE!
//                        
// (c) Adrian Guerrera.  MIT Licence.                            
// May 26 2020                                  
// ----------------------------------------------------------------------------


contract PetylDutchAuction  {

    using SafeMath for uint256;
    uint256 private constant TENPOW18 = 10 ** 18;
    /// @dev The placeholder ETH address.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public amountRaised;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public startPrice;
    uint256 public minimumPrice;
    uint256 public tokenSupply;
    IPetylToken public token; 
    IERC20 public paymentCurrency; 
    address payable public wallet;
    mapping(address => uint256) public commitments;

    event AddedCommitment(address addr, uint256 commitment);

    /// @dev Init function 
    function initDutchAuction(
        address _token, 
        uint256 _tokenSupply, 
        uint256 _startDate, 
        uint256 _endDate,
        address _paymentCurrency, 
        uint256 _startPrice, 
        uint256 _minimumPrice, 
        address payable _wallet
    ) 
        external 
    {
        require(_endDate > _startDate);
        require(_startPrice > _minimumPrice);
        require(_minimumPrice > 0);

        token = IPetylToken(_token);
        paymentCurrency = IERC20(_paymentCurrency);
        tokenSupply =_tokenSupply;
        startDate = _startDate;
        endDate = _endDate;
        startPrice = _startPrice;
        minimumPrice = _minimumPrice; 
        wallet = _wallet;
    }


    // Dutch Auction Price Function
    // ============================
    //  
    // Start Price ----- 
    //                   \ 
    //                    \
    //                     \
    //                      \ ------------ Token Price
    //                     / \            = AmountRaised/TokenSupply
    //                   --   \
    //                  /      \ 
    //                --        ----------- Minimum Price
    // Amount raised /          End Time
    //

    /// @notice The average price of each token from all commitments. 
    function tokenPrice() public view returns (uint256) {
        return amountRaised.mul(TENPOW18).div(tokenSupply);
    }

    /// @notice Token price decreases at this rate during auction.
    function priceGradient() public view returns (uint256) {
        uint256 numerator = startPrice.sub(minimumPrice);
        uint256 denominator = endDate.sub(startDate);
        return numerator.div(denominator);
    }

      /// @notice Returns price during the auction 
    function priceFunction() public view returns (uint256) {
        /// @dev Return Auction Price
        if (now <= startDate) {
            return startPrice;
        }
        if (now >= endDate) {
            return minimumPrice;
        }
        uint256 priceDiff = now.sub(startDate).mul(priceGradient());
        uint256 price = startPrice.sub(priceDiff);
        return price;
    }

    /// @notice The current Dutch auction price
    function auctionPrice() public view returns (uint256) {
        /// @dev If auction successful, return tokenPrice
        if (tokenPrice() > priceFunction()) {
            return tokenPrice();
        }
        return priceFunction();
    }

    /// @notice How many tokens the user is able to claim
    function tokensClaimable(address _user) public view returns (uint256) {
        return commitments[_user].mul(TENPOW18).div(auctionPrice());
    }

    /// @notice Total amount of tokens committed at current auction price
    function totalTokensCommitted() public view returns(uint256) {
        return amountRaised.mul(TENPOW18).div(auctionPrice());
    }

    /// @notice Successful if tokens sold equals tokenSupply
    function auctionSuccessful() public view returns (bool){
        return totalTokensCommitted() >= tokenSupply && tokenPrice() >= minimumPrice;
    }

    /// @notice Returns bool if successful or time has ended
    function auctionEnded() public view returns (bool){
        return auctionSuccessful() || now > endDate;
    }

    //--------------------------------------------------------
    // Commit to buying tokens 
    //--------------------------------------------------------

    /// @notice Buy Tokens by committing ETH to this contract address 
    receive () external payable {
        commitEth(msg.sender);
    }

    /// @notice Commit ETH to buy tokens on sale
    function commitEth (address payable _from) public payable {
        require(now >= startDate && now <= endDate);
        require(address(paymentCurrency) == ETH_ADDRESS);
        // Get ETH able to be committed
        uint256 ethToTransfer = calculateCommitment( msg.value);

        // Accept ETH Payments
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            addCommitment(_from, ethToTransfer);
        }
        // Return any ETH to be refunded
        if (ethToRefund > 0) {
            _from.transfer(ethToRefund);
        }
    }


    /// @notice Commit approved ERC20 tokens to buy tokens on sale
    function commitTokens (uint256 _amount) public {
        commitTokensFrom(msg.sender, _amount);
    }

    /// @dev Users must approve contract prior to committing tokens to auction
    function commitTokensFrom (address _from, uint256 _amount) public {
        require(now >= startDate && now <= endDate);
        require(address(paymentCurrency) != ETH_ADDRESS);
        uint256 tokensToTransfer = calculateCommitment( _amount);
        if (tokensToTransfer > 0) {
            require(IERC20(paymentCurrency).transferFrom(_from, address(this), _amount));
            addCommitment(_from, tokensToTransfer);
        }
    }

    /// @notice Returns the amout able to be committed during an auction
    function calculateCommitment( uint256 _commitment) 
        public view returns (uint256 committed) 
    {
        uint256 maxCommitment = tokenSupply.mul(auctionPrice()).div(TENPOW18);
        if (amountRaised.add(_commitment) > maxCommitment) {
            return maxCommitment.sub(amountRaised);
        }
        return _commitment;
    }

    /// @notice Commits to an amount during an auction
    function addCommitment(address _addr,  uint256 _commitment) internal {
        commitments[_addr] = commitments[_addr].add(_commitment);
        amountRaised = amountRaised.add(_commitment);
        emit AddedCommitment(_addr, _commitment);
    }



    //--------------------------------------------------------
    // Withdraw tokens 
    //--------------------------------------------------------

    /// @notice Auction finishes successfully above the reserve
    /// @dev Transfer contract funds to initialised wallet. 
    function finaliseAuction () public  {
        require(auctionSuccessful());
        _tokenPayment(wallet, amountRaised);       
    }

    /// @notice Withdraw your tokens once the Auction has ended.
    function withdrawTokens() public {
        uint256 fundsCommitted = commitments[ msg.sender];
        uint256 tokensToClaim = tokensClaimable(msg.sender);
        commitments[ msg.sender] = 0;

        /// @notice Auction did not meet reserve price.
        /// @dev Return committed funds back to user.
        if( auctionEnded() && tokenPrice() < minimumPrice ) {
            _tokenPayment(msg.sender, fundsCommitted);       
            return;      
        }
        /// @notice Successful auction! Transfer tokens bought.
        /// @dev AG: Should hold and distribute tokens vs mint
        /// @dev AG: Could be only > min to allow early withdraw  
        if (auctionSuccessful() && tokensToClaim > 0 ) {
            token.operatorMint( msg.sender,tokensToClaim,"","");
        }
    }

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _tokenPayment(address payable _to, uint256 _amount) internal {
        if (address(paymentCurrency) == ETH_ADDRESS) {
            _to.transfer(_amount); 
        } else {
            require(paymentCurrency.transfer(_to, _amount));
        }
    }

}