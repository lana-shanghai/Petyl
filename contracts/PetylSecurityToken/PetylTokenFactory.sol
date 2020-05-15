pragma solidity ^0.6.2;


import "../Misc/Owned.sol";
import "../Misc/SafeMath.sol";
import "../Misc/CloneFactory.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IPetylToken.sol";
import "../../interfaces/IPetylContract.sol";
import "../../interfaces/IOwned.sol";


// ----------------------------------------------------------------------------
// Petyl Token Factory
//
// Authors:
// * Adrian Guerrera / Deepyr Pty Ltd
//
// Appropriated from BokkyPooBah's Fixed Supply Token 👊 Factory
//
// ----------------------------------------------------------------------------

contract PetylTokenFactory is  Owned, CloneFactory {
    using SafeMath for uint;

    address public petylTemplate;
    address public baseTokenTemplate;

    address public newAddress;
    uint256 public minimumFee = 0.1 ether;
    mapping(address => bool) public isChild;
    address[] public children;

    event PetylDeployed(address indexed owner, address indexed addr, address petylToken,address baseToken, uint256 fee);
    event BaseTokenDeployed(address indexed owner, address indexed addr, address baseToken, uint256 fee);
    event FactoryDeprecated(address _newAddress);
    event MinimumFeeUpdated(uint oldFee, uint newFee);
    
    function initPetylTokenFactory(address _petylTemplate, address _baseTokenTemplate, uint256 _minimumFee) public  {
        _initOwned(msg.sender);
        petylTemplate = _petylTemplate;
        baseTokenTemplate = _baseTokenTemplate;
        minimumFee = _minimumFee;
        // add to totalSupplyHistory { block.number, baseToken.totalSupply(); }
    }

    function numberOfChildren() public view returns (uint) {
        return children.length;
    }
    function deprecateFactory(address _newAddress) public  {
        require(isOwner());
        require(newAddress == address(0));
        emit FactoryDeprecated(_newAddress);
        newAddress = _newAddress;
    }
    function setMinimumFee(uint256 _minimumFee) public  {
        require(isOwner());
        emit MinimumFeeUpdated(minimumFee, _minimumFee);
        minimumFee = _minimumFee;
    }

    function deployBaseToken(
        address _tokenOwner,
        string memory _symbol,
        string memory _name,
        address[] memory _defaultOperators,
        address _burnOperator,
        uint256 _initialSupply

    )
        public payable returns (address baseToken)
    {
        baseToken = createClone(baseTokenTemplate);
        isChild[address(baseToken)] = true;
        children.push(address(baseToken));
        IPetylToken(baseToken).initBaseToken(_tokenOwner, _symbol,_name,_defaultOperators,_burnOperator, _initialSupply);
        emit BaseTokenDeployed(msg.sender, address(baseToken), baseTokenTemplate, msg.value);
    }

    function deployPetylContract(        
        address _tokenOwner,
        string memory _symbol,
        string memory _name,
        address[] memory _defaultOperators,
        address _burnOperator,
        uint256 _initialSupply
    ) 
        public payable returns (address petylToken) 
    {
        require(msg.value >= minimumFee);
        petylToken = createClone(petylTemplate);
        address baseToken = deployBaseToken(_tokenOwner, _symbol,_name, _defaultOperators,_burnOperator, _initialSupply);

        IPetylContract(petylToken).initPetylSecurityToken(msg.sender, baseToken);
        isChild[address(petylToken)] = true;
        children.push(address(petylToken));
        emit PetylDeployed(msg.sender, address(petylToken), petylTemplate, baseToken, msg.value);
        if (msg.value > 0) {
            payable(owner()).transfer(msg.value);
        }
    }


    // footer functions
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public returns (bool success) {
        require(isOwner());
        return IERC20(tokenAddress).transfer(owner(), tokens);
    }
    receive () external payable {
        revert();
    }
}