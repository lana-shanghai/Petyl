pragma solidity ^0.6.2;

// ----------------------------------------------------------------------------
// IERC1400 Security Token Standard
// https://github.com/SecurityTokenStandard/EIP-Spec
// ----------------------------------------------------------------------------

import "../interfaces/IERC1643.sol";
import "../interfaces/IERC1644.sol";
import "../interfaces/IERC20.sol";

interface IERC1400 is IERC1643, IERC1644 {

    // Token Information
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns (uint256);
    function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory);

    // Transfers
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    // Partition Token Transfers
    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes calldata _data)
        external
        returns (bytes32);

    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external returns (bytes32);

    // Operator Management
    function authorizeOperator(address _operator) external;
    function revokeOperator(address _operator) external;
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external;
    function revokeOperatorByPartition(bytes32 _partition, address _operator) external;

    // Operator Information
    function isOperator(address _operator, address _tokenHolder) external view returns (bool);
    function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder)
        external
        view
        returns (bool);

    // Token Issuance
    function isIssuable() external view returns (bool);
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;
    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data) external;

    // Token Redemption
    function redeem(uint256 _value, bytes calldata _data) external;
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data) external;
    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _operatorData
    ) external;

    // Transfer Validity
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (byte, bytes32);
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data)
        external
        view
        returns (byte, bytes32);

    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    ) external view returns (byte, bytes32, bytes32);


    // Transfer Events
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );
    /*
    Need to see where this is needed from specification
      event ChangedPartition(
          bytes32 indexed _fromPartition,
          bytes32 indexed _toPartition,
          uint256 _value
      );
    */
    // Operator Events
    event AuthorizedOperator(address indexed _operator, address indexed _tokenHolder);
    event RevokedOperator(address indexed _operator, address indexed _tokenHolder);

    event AuthorizedOperatorByPartition(
        bytes32 indexed _partition,
        address indexed _operator,
        address indexed _tokenHolder
    );

    event RevokedOperatorByPartition(
        bytes32 indexed _partition,
        address indexed _operator,
        address indexed _tokenHolder
    );

    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);
    event IssuedByPartition(
        bytes32 indexed _partition,
        address indexed _operator,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event RedeemedByPartition(
        bytes32 indexed _partition,
        address indexed _operator,
        address indexed _from,
        uint256 _value,
        bytes _operatorData
    );


    event AddedPartition(address indexed _tokenAddr, bytes32 indexed _partition);
    event TransferByOperator(bytes32 indexed _partition, address _operator, address _from, address _to, uint256 _value, bytes _userData, bytes _operatorData);


}
