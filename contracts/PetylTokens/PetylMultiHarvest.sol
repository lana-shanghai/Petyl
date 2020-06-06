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
//  Petyl Multi Harvest (PMH)                                    :
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
import "../../interfaces/IERC20.sol";
// import "../Utils/ReentrancyGuard.sol;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";



contract PetylMultiHarvest is PetylBaseToken {

    using SafeMath for uint256;
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant pointMultiplier = 10e32;

    // Harvest
    bool public acceptEth;
    
    // [accounts]
    mapping(address => uint256) public lastHarvest; 

    struct Harvest {
      address token;
      uint256 amount;
      uint256 lastHarvestPoints;
    }
    Harvest[] public harvests;  //internal

    // [token]
    struct Token {
        bool active;
        uint256 index;
    }
    address[] public tokens;  //internal
    mapping(address => Token) public tokenIndex;
    
    mapping(address => uint256) public totalHarvestPoints;
    mapping(address => uint256) public totalUnclaimedHarvest;
    
    /// @dev [account][token]
    mapping(address => mapping(address => uint256)) public unclaimedHarvestByAccount;  


    // Harvest Events
    event HarvestReceived(uint256 time, address indexed sender, address token, uint256 amount);
    event WithdrawalHarvest(address indexed holder, address indexed token, uint256 amount);
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

    function addHarvestToken (address _token) public {
        require(isOwner());
        require(totalHarvestPoints[_token] == 0 );
        tokenIndex[_token] = Token(true,tokens.length);
    }


    //------------------------------------------------------------------------
    // Before Transfer Hook
    //------------------------------------------------------------------------

    function _beforeTokenTransfer(address operator, address from, address to, uint256 tokenId) internal override { 
        _updateAccount(from);
        
        // // Set last points for sending to new accounts.
        // if (balanceOf(to) == 0 && lastEthPoints[to] == 0 && totalHarvestPoints > 0) {
        //   lastEthPoints[to] = totalHarvestPoints;
        // }
        _updateAccount(to);
    }


    //------------------------------------------------------------------------
    // Harvest Owed
    //------------------------------------------------------------------------

    function harvestOwing(address _account, address _token) external view returns(uint256) {
        return _harvestOwing(_account, _token);
    }
    function _harvestOwing(address _account, address _token) internal view returns(uint256) {
        uint256 harvestIndex = _scanForFirstTokenHarvest(_token, lastHarvest[_account]);
        return _harvestOwingByTokenIndex(_account,harvestIndex);
    }

    function _harvestOwingByTokenIndex(address _account, uint256 _harvestIndex) internal view returns(uint256){
        address token = harvests[_harvestIndex].token;
        uint256 lastHarvestPoints = harvests[_harvestIndex].lastHarvestPoints;
        uint256 newHarvestPoints = totalHarvestPoints[token].sub(lastHarvestPoints);

        // Return difference in points for token at harvestIndex
        return (balanceOf(_account) * newHarvestPoints) / pointMultiplier;
    }


    function _scanForFirstTokenHarvest(address _token, uint256 _index) internal view returns (uint256) {  //view internal
        require(_index <= harvests.length);
        while (_index + 1 < harvests.length  && _token != harvests[_index].token) {
            _index++;
        }
        return (_index);
    }

    //------------------------------------------------------------------------
    // Harvest: Token Transfer Accounting
    //------------------------------------------------------------------------

     function updateAccount(address _account) external {
        _updateAccount(_account);
    }

     function _updateAccount(address _account) internal {
        if (lastHarvest[_account] < harvests.length - 1) {
            for (uint256 i = 0; i < tokens.length; i++) {
                  _updateAccountByToken(_account,tokens[i]);
            }
            lastHarvest[_account] = harvests.length - 1;
        }
    }


    function _updateAccountByToken(address _account, address _token) internal {
       // Check if new deposits have been made since last withdraw
        uint256 _owing = _harvestOwing(_account, _token);
        // Increment internal harvest counter to new amount owed
        if (_owing > 0) {
            unclaimedHarvestByAccount[_account][_token] = unclaimedHarvestByAccount[_account][_token].add(_owing);
        }
    }



    //------------------------------------------------------------------------
    // Harvest: Token Deposits
    //------------------------------------------------------------------------

   function depositHarvest() external payable {
        require(acceptEth);
        require(msg.value > 0);
        _depositHarvest(msg.value,ETH_ADDRESS);
    }

    function depositTokenHarvest(uint256 _amount,address _token) external  {
        require(_amount > 0 || _token != ETH_ADDRESS);  // AG: or ETH
        require(tokenIndex[_token].active);
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount));
        _depositHarvest(_amount,_token);
    }

    function _depositHarvest(uint256 _amount, address _token) internal {
        // Convert deposit into points
        totalHarvestPoints[_token] += (_amount * pointMultiplier ) / totalSupply();
        totalUnclaimedHarvest[_token] += _amount;
        harvests.push(Harvest(_token, _amount, totalHarvestPoints[_token]));
        emit HarvestReceived(now, msg.sender, _token ,_amount);
    }



    //------------------------------------------------------------------------
    // Harvest: Claim accrued 
    //------------------------------------------------------------------------

    /// @notice Claim amount of harvest owed to user, for each token 
    function withdrawHarvest () public  {
        uint256 i;
        _updateAccount(msg.sender);
        for (i = 0; i < tokens.length; i++) {
            address tmpToken = tokens[i];
            _withdrawHarvestByToken(tmpToken, msg.sender);
        }
    }

    function _withdrawHarvestByToken(address _token, address payable _account) internal  {
        uint256 _unclaimed = unclaimedHarvestByAccount[_account][_token];
        if (_unclaimed>0) {
            totalUnclaimedHarvest[_token] = totalUnclaimedHarvest[_token].sub(_unclaimed);
            unclaimedHarvestByAccount[_account][_token] = 0;

            _transferHarvestTokens(_token,_account, _unclaimed );
            emit WithdrawalHarvest(_account, _token, _unclaimed);
        }
    }

    function _transferHarvestTokens(address _token, address payable _account, uint256 _amount) internal  {
        /// @dev transfer harvest owed to user
        if (_token == ETH_ADDRESS) {
            _account.transfer(_amount);
        } else {
            require(IERC20(_token).transfer(_account, _amount));
        }
    }



    // ------------------------------------------------------------------------
    // Accept ETH deposits as harvest
    // ------------------------------------------------------------------------

    receive () external payable {
        require(acceptEth);
        require(msg.value > 0);
        _depositHarvest(msg.value,ETH_ADDRESS);
    }


}
