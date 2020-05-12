pragma solidity ^0.6.2;

// ----------------------------------------------------------------------------
// Deepyr's Dynamic Security Token (DST)
//
// Authors:
// * Adrian Guerrera / Deepyr Pty Ltd
//
// Oct 20 2018
// ----------------------------------------------------------------------------

// Import Contracts
import "../Misc/SafeMath.sol";
import "../Misc/Controlled.sol";
import "../Misc/CanSendCodes.sol";
import "../Misc/CertificateControllerMock.sol";
import "./ERC1643.sol";
import "./ERC1820Implementer.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IBaseToken.sol";
import "../../interfaces/IERC777.sol";
import "../../interfaces/IERC1400.sol";
import "../../interfaces/IERC1644.sol";

// ----------------------------------------------------------------------------
// ERC1400 Token Contract
// ----------------------------------------------------------------------------

contract ERC1400 is IERC20, IERC1400, ERC1643,  Controlled, CertificateControllerMock, CanSendCodes {
    using SafeMath for uint;

    // Set Variables
    bytes32 public defaultPartition;
    bytes32[] public partitions;
    IERC777 public baseToken;
    bool internal issuance = true;

    // mapping(address => bytes32) defaultHolderPartition;
    mapping(bytes32 => address) public partitionAddress;
    mapping(address => bytes32[]) holderPartitions;


    function _initERC1400(address _owner, address _baseToken) internal {
        require(_baseToken != address(0));
        _initCertificateController(_owner);
        _initControlled(_owner);
        baseToken = IERC777(_baseToken);
        bytes32 partition = keccak256(abi.encodePacked(baseToken));
        partitions.push(partition);
        partitionAddress[partition] = _baseToken;
        defaultPartition = partition;
        // AG needs to be this contract, cannot be done due to forwarding contract not being the owner of the 777 token
        // needs to be moved to factory contract.
        // baseToken.addDefaultOperators(msg.sender);
    }

    // // ------------------------------------------------
    // // Set default erc20 functions
    // // ------------------------------------------------
    function symbol() public view override returns (string memory) {
        return baseToken.symbol();
    }

    function name() public view override  returns (string memory) {
        return baseToken.name();
    }

    function decimals() public view override returns (uint8) {
        return IERC20(address(baseToken)).decimals();
    }

    function totalSupply() public view override  returns (uint256) {
        return baseToken.totalSupply();
    }

    function balanceOf(address _owner) public view override  returns (uint256) {
        return baseToken.balanceOf(_owner);
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        _transferByPartition(defaultPartition, msg.sender, _to, _value, "");
        return true;
    }
    // AG: Check operator vs controller for this function 
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        return IBaseToken(address(baseToken)).operatorTransferFrom(msg.sender, _from, _to, _value, "");
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        return IBaseToken(address(baseToken)).operatorApprove(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return IERC20(address(baseToken)).allowance(_owner, _spender);
    }


    // ------------------------------------------------
    // ERC1400 Partition Operations
    // ------------------------------------------------
    function getPartitions() external view returns (bytes32[] memory) {
        return partitions;
    }

    function getDefaultPartition() external view returns (bytes32) {
        return defaultPartition;
    }

    // AG: Permissioning
    function setDefaultPartition(bytes32 _partition) public  {
        // AG: Check if partition exisits
        defaultPartition = _partition;
    }
    // AG To Do - Not implemented correctly - need to iterate through partitions ideally
    function partitionsOf(address _tokenHolder) external view override returns (bytes32[] memory) {
        return holderPartitions[_tokenHolder];
    }

    // AG: To test
    function resetUserPartitions(address _tokenHolder) public returns (bytes32[] memory) {
        delete holderPartitions[_tokenHolder];
        for (uint i = 0; i < partitions.length; i++) {
            if (_balanceOfByPartition(partitions[i], _tokenHolder) > 0) {
                holderPartitions[_tokenHolder].push(partitions[i]);
            }
        //    else if (_balanceOfByPartition(partitions[i],_tokenHolder)>0) {
        //        uint partition = holderPartitions[_tokenHolder].length - 1;
        //        holderPartitions[_tokenHolder][partitions[i]] = holderPartitions[_tokenHolder][partition];
        //        holderPartitions[_tokenHolder].length--;
        //    }
        }
        return holderPartitions[_tokenHolder];
    }

    // Partition Operations  // AG: Permissioning?
    function addPartition(address _token) public returns (bytes32 partition, bool success) {
        partition = keccak256(abi.encodePacked(_token));
        partitions.push(partition);
        partitionAddress[partition] = _token;
        success = true;
        emit AddedPartition(_token,partition);
    }

    function getPartition(address _tokenAddress) public view returns (bytes32) {
        for (uint i = 0; i < partitions.length; i++) {
            if (partitionAddress[partitions[i]] == _tokenAddress) {
                return partitions[i];
            }
        }
    }

    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external override view returns (uint) {
        return _balanceOfByPartition(_partition, _tokenHolder);
    }

    function _balanceOfByPartition(bytes32 _partition, address _tokenHolder) private view returns (uint) {
        return IERC777(partitionAddress[_partition]).balanceOf(_tokenHolder);
    }


    // ------------------------------------------------
    // Transfers
    // ------------------------------------------------
    // AG: To Check Data
    function transferWithData(
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external override
        // isValidCertificate(_data)
    {
        _transferByPartition(defaultPartition,msg.sender, _to, _value, _data);
    }
    // AG: To Check Data
    function transferFromWithData(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _operatorData
    )
        external override
        // isValidCertificate(_operatorData)
    {
        require(IBaseToken(address(baseToken)).operatorTransferFrom(msg.sender, _from, _to, _value, _operatorData));
    }

    function transferByPartition(
        bytes32 _partition,
        address _to,
        uint _value,
        bytes calldata _data
    )
        external override
        // isValidCertificate(_data)
        returns (bytes32)
    {
        return _transferByPartition(_partition, msg.sender, _to, _value, _data);
    }

    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external override
        // isValidCertificate(_operatorData)
        returns (bytes32)
    {
        return _operatorTransferByPartition(_partition, _from, _to, _value, _data, _operatorData);
    }

    //----------- Internal Functions --------------------

    function _transferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint _value,
        bytes memory _data
    )
        internal
        returns (bytes32)
    {
        IERC777(partitionAddress[_partition]).operatorSend(_from, _to, _value, _data, "");
        return _partition;
    }

    function _operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint _value,
        bytes memory _data,
        bytes memory _operatorData
    )
        internal
        returns (bytes32)
    {
        require(
            _isOperatorForPartition(_partition, msg.sender, _from),
            "A7 Transfer Blocked, msg.sender is not an operator"
        );

        IERC777(partitionAddress[_partition]).operatorSend(_from, _to, _value, _data, _operatorData);
        emit TransferByOperator(_partition, msg.sender, _from, _to, _value, _data, _operatorData);
        return _partition;
    }


    // ------------------------------------------------
    // Operator Management
    // ------------------------------------------------
 
     function isControllable() public view override (IERC1644,Controlled) returns (bool) {
        return Controlled.isControllable();
    }

    // AG: To Check // Combined into shared operator state
    function authorizeOperator(address _operator) external override {
        _authorizeOperatorByPartition(defaultPartition, _operator);
    }
    // AG: To Check
    function revokeOperator(address _operator) external override {
        require(_operator != msg.sender);
        _revokeOperatorByPartition(defaultPartition, _operator);
    }

    function defaultOperatorsByPartition(bytes32 _partition) external view  returns (address[] memory) {
        return IERC777(partitionAddress[_partition]).defaultOperators();
    }

    // AG: Permissioning ? 
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external override {
        require(isOwner());
        _authorizeOperatorByPartition(_partition, _operator);
    }

    function revokeOperatorByPartition(bytes32 _partition, address _operator) external override {
        require(_operator != msg.sender);
        _revokeOperatorByPartition(_partition, _operator);
    }

    function isOperator(address _operator, address _tokenHolder) external view override returns (bool) {
        return _isOperatorForPartition(defaultPartition, _operator, _tokenHolder);
    }

    function isOperatorForPartition(
        bytes32 _partition,
        address _operator,
        address _tokenHolder
    )
        external
        view override 
        returns (bool)
    {
        return _isOperatorForPartition(_partition, _operator, _tokenHolder);
    }

    //--------- Internal Functions --------------------
    function _authorizeOperatorByPartition(bytes32 _partition, address _operator) internal {
        require(_operator != msg.sender);
        IERC777(partitionAddress[_partition]).authorizeOperator(_operator);
        emit AuthorizedOperatorByPartition(_partition, _operator, msg.sender);
    }

    function _revokeOperatorByPartition(bytes32 _partition, address _operator) internal {
        require(_operator != msg.sender);
        IERC777(partitionAddress[_partition]).revokeOperator(_operator);
        if (defaultPartition == _partition) {
            emit RevokedOperator(_operator, msg.sender);
        } else {
            emit RevokedOperatorByPartition(_partition, _operator, msg.sender);
        }
    }

    function _isOperatorForPartition(
        bytes32 _partition,
        address _operator,
        address _tokenHolder
    )
        internal
        view
        returns (bool)
    {
        return IERC777(partitionAddress[_partition]).isOperatorFor(_operator, _tokenHolder);
    }

    // ------------------------------------------------
    // Token Issuance
    // ------------------------------------------------
    function isIssuable() external view  override returns (bool) {
        return issuance;
    }
    // AG: To Check Data
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data)
        external override  
        // isValidCertificate(_data)
    {
        require(isOwner());
        require(issuance, "Issuance is closed");
        IERC777(partitionAddress[defaultPartition]).mint(_tokenHolder, _value, _data, "");
        emit Issued(msg.sender, _tokenHolder, _value, _data);
    }
    // AG: To Check Data
    function issueByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    )
        external  override 
        // isValidCertificate(_data)
    {
        require(isOwner());
        return _issueByPartition(_partition, _tokenHolder, _value, _data);
    }

    // -------- Internals--------------

    // AG: To Check Data
    function _issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes memory _data) internal {
        require(issuance, "Issuance is closed");
        IERC777(partitionAddress[_partition]).mint(_tokenHolder, _value, _data, "");
        emit IssuedByPartition(_partition, msg.sender, _tokenHolder, _value, _data, "");
    }


    // ------------------------------------------------
    // Token Redemption
    // ------------------------------------------------
    // AG: To Check
    function redeem(uint256 _value, bytes calldata _data) external /*isValidCertificate(_data)*/ override {
        return _redeemByPartition(defaultPartition, _value, _data);
    }
    // AG: To Check
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data)
        external override 
        // isValidCertificate(_data)
    {
        _operatorRedeemByPartition(defaultPartition, _tokenHolder, _value, _data);
    }

    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data)
        external override 
        // isValidCertificate(_data)
    {
        return _redeemByPartition(_partition, _value, _data);
    }

    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    )
        external override 
        // isValidCertificate(_data)
    {
        return _operatorRedeemByPartition(_partition, _tokenHolder, _value, _data);
    }

    // -------- Internals--------------
    function _redeemByPartition(bytes32 _partition, uint256 _value, bytes memory _data) internal {
        IERC777(partitionAddress[_partition]).burn(_value, _data);
        emit Redeemed(msg.sender, msg.sender, _value, _data);
        // AG To check correct senders
    }

    function _operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes memory _operatorData
    )
        internal
    {
        require(_isOperatorForPartition(_partition, msg.sender,_tokenHolder));
        IERC777(partitionAddress[_partition]).operatorBurn(_tokenHolder, _value, "", _operatorData);
        emit RedeemedByPartition(_partition, msg.sender, _tokenHolder, _value, _operatorData);
    }

    // AG To Do - See how much can be transfered
    // function checkTransferLimit() external view returns (uint256 _value) {}

    // ------------------------------------------------
    // Transfer Validity
    // ------------------------------------------------
    // AG: To Check Data
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view override returns (byte, bytes32) {
        (byte _transferCode, bytes32 _bytes1, bytes32 _bytes2) = _canTransfer(
            defaultPartition,
            msg.sender,
            msg.sender,
            _to,
            _value,
            _data,
            ""
        );

        _bytes1 = _bytes2;
        // AG: Tmp. To stop warning, to be removed
        return (_transferCode, _bytes1);
    }

    // AG: To Check
    function canTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        view  override 
        returns (byte, bytes32)
    {
        (byte _transferCode, bytes32 _bytes1, bytes32 _bytes2) = _canTransfer(
            defaultPartition,
            msg.sender,
            _from,
            _to,
            _value,
            _data,
            ""
        );
        _bytes1 = _bytes2;
        // AG: Tmp. To stop warning, to be removed
        return (_transferCode, _bytes1);
    }

    // AG: To Check
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view override 
        returns (byte, bytes32, bytes32)
    {
        return _canTransfer(_partition, msg.sender, _from, _to, _value, _data, "");
    }

    //--------- Internal Functions --------------------
    function _canTransfer(
        bytes32 _partition,
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    )
        internal
        view
        returns (byte, bytes32, bytes32)
    {
        require(_value != 0 || _from != address(0) || _to != address(0));
        // replace with amount check logic
        return IBaseToken(partitionAddress[_partition]).canTransfer(
            _operator,
            _from,
            _to,
            _value,
            _data,
            _operatorData
        );
    }

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



    // ------------------------------------------------
    // Token Controllers
    // ------------------------------------------------
    function setPartitionControllers(bytes32 _partition, address[] calldata _controllers) external view  {
        require(isOwner());

    }

}
