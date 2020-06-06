pragma solidity ^0.6.9;

// ----------------------------------------------------------------------------
// White List interface
// ----------------------------------------------------------------------------

interface WhiteListInterface {
    function isInWhiteList(address account) external view returns (bool);
    function addWhiteList(address[] calldata accounts) external ;
    function removeWhiteList(address[] calldata accounts) external ;
    function initWhiteList(address owner) external ;

}
