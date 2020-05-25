pragma solidity ^0.6.2;


// ----------------------------------------------------------------------------
// Petyl Distribution Token
//
// Deployed to : {TBA}
//
// Enjoy.
//
// (c) Adrian Guerrera / Deepyr Pty Ltd for Petyl. The MIT Licence.
// ----------------------------------------------------------------------------
import "./PetylBaseToken.sol";
import "../Misc/SafeMath.sol";



contract PetylDistributeTokens is PetylBaseToken {

    using SafeMath for uint256;


    // Distributions
    bool public acceptEth;
    uint256 constant pointMultiplier = 10e32;
    IERC20 public distributionTokenAddress;
    uint256 public totalDistributionPoints;
    uint256 public totalUnclaimedDistributions;

    mapping(address => uint256) public lastEthPoints;
    mapping(address => uint256) public unclaimedDistributionByAccount;

    // Distribution Events
    event DistributionReceived(uint256 time, address indexed sender, uint256 amount);
    event WithdrawalDistributions(address indexed holder, uint256 amount);
    event SetAcceptEth(bool scceptEth);


    //------------------------------------------------------------------------
    // Constructor
    //------------------------------------------------------------------------
    function initDistributionToken (
        address _tokenOwner,
        string memory _name,
        string memory _symbol,
        address[] memory _defaultOperators,
        address _burnOperator,
        uint256 _initialSupply,
        bool _acceptEth
    )
        public
    {
        initBaseToken(_tokenOwner, _name, _symbol, _defaultOperators,_burnOperator, _initialSupply);
        acceptEth = _acceptEth;
    }


    //------------------------------------------------------------------------
    // Tokens Accepted
    //------------------------------------------------------------------------

    function setAcceptEth (bool _acceptEth)  public  {
        require(isOwner());
        acceptEth = _acceptEth;
        emit SetAcceptEth(_acceptEth);
    }


    //------------------------------------------------------------------------
    // Before Transfer Hook
    //------------------------------------------------------------------------

    function _beforeTokenTransfer(address operator, address from, address to, uint256 tokenId) internal override { 
        _updateAccount(from);
        
        // Set last points for sending to new accounts.
        if (balanceOf(to) == 0 && lastEthPoints[to] == 0 && totalDistributionPoints > 0) {
          lastEthPoints[to] = totalDistributionPoints;
        }
        _updateAccount(to);
    }


    //------------------------------------------------------------------------
    // Distributions Owed
    //------------------------------------------------------------------------

    function distributionsOwing(address _account) external view returns(uint256) {
        return _distributionsOwing(_account);
    }
    function _distributionsOwing(address _account) internal view returns(uint256) {
        uint256 newDistributionPoints = totalDistributionPoints.sub(lastEthPoints[_account]);
        // Returns amount ETH owed from current token balance
        return (balanceOf(_account) * newDistributionPoints) / pointMultiplier;
    }


    //------------------------------------------------------------------------
    // Distributions: Token Transfer Accounting
    //------------------------------------------------------------------------

     function updateAccount(address _account) external {
        _updateAccount(_account);
    }

    function _updateAccount(address _account) internal {
       // Check if new deposits have been made since last withdraw
      if (lastEthPoints[_account] < totalDistributionPoints ){
        uint256 _owing = _distributionsOwing(_account);
        // Increment internal distributions counter to new amount owed
        if (_owing > 0) {
            unclaimedDistributionByAccount[_account] = unclaimedDistributionByAccount[_account].add(_owing);
            lastEthPoints[_account] = totalDistributionPoints;
        }
      }
    }


    //------------------------------------------------------------------------
    // Distributions: Token Deposits
    //------------------------------------------------------------------------

   function depositDistributions() external payable {
        require(msg.value > 0);
        _depositDistributions(msg.value);
    }

    function _depositDistributions(uint256 _amount) internal {
      // Convert deposit into points
        totalDistributionPoints += (_amount * pointMultiplier ) / totalSupply();
        totalUnclaimedDistributions += _amount;
        emit DistributionReceived(now, msg.sender, _amount);
    }

    function getLastEthPoints(address _account) external view returns (uint256) {
        return lastEthPoints[_account];
    }




    //------------------------------------------------------------------------
    // Distributions: Claim accrued 
    //------------------------------------------------------------------------

    function withdrawDistributions () external  {
        _updateAccount(msg.sender);
        _withdrawDistributions(msg.sender);
    }
    function withdrawDistributionsByAccount (address payable _account) external  {
        require(msg.sender == mOwner);
        _updateAccount(_account);
        _withdrawDistributions(_account);
    }

    function _withdrawDistributions(address payable _account) internal  {
        require(_account != address(0));

        if (unclaimedDistributionByAccount[_account]>0) {
          uint256 _unclaimed = unclaimedDistributionByAccount[_account];
          totalUnclaimedDistributions = totalUnclaimedDistributions.sub(_unclaimed);
          unclaimedDistributionByAccount[_account] = 0;
          _account.transfer(_unclaimed);
          emit WithdrawalDistributions(_account, _unclaimed);
        }
    }


    // ------------------------------------------------------------------------
    // Accept ETH deposits as distributions
    // ------------------------------------------------------------------------

    receive () external payable {
        require(acceptEth);
        require(msg.value > 0);
        _depositDistributions(msg.value);
    }


}
