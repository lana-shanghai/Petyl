pragma solidity ^0.6.9;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

interface IPetylToken {

    function initBaseToken( 
        address _tokenOwner,
        string calldata _name,
        string calldata _symbol,
        address[] calldata _defaultOperators,
        address _burnOperator,
        uint256 _initialSupply
    ) external;
    function burn(uint256 amount, bytes calldata data) external;
    function mint(address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external;

    function operatorBurn(address from, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
    function operatorMint(address from, uint256 amount, bytes calldata data, bytes calldata operatorData) external;


}
