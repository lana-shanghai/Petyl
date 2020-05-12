pragma solidity ^0.6.2;

// ----------------------------------------------------------------------------
// Deepyr's Dynamic Security Token
//
// Authors:
// * Adrian Guerrera / Deepyr Pty Ltd
//
// Oct 20 2018
// ----------------------------------------------------------------------------

import "../../interfaces/IPetylConv.sol";
import "../../interfaces/IBaseToken.sol";
import "../../interfaces/IERC777.sol";
import "../Misc/SafeMath.sol";


contract PetylTokenConverter is IPetylConv {

    using SafeMath for uint256;

    constructor() public {
    }

    function canConvert(address _account, address _oldToken, address _newToken, uint _amount)
        external
        view
        override
        returns (bool success)
    {
        return _canConvert(_account, _oldToken, _newToken, _amount);
    }

    function _canConvert(address _account, address _oldToken, address _newToken, uint _amount)
        internal
        pure
        returns (bool success)
    {
        require(_amount != 0);
        // replace with amount check logic
        require(_account != address(0)); 
        require(_oldToken != address(0));
        require(_newToken != address(0));
        // replace with amount check logic
        // check can send, check can receive
        // check convert logic
        // WhiteListInterface whitelist = WhiteListInterface(_whitelist);
        // whitelist.isInWhiteList(_partition, _account);
        success = true;
    }

    // needs to have this contract as the operator of the 777 tokens
    function convertToken(
        address _account,
        address _oldToken,
        address _newToken,
        uint _amount,
        bytes memory _holderData,
        bytes memory _operatorData
    )
        public
        override
        returns (bool success)
    {
        require(_account != address(0) && _amount != 0 );
        require(_operatorData[0] != bytes1(0) && _holderData[0] != bytes1(0));
        // AG Remove for testing purposes only
        require(_canConvert(_account, _oldToken, _newToken, _amount));
        require(_oldToken != _newToken);

        IERC777 fromToken = IERC777(_oldToken);
        IBaseToken toToken = IBaseToken(_newToken);

        fromToken.operatorBurn(_account, _amount, _holderData, _operatorData);
        toToken.operatorMint(_account, _amount, _holderData, _operatorData);

        success = true;

    }
}

