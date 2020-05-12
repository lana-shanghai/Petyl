pragma solidity ^0.6.2;

import "../Misc/SafeMath.sol";


// MVP prototype. DO NOT USE!

contract PetylDutchAuction {

    using SafeMath for uint256;
    uint256 private constant TENPOW18 = 10 ** 18;

    uint256 public totalCommitments;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public startPrice;
    uint256 public reservePrice;
    uint256 public tokensAvailable;
    address payable public wallet;
    mapping(address => uint256) public commitments;

    constructor () public {
        tokensAvailable =1000000 * TENPOW18;
        startDate = 1589183895;
        endDate = 1589383895;
        startPrice = 100 * TENPOW18;
        reservePrice = 1 * TENPOW18; 
        wallet = 0x0000000000000000000000000000000000000000;
    }

    function initPetylAuction(uint256 _tokensAvailable, uint256 _startDate, uint256 _endDate, uint256 _startPrice, uint256 _reservePrice) external {
        require(_endDate > _startDate);
        require(_startPrice > _reservePrice);

        tokensAvailable =_tokensAvailable;
        startDate = _startDate;
        endDate = _endDate;
        startPrice = _startPrice;
        reservePrice = _reservePrice; 
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
        if (totalCommitments.add(_commitment) >= tokensAvailable.mul(auctionPrice())) {
            return tokensAvailable.mul(auctionPrice()).sub(totalCommitments);
        }
        return _commitment;
    }

    /// @notice Commits to an amount during an auction
    function addCommitment( uint256 _commitment) public returns (uint256 committed){
        require(now >= startDate && now <= endDate);
        committed = calculateCommitment(_commitment);
        commitments[msg.sender] = commitments[msg.sender].add(committed);
        totalCommitments = totalCommitments.add(committed);
    }
    function tokenPrice() public view returns (uint256) {
        return totalCommitments.div(tokensAvailable);
    }

    /// @notice Returns bool if amount committed exceeds tokens available
    function finialised () public view returns (bool){
        return currentDemand() >= tokensAvailable;
    }
    function tokensClaimable(address _user) public view returns (uint256) {
        return commitments[_user].div(tokenPrice());
    }


    /// @notice Buy Tokens by committing ETH to this contract address 
    receive () external payable {

        // Get ETH able to be committed
        uint256 ethToTransfer = calculateCommitment( msg.value);

        // Accept ETH Payments
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            wallet.transfer(ethToTransfer);
        }
        // Return any ETH to be refunded
        if (ethToRefund > 0) {
            msg.sender.transfer(ethToRefund);
        }
        addCommitment(ethToTransfer);
    }


}