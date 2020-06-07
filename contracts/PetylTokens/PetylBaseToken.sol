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
//  Petyl Base Token (PBT)                                       :
//  https://www.petyl.com                                        :
//                                                               :
//  Authors:                                                     :
//  * Adrian Guerrera / Deepyr Pty Ltd                           :
//                                                               :
// (c) Adrian Guerrera.  MIT Licence.                            :
//                                                               :
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// SPDX-License-Identifier: MIT


import "../ERCs/ERC777.sol";
// import "../ERCs/ERC1820Implementer.sol";
import "../Utils/CanSendCodes.sol";
import "../Utils/Controlled.sol";
import "../../interfaces/IBaseToken.sol";
import "../../interfaces/IERC777TokenRules.sol";


contract PetylBaseToken is ERC777, IBaseToken, Controlled, CanSendCodes  {
    event ERC20Enabled();
    event ERC20Disabled();

    bool internal erc20compatible;
    mapping(address => bool) public mintOperator;
    mapping(address => bool) public burnOperator;

    bytes32 public partitionId;   // internal

    // keccak256("ERC20Token")
    bytes32 constant internal _ERC20_TOKENS_INTERFACE_HASH =
        0xaea199e31a596269b42cdafd93407f14436db6e4cad65417994c2eb37381e05a;
    // keccak256("ERC777Token")
    bytes32 constant internal _ERC777_TOKENS_INTERFACE_HASH =
        0xac7fbab5f54a3ca8194167523c6753bfeb96a445279294b6125b68cce2177054;
    // keccak256("ERC777TokenRules")
    bytes32 constant internal _TOKEN_RULES_INTERFACE_HASH =
        0xc4a4c123287cf7b0d8046a21e081e4b2801e57af59a2546c99adf112443f5012;

    IERC1820Registry constant internal ERC1820_BASE = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    event SetTokenRules(address indexed controller, address indexed rules);
    event SetBurnOperator(address indexed controller, address indexed burnOperator, bool status);
    event SetMintOperator(address indexed controller, address indexed mintOperator, bool status);

    /// @notice Initialise token contract
    /// @dev This is a function, not a constructor for automatic contract verification
    function initBaseToken(
        address _tokenOwner,
        string memory _name,
        string memory _symbol,
        address[] memory _defaultOperators,
        address _burnOperator,
        uint256 _initialSupply
    )
       public override
    {
        _initControlled(_tokenOwner);
        burnOperator[_burnOperator];
        partitionId = keccak256(abi.encodePacked(address(this)));
        super._initERC777(_name, _symbol, _defaultOperators);
        _mint(_tokenOwner, _initialSupply, "","");
    }


    //--------------------------------------------------------
    // Getters and Setters
    //--------------------------------------------------------

    /// @notice Each token will have a token ID
    function getPartitionId () public view returns (bytes32) {
        return partitionId;
    }

    function disableERC20Transfers() public  {
        require(isOwner());
        erc20compatible = false;
        ERC1820_BASE.setInterfaceImplementer(address(this), _ERC20_TOKENS_INTERFACE_HASH,  address(0));
        emit ERC20Disabled();
    }

    function enableERC20Transfers() public  {
        require(isOwner());
        erc20compatible = true;
        ERC1820_BASE.setInterfaceImplementer(address(this), _ERC20_TOKENS_INTERFACE_HASH, address(this));
        emit ERC20Enabled();
    }

    /// @notice Add a set of transfer rules to this token
    /// @dev Set rules to address(0) to remove rules
    function setTokenRules(address _rules) public override  {
        require(controllers[msg.sender] || mOwner == msg.sender);
        ERC1820_BASE.setInterfaceImplementer(address(this), _TOKEN_RULES_INTERFACE_HASH, _rules);
        // ERC1820_BASE.setInterfaceImplementer(address(this), _TOKENS_SENDER_INTERFACE_HASH, _rules);
        // ERC1820_BASE.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, _rules);
        emit SetTokenRules(_msgSender(), _rules);
    }

    /// @notice Allow an operator to burn tokens
    function setBurnOperator(address _burnOperator, bool _status) public  override {
        require(controllers[msg.sender] || mOwner == msg.sender);
        burnOperator[_burnOperator] = _status;
        emit SetBurnOperator(_msgSender(), _burnOperator, _status);
    }
    /// @notice Allow an operator to mint tokens
    function setMintOperator(address _mintOperator, bool _status) public  override{
        require(controllers[msg.sender] || mOwner == msg.sender);
        mintOperator[_mintOperator] = _status;
        emit SetMintOperator(_msgSender(), _mintOperator, _status);
    }    



    //--------------------------------------------------------
    // Operator Fuctions
    //--------------------------------------------------------

    /// @notice Allow the owner or controller to mint tokens
    function mint(address to, uint256 amount,  bytes calldata userData, bytes calldata operatorData) external  {
        require(controllers[msg.sender] || mOwner == msg.sender);
        // require(mintable, "Not Mintable");
        _mint(to, amount, userData, operatorData);
    }

    /// @notice Operator functions 
    function operatorMint(address account, uint256 amount, bytes memory data, bytes memory operatorData) public override {
        require(mintOperator[_msgSender()] == true, "ERC777: caller is not a mint operator");
        // require(mintable, "Not Mintable");
        _mint( account, amount, data, operatorData);
    }

    /// @notice Operator functions 
    function operatorBurn(address account, uint256 amount, bytes memory data, bytes memory operatorData) public override {
        require(burnOperator[_msgSender()] || isOperatorFor(_msgSender(), account), "ERC777: caller is not a burn operator");
        _burn(account, amount, data, operatorData);
    }

    /// @notice Operator functions 
    function operatorApprove(address holder, address spender, uint256 value) public override  returns (bool) {
        require(isOperatorFor(_msgSender(), holder), "ERC777: caller is not an operator for holder");
        _approve(holder, spender, value);
        return true;
    }

    /// @notice Operator functions 
    function operatorTransferFrom(
        address spender,
        address holder,
        address recipient,
        uint256 amount,
        bytes memory operatorData
    )
        public
        override
        returns (bool)
    {
        require(isOperatorFor(_msgSender(), holder), "ERC777: caller is not an operator for holder");
        _approve(holder, spender, allowance(holder,spender).sub(amount, "ERC777: transfer amount exceeds allowance"));
        _send(holder, recipient, amount, "", operatorData, false);
        return true;
    }

    // function addDefaultOperators(address _operator) public override  { // AG To Do - Check permissioning
    //     require(isOwner());
    //     _defaultOperatorsArray.push(_operator);
    //     _defaultOperators[_operator] = true;
    // }



    //--------------------------------------------------------
    // Transfer Checks
    //--------------------------------------------------------

    /// @notice Transfer checks for tokens with rules
    /// @dev Not finished - To Do
    /// @dev Should call the token rule contract, check and return results.
    /// @dev If no rules set, should have some basic transfer checks. 
    function canTransfer(
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        view override
        returns (byte, bytes32, bytes32)
    {
        return _canTransfer(_operator, _from, _to, _value, _data, _operatorData);
    }

    function _canTransfer(
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    )
        internal
        view
        returns (byte, bytes32, bytes32)
    {

       address rules = _ERC1820_REGISTRY.getInterfaceImplementer(from, _TOKEN_RULES_INTERFACE_HASH);

        if(rules != address(0)) {
            return IERC777TokenRules(rules).canTransfer(
                partitionId,
                operator,
                from,
                to,
                value,
                data,
                operatorData
            );
        }
        return(TRANSFER_BLOCKED_RECEIVER_NOT_ELIGIBLE, "", partitionId); 
    }

}

