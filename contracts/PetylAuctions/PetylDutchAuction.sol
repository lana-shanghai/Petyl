pragma solidity ^0.6.2;

import "../Misc/SafeMath.sol";
import "../../interfaces/IPetylToken.sol";

// MVP prototype. DO NOT USE!

contract PetylDutchAuction  {

    using SafeMath for uint256;
    uint256 private constant TENPOW18 = 10 ** 18;

    uint256 public totalCommitments;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public startPrice;
    uint256 public reservePrice;
    uint256 public tokensAvailable;
    IPetylToken public token; 
    address payable public wallet;
    mapping(address => uint256) public commitments;

    event AddedCommitment(address addr, uint256 commitment);

    /// @dev Init function 
    function initPetylAuction(address _token, uint256 _tokensAvailable, uint256 _startDate, uint256 _endDate, uint256 _startPrice, uint256 _reservePrice, address payable _wallet) external {
        require(_endDate > _startDate);
        require(_startPrice > _reservePrice);
        token = IPetylToken(_token);
        tokensAvailable =_tokensAvailable;
        startDate = _startDate;
        endDate = _endDate;
        startPrice = _startPrice;
        reservePrice = _reservePrice; 
        wallet = _wallet;
    }

    /// @notice Token price decreases at this rate during auction.
    function invGradient() public view returns (uint256) {
        uint256 numerator = startPrice.sub(reservePrice);
        uint256 denominator = endDate.sub(startDate);
        return numerator.div(denominator);
    }

    /// @notice Returns price during the auction 
    function auctionPrice() public view returns (uint256) {
        if (now <= startDate) {
            return startPrice;
        }
        if (now >= endDate) {
            return reservePrice;
        }
        uint256 priceDiff = now.sub(startDate).mul(invGradient());
        return startPrice.sub(priceDiff);
    }

    /// @notice Current amount of tokens committed for a given auction price
    function currentDemand() public view returns(uint256) {
        return totalCommitments.mul(TENPOW18).div(auctionPrice());
    }

    /// @notice Returns the amout able to be committed during an auction
    function calculateCommitment( uint256 _commitment) public view returns (uint256 committed) {
        uint256 maxCommitment = tokensAvailable.mul(auctionPrice()).div(TENPOW18);
        if (totalCommitments.add(_commitment) >= maxCommitment) {
            return maxCommitment.sub(totalCommitments);
        }
        return _commitment;
    }

    /// @notice Commits to an amount during an auction
    function addCommitment(address addr,  uint256 _commitment) internal returns (uint256 committed){
        require(now >= startDate && now <= endDate);
        committed = calculateCommitment(_commitment);
        commitments[addr] = commitments[addr].add(committed);
        totalCommitments = totalCommitments.add(committed);
        emit AddedCommitment(addr, committed);
    }
    function tokenPrice() public view returns (uint256) {
        return totalCommitments.mul(TENPOW18).div(tokensAvailable);
    }

    /// @notice Returns bool if amount committed exceeds tokens available
    function auctionEnded() public view returns (bool){
        return currentDemand() >= tokensAvailable;
    }
    function tokensClaimable(address _user) public view returns (uint256) {
        if(commitments[_user] == 0) {
            return 0;
        }
        return commitments[_user].mul(TENPOW18).div(tokenPrice());
    }

    function claim() public  {
        require(auctionEnded(), "Auction has not yet ended");
        uint256 fundsCommitted = commitments[ msg.sender];
        uint256 tokensToClaim = tokensClaimable(msg.sender);
        commitments[ msg.sender] = 0;

        /// @notice Auction below reserve price, return commited funds
        if( tokenPrice() < reservePrice ) {
            msg.sender.transfer(fundsCommitted);
            return ;        
        }
        /// @notice If auction successful, mint tokens owed
        if (tokensToClaim > 0 ) {
            token.operatorMint( msg.sender,tokensToClaim, "","");
        }
    }

    /// @notice Auction finishes successfully, above the reserve, then transfer funds to wallet. 
    /// @dev This doesnt nessasarily have to have an auctionEnded requirement. 
    function finaliseAuction () public {
        require(auctionEnded());
        if( tokenPrice() >= reservePrice ) {
            wallet.transfer(totalCommitments);        
        }
    }
 
    /// @notice Buy Tokens by committing ETH to this contract address 
    receive () external payable {
        // Get ETH able to be committed
        uint256 ethToTransfer = calculateCommitment( msg.value);

        // Accept ETH Payments
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            addCommitment(msg.sender, ethToTransfer);
        }
        // Return any ETH to be refunded
        if (ethToRefund > 0) {
            msg.sender.transfer(ethToRefund);
        }
    }


}