/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.6.9;

/**
 * @title IERC777Sender
 * @dev ERC777TokensSender interface
 */
interface IERC777TokenRules {
    function tokensToTransfer(
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;

    function canTransfer(
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external view returns (byte, bytes32, bytes32);
}
