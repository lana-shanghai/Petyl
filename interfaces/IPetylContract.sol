pragma solidity ^0.6.2;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

interface IPetylContract {
    function initPetylSecurityToken(address _owner, address _baseToken) external ;

}
