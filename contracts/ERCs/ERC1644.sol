pragma solidity ^0.6.2;

// @title ERC1644 Controller Operation  (part of the ERC1400 Security Token Standards)
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec

// import "../Misc/Controlled.sol";
// import "../../interfaces/IERC1644.sol";

contract ERC1644 { /* is IERC1644, Controlled */ 


    /*
    function controllerTransfer(address _from, address _to, uint256 _value, bytes _data, bytes _operatorData) external;
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes _data, bytes _operatorData) external;

    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    */


    // ------------------------------------------------
    // Controller Functions  ERC1644
    // ------------------------------------------------
    function controllerTransfer(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external override 
        /*onlyController*/
    {
        _transferByPartition(defaultPartition, _from, _to, _value, _data);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }

    function controllerTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        /*onlyController*/
    {
        _transferByPartition(_partition,_from, _to, _value, _data);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }

    function controllerRedeem(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external override
        /*onlyController*/ 
    {
        _operatorRedeemByPartition(defaultPartition, _tokenHolder, _value, _data);
        emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
    }

    function controllerRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        // onlyController
    {
        _operatorRedeemByPartition(_partition, _tokenHolder, _value, _data);
        emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
    }
}
