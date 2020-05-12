pragma solidity ^0.6.2;

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//:::::::::: @#:::::::::::::::::::::::::::::::::::::::::::::::::::
//:::::::::: ##:::::::::::::::::::::::::::::::::::::::::::::::::::
//:::::::::: ##:::::::::::::::::::::::::::::::::::::::::::::::::::
//::::: #######::: #####::: ######:: #######: ###::: ### ##.###:::
//::: ###.. ###: ###.. ##: ###.. ##: ###.. ## ###:: ###: ####.::::
//::: ##:::: ##: ######### ########: ##.::: ## ###: ###: ###.:::::
//::: ##:::: ##: ##.....:: ##.....:: ##:::: ##: ######:: ###::::::
//::::: #######::: #####::: ######:: #######:::: ####::: ###::::::
//::::::......::::::...::::::...:::: ##....:::::: ##::::::::::::::
//:::::::::::::::::::::::::::::::::: ##::::::::: ##:::::::::::::::
//:::::::::::::::::::::::::::::::::: ##:::::::: ##::::::::::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//::::::::::::::01101100:01101111:01101111:01101011:::::::::::::::
//:::::01100100:01100101:01100101:01110000:01111001:01110010::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//                                                               :
//  Petyl Security Token (PST)                                   :
//  https://www.petyl.com                                        :
//                                                               :
//  Authors:                                                     :
//  * Adrian Guerrera / Deepyr Pty Ltd                           :
//                                                               :
//  Oct 20 2018                                                  :
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


import "../Misc/Owned.sol";
import "../ERCs/ERC1400.sol";
import "../../interfaces/IPetylConv.sol";
import "../../interfaces/IERC777.sol";
import "../../interfaces/IPetylContract.sol";
import "../Misc/SafeMath.sol";
import "../Misc/CloneFactory.sol";


// Petyl Security Token
contract PetylSecurityToken is IPetylContract, ERC1400, CloneFactory {

    using SafeMath for uint;

    uint private constant TENPOW18 = 10 ** 18;
    // ERC777Token public baseToken;

    // address[] an array of conversions, or Conversion[]
    mapping(bytes32 => mapping(bytes32 => address)) partitionConversions;

    event PartitionConverted(
        bytes32 indexed fromPartition,
        bytes32 indexed toPartition,
        address indexed account,
        uint amount
    );
    event AddedNewPartition (address indexed partitionAddress, bytes32 indexed partitionId);

    address public baseTokenTemplate;

    // AG: To be finalised
    function initPetylSecurityToken(address _owner, address _baseToken) public override  {
        _initERC1400(_owner, _baseToken);
        baseTokenTemplate = _baseToken;
        // add to totalSupplyHistory { block.number, baseToken.totalSupply(); }
    }
    
    function setBaseTokenTemplate(address _baseToken) public onlyOwner {
        baseTokenTemplate = _baseToken;

    }

    function canConvert(bytes32 _from, bytes32 _to, uint _amount) public view returns (bool success) {
        address convertAddress = partitionConversions[_from][_to];
        address oldToken = partitionAddress[_from];
        address newToken = partitionAddress[_to];
        require(IPetylConv(convertAddress).canConvert(msg.sender,oldToken, newToken,  _amount));
        success = true;
    }

    function addNewConversion(bytes32 _from, bytes32 _to, address _convertAddress)
        public
        onlyOwner
        returns (bool success)
    {
        require(_convertAddress != address(0));
        require(partitionAddress[_from] != address(0));
        require(partitionAddress[_to] != address(0));

        // require(IPetylConv(_convertAddress));  // some sort of test that the conversion interface works for the input
        partitionConversions[_from][_to] = _convertAddress;
        success = true;
    }

    function getConversionAddress(bytes32 _from, bytes32 _to) public view returns (address) {
        return partitionConversions[_from][_to];
    }

    function deleteConversion(bytes32 _from, bytes32 _to) public onlyOwner returns (bool success) {
        partitionConversions[_from][_to] = address(0);
        success = true;
    }

    // conversion should be from an internal function which calls a mint and burn on the 777 tokens and a custom event
    // conversion could also act like a proxy that opperates on the data
    function convertPartition(
        bytes32 _from,
        bytes32 _to,
        uint _amount,
        bytes calldata _userData
    )
        external
    {
        require(partitionConversions[_from][_to] != address(0));
        require(partitionAddress[_from] != address(0));
        require(partitionAddress[_to] != address(0));
        require(_amount > 0);

        require(canConvert(_from, _to, _amount));

        // check total supply before for both tokens
        // load conversion contract and convert tokens
        IPetylConv(partitionConversions[_from][_to]).convertToken(
            msg.sender,
            partitionAddress[_from],
            partitionAddress[_to],
            _amount,
            _userData,
            ""
        );

        // check total supply for both tokens
        // _operatorRedeemByPartition(_partition, _tokenHolder,_value,_data);
        // _issueByPartition(_partition, _tokenHolder, _value, _data);

        emit PartitionConverted(_from, _to, msg.sender, _amount);
    }

    
    function addNewPartition(
        string memory _name,
        string memory _symbol,
        address[] memory _defaultOperators,
        address _burnOperator,
        uint256 _initialSupply
    )
        public
        returns (IBaseToken baseToken, bytes32 partitionId,  bool success)
    {
        baseToken = IBaseToken(payable(createClone(baseTokenTemplate)));
        // _token = new ERC777Token("TEST", "Test Token", 18, 1, 2000000);
        (partitionId, success) = addPartition(address(baseToken));
        baseToken.initBaseToken(msg.sender, _name, _symbol, _defaultOperators, _burnOperator, _initialSupply);

        //uint curTotalSupply = totalSupply();
        //updateValueAtNow(totalSupplyHistory, curTotalSupply + initialSupply);
        //updateValueAtNow(partitionBalances[partition], initialSupply);
        //success = true;
        emit AddedNewPartition(address(baseToken), partitionId);
    }
    

    // footer functions
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(mOwner, tokens);
    }

    receive() external payable {
        revert();
    }
}
