pragma solidity ^0.6.9;


import "../Utils/Owned.sol";
import "../Utils/CloneFactory.sol";
import "../../interfaces/IPetylToken.sol";
import "../../interfaces/IPetylContract.sol";
import "../../interfaces/IOwned.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ----------------------------------------------------------------------------
// From BokkyPooBah's Fixed Supply Token 👊 Factory
// https://github.com/bokkypoobah/FixedSupplyTokenFactory
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT

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
        string memory _name,
        string memory _symbol,

        address[] memory _defaultOperators,
        address _burnOperator,
        uint256 _initialSupply

    )
        public payable returns (address baseToken)
    {
        baseToken = createClone(baseTokenTemplate);
        isChild[address(baseToken)] = true;
        children.push(address(baseToken));
        IPetylToken(baseToken).initBaseToken(_tokenOwner, _name, _symbol, _defaultOperators,_burnOperator, _initialSupply);
        emit BaseTokenDeployed(msg.sender, address(baseToken), baseTokenTemplate, msg.value);
    }

    function deployPetylContract(        
        address _tokenOwner,
        string memory _name,
        string memory _symbol,
        address[] memory _defaultOperators,
        address _burnOperator,
        uint256 _initialSupply
    ) 
        public payable returns (address petylToken) 
    {
        require(msg.value >= minimumFee);
        petylToken = createClone(petylTemplate);
        address baseToken = deployBaseToken(_tokenOwner, _name, _symbol, _defaultOperators,_burnOperator, _initialSupply);

        IPetylContract(petylToken).initPetylVenture(msg.sender, baseToken);
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