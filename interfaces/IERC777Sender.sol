/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.6.9;

/**
 * @title ERC777TokensSender
 * @dev ERC777TokensSender interface
 */
interface IERC777Sender {
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;

    function canSend(
        bytes32 partition,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external view returns (bool);
}
