pragma solidity ^0.6.2;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

interface IPetylConv {
    function canConvert(
        address _account,
        address _oldToken, 
        address _newToken,       
        uint _amount
    ) external view returns (bool success);

    function convertToken(
        address _account,
        address _oldToken, 
        address _newToken,    
        uint _amount,
        bytes calldata _holderData,
        bytes calldata _operatorData
    ) external returns (bool success);
}
