pragma solidity ^0.6.9;


//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//:::::::::: @#:::::::::::::::::::::::::::::::::::::::::::::::::::
//:::::::::: ##:::::::::::::::::::::::::::::::::::::::::::::::::::
//:::::::::: ##:::::::::::::::::::::::::::::::::::::::::::::::::::
//::::: #######::: #####::: ######:: #######: ###::: ### ##.###:::
//::: ###.. ###: ###.. ##: ###.. ##: ###.. ## ###:: ###: ####.::::
//::: ##:::: ##: ######### ########: ##.::: ## ###: ###: ###.:::::
//::: ##:::: ##: ##.....:: ##.....:: ##:::: ##: ######:: ###::::::
//::::: #######::: #####::: ######:: #######:::: ####::: ###::::::
//::::::......::::::...::::::...:::: ##....:::::: ##::::::::::::::
//:::::::::::::::::::::::::::::::::: ##::::::::: ##:::::::::::::::
//:::::::::::::::::::::::::::::::::: ##:::::::: ##::::::::::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//::::::::::::::01101100:01101111:01101111:01101011:::::::::::::::
//:::::01100100:01100101:01100101:01110000:01111001:01110010::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//                                                               :
//  Petyl Harvest Token (PHT)                                    :
//  https://www.petyl.com                                        :
//                                                               :
//  Authors:                                                     :
//  * Adrian Guerrera / Deepyr Pty Ltd                           :
//                                                               :
// (c) Adrian Guerrera.  MIT Licence.                            :
//                                                               :
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// SPDX-License-Identifier: MIT



import "./PetylBaseToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PetylHarvestToken is PetylBaseToken, ReentrancyGuard  {

    using SafeMath for uint256;


    // Harvest
    bool public acceptEth;
    uint256 constant pointMultiplier = 10e32;
    IERC20 public harvestTokenAddress;
    uint256 public totalHarvestPoints;  
    uint256 public totalUnclaimedHarvest;

    mapping(address => uint256) public lastEthPoints;  
    mapping(address => uint256) public unclaimedHarvestByAccount;

    // Harvest Events
    event HarvestReceived(uint256 time, address indexed sender, uint256 amount);
    event WithdrawalHarvest(address indexed holder, uint256 amount);
    event SetAcceptEth(bool scceptEth);


    //------------------------------------------------------------------------
    // Constructor
    //------------------------------------------------------------------------
    function initHarvestToken (
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
        if (balanceOf(to) == 0 && lastEthPoints[to] == 0 && totalHarvestPoints > 0) {
          lastEthPoints[to] = totalHarvestPoints;
        }
        _updateAccount(to);
    }


    //------------------------------------------------------------------------
    // Harvest Owed
    //------------------------------------------------------------------------

    function harvestOwing(address _account) external view returns(uint256) {
        return _harvestOwing(_account);
    }
    function _harvestOwing(address _account) internal view returns(uint256) {
        uint256 newHarvestPoints = totalHarvestPoints.sub(lastEthPoints[_account]);
        // Returns amount ETH owed from current token balance
        return (balanceOf(_account) * newHarvestPoints) / pointMultiplier;
    }


    //------------------------------------------------------------------------
    // Harvest: Token Transfer Accounting
    //------------------------------------------------------------------------

     function updateAccount(address _account) external {
        _updateAccount(_account);
    }

    function _updateAccount(address _account) internal {
       // Check if new deposits have been made since last withdraw
      if (lastEthPoints[_account] < totalHarvestPoints ){
        uint256 _owing = _harvestOwing(_account);
        // Increment internal harvest counter to new amount owed
        if (_owing > 0) {
            unclaimedHarvestByAccount[_account] = unclaimedHarvestByAccount[_account].add(_owing);
            lastEthPoints[_account] = totalHarvestPoints;
        }
      }
    }


    //------------------------------------------------------------------------
    // Harvest: Token Deposits
    //------------------------------------------------------------------------

   function depositHarvest() external payable {
        require(msg.value > 0);
        _depositHarvest(msg.value);
    }

    function _depositHarvest(uint256 _amount) internal {
      // Convert deposit into points
        totalHarvestPoints += (_amount * pointMultiplier ) / totalSupply();
        totalUnclaimedHarvest += _amount;
        emit HarvestReceived(now, msg.sender, _amount);
    }

    function getLastEthPoints(address _account) external view returns (uint256) {
        return lastEthPoints[_account];
    }




    //------------------------------------------------------------------------
    // Harvest: Claim accrued 
    //------------------------------------------------------------------------

    function withdrawHarvest () external  {
        _updateAccount(msg.sender);
        _withdrawHarvest(msg.sender);
    }
    function withdrawHarvestByAccount (address payable _account) external  {
        require(msg.sender == mOwner);
        _updateAccount(_account);
        _withdrawHarvest(_account);
    }

    function _withdrawHarvest(address payable _account) internal  {
        require(_account != address(0));

        if (unclaimedHarvestByAccount[_account]>0) {
          uint256 _unclaimed = unclaimedHarvestByAccount[_account];
          totalUnclaimedHarvest = totalUnclaimedHarvest.sub(_unclaimed);
          unclaimedHarvestByAccount[_account] = 0;
          _account.transfer(_unclaimed);
          emit WithdrawalHarvest(_account, _unclaimed);
        }
    }


    // ------------------------------------------------------------------------
    // Accept ETH deposits as harvest
    // ------------------------------------------------------------------------

    receive () external payable {
        require(acceptEth);
        require(msg.value > 0);
        _depositHarvest(msg.value);
    }


}
