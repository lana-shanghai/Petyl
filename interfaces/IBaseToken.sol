pragma solidity ^0.6.9;

//-----------------------------------------------------------------------------
/// @title Interface of ERC777 standard
/// @dev ref. https://eips.ethereum.org/EIPS/eip-777
//-----------------------------------------------------------------------------

// import "../interfaces/IERC20.sol";
// import "../interfaces/IERC777.sol";


interface IBaseToken  {

    // Additional permissioning
    //function addController(address _controller) external;
    // function addDefaultOperators(address _operator) external;  // AG To Do - Check permissioning
    function setTokenRules(address _rules) external;
    function setBurnOperator(address _burnOperator, bool _status) external;
    function setMintOperator(address _mintOperator, bool _status) external;

     function canTransfer(
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns (byte, bytes32, bytes32);

    function initBaseToken(
        address _tokenOwner,
        string calldata _name,
        string calldata _symbol,
        address[] calldata _defaultOperators,
        address _burnOperator,
        uint256 _initialSupply
    ) external;


    function operatorApprove(address holder, address spender, uint256 value) external returns (bool);
    function operatorTransferFrom(address spender, address holder, address recipient, uint256 amount, bytes calldata operatorData) external returns (bool);
    function operatorMint(address from, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
    // function operatorBurn(address from, uint256 amount, bytes calldata data, bytes calldata operatorData) external;

    event SetTokenRules(address indexed controller, address indexed rules);
    event SetBurnOperator(address indexed controller, address indexed burnOperator, bool status);
    event SetMintOperator(address indexed controller, address indexed mintOperator, bool status);

}
