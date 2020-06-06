pragma solidity ^0.6.9;

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
//  Petyl Token Rules (PTR)                                      :
//  https://www.petyl.com                                        :
//                                                               :
//  Authors:                                                     :
//  * Adrian Guerrera / Deepyr Pty Ltd                           :
//                                                               :
//  (c) Adrian Guerrera.  MIT Licence.                           :                                                         :
//  Oct 20 2018                                                  :
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// SPDX-License-Identifier: MIT


import "../../interfaces/IERC777.sol";
import "../../interfaces/IERC777TokenRules.sol";
import "../../interfaces/IERC777Recipient.sol";
import "../../interfaces/IERC777Sender.sol";
import "../Utils/Controlled.sol";
import "../Utils/CanSendCodes.sol";
import "../ERCs/ERC1820Implementer.sol";
import "../../interfaces/IERC1820Registry.sol";

import "@openzeppelin/contracts/GSN/Context.sol";


contract PetylTokenRules is IERC777Sender,IERC777Recipient,  Controlled , Context, ERC1820Implementer, CanSendCodes  {

    event TokensToSendCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    event TokensReceivedCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    bool public allowTokensToSend;  // AG: Private
    bool public allowTokensToReceive;  // AG: Private

    // keccak256("ERC777TokenRules")
    bytes32 constant private TOKEN_RULES_INTERFACE_HASH =
        0xc4a4c123287cf7b0d8046a21e081e4b2801e57af59a2546c99adf112443f5012;

    // keccak256("ERC777Token")
    bytes32 constant private ERC777_TOKENS_INTERFACE_HASH =
        0xac7fbab5f54a3ca8194167523c6753bfeb96a445279294b6125b68cce2177054;

    // keccak256("ERC777TokensSender")
    bytes32 constant private TOKENS_SENDER_INTERFACE_HASH =
        0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;

    // keccak256("ERC777TokensRecipient")
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    IERC1820Registry constant internal _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    constructor() public {
        allowTokensToSend = true;
        allowTokensToReceive = true;
        _initControlled(msg.sender);
    }


    function registerToken(address account) public {  // AG Permissioned or public ?
        _registerInterfaceForAddress(TOKEN_RULES_INTERFACE_HASH, account);
        _registerInterfaceForAddress(TOKENS_SENDER_INTERFACE_HASH, account);
        _registerInterfaceForAddress(TOKENS_RECIPIENT_INTERFACE_HASH, account);
    }

    // Regulalor restrictions
    function canTransfer(
 bytes32 _partition,
        address _from,
        address _to,
        uint _value,
        bytes calldata _userData,
        bytes calldata _operatorData
    ) // Comments to avoid compilation warnings for unused variables.
    external pure returns(byte, bytes32, bytes32) {
        return(_canTransfer(_partition,_from, _to, _value, _userData, _operatorData));
    }

// //-------------------------------------------
// //      Token Transfers
// //-------------------------------------------

    function _canTransfer(  bytes32 _partition,  address _from, address _to, uint256 _value, bytes memory _userData , bytes memory _operatorData)
      internal pure returns (byte, bytes32, bytes32)
      {

        // Check transfer restrictions
        if(!_canSend(_partition, _from, _to, _value, _userData, _operatorData)) {
           return(TRANSFER_BLOCKED_SENDER_NOT_ELIGIBLE, "", ""); // Transfer Blocked - Sender not eligible
        }
        if(!_canReceive(_partition,_from, _to, _value, _userData, _operatorData)) {
           return(TRANSFER_BLOCKED_RECEIVER_NOT_ELIGIBLE, "", ""); // Transfer Blocked - Receiver not eligible
        }

        // Verify using ofchain approval
        return(TRANSFER_VERIFIED_OFFCHAIN_APPROVAL, "", "");  // Transfer Verified - Off-Chain approval for restricted token
    }

    function tokensToTransfer(
        address _operator,
        address _from,
        address _to,
        uint _value,
        bytes calldata _userData,
        bytes calldata _operatorData
    )
    external view {
        require(allowTokensToSend, "Send not allowed");
        require(allowTokensToReceive, "Receive not allowed");
        // solhint-disable-next-line no-unused-vars
        (byte CanSendCode, bytes32 data32, bytes32 partition) = _canTransfer('',_from,_to, _value, _userData, _operatorData);
        require(data32 != partition, "Test, remove this");   // AG Test, remove this
        require((CanSendCode != TRANSFER_BLOCKED_TOKEN_GRANULARITY), "Transfer not allowed by rules");
        require((CanSendCode != TRANSFER_BLOCKED_RECEIVER_NOT_ELIGIBLE), "Transfer Blocked - Receiver not eligible");

        // AG To Do: Push events to token contract, then to 1400 token.

    }

//-------------------------------------------
//   Token Transfers - Sending Tokens
//-------------------------------------------

    function canSend(bytes32 _partition,
      address _from,
      address _to,
      uint _value,
      bytes calldata _userData,
      bytes calldata _operatorData
    ) // Comments to avoid compilation warnings for unused variables.
    external view override returns(bool) {
        require(allowTokensToSend, "Send not allowed");
        return(_canSend(_partition,_from, _to, _value, _userData, _operatorData));
    }


    function tokensToSend(
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _userData,
        bytes calldata _operatorData
    ) external override {
        if (allowTokensToSend == false) {
            revert();
        }

        IERC777 token = IERC777(_msgSender());
        // AG: Get partition from 1400, else 0x
        uint256 fromBalance = token.balanceOf(_from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = token.balanceOf(_to);
        require(_canSend( '',_from, _to, _value, _userData, _operatorData), "A5:	Transfer Blocked - Sender not eligible");

        emit TokensToSendCalled(
            _operator,
            _from,
            _to,
            _value,
            _userData,
            _operatorData,
            address(token),
            fromBalance,
            toBalance
        );
    }

    function _canSend(
        bytes32 _partition, 
        address _from,
        address _to,
        uint _value,
        bytes memory _userData,
        bytes memory _operatorData
    ) // Comments to avoid compilation warnings for unused variables.
    internal pure returns(bool) {

    //   // Token transfers
    //     address tokenImplementation = _ERC1820_REGISTRY.getInterfaceImplementer(_from, ERC777_TOKENS_INTERFACE_HASH);

    //   if((tokenImplementation != address(0)) && !IERC777(tokenImplementation).isOperatorFor(_operator, _from)) {
    //      return false; // "Transfer Blocked - Identity restriction"
    //   }
    //   if  ((tokenImplementation != address(0)) && (IERC777(tokenImplementation).balanceOf(_from) < _value)) {
    //      return false; // Transfer Blocked - Sender balance insufficient
    //   }

    //   // Check if token sender and reciever interfaces are being used
    //     address senderImplementation = _ERC1820_REGISTRY.getInterfaceImplementer(_from, TOKENS_SENDER_INTERFACE_HASH);

    //   if((senderImplementation != address(0)) && !IERC777Sender(senderImplementation).canSend( _from, _to, _value, _userData, _operatorData)) {
    //      return false; // Transfer Blocked - Sender not eligible
    //   }
      return true;
    }

//-------------------------------------------
//   Token Transfers - Receiving Tokens
//-------------------------------------------

    function canReceive(
      bytes32 _partition,
      address _from,
      address _to,
      uint _value,
      bytes calldata _userData,
      bytes calldata _operatorData
    ) // Comments to avoid compilation warnings for unused variables.
    external view override returns(bool) {
        require(allowTokensToReceive, "Receive not allowed");
        return(_canReceive(_partition,_from, _to, _value, _userData, _operatorData));
    }

    function tokensReceived(
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _userData,
        bytes calldata _operatorData
    ) external override {
        if (allowTokensToReceive == false) {
            revert();
        }

        IERC777 token = IERC777(_msgSender());

        uint256 fromBalance = token.balanceOf(_from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = token.balanceOf(_to);
        require(_canReceive( '',_from, _to, _value, _userData, _operatorData), "A6: Transfer Blocked - Receiver not eligible");

        emit TokensReceivedCalled(
            _operator,
            _from,
            _to,
            _value,
            _userData,
            _operatorData,
            address(token),
            fromBalance,
            toBalance
        );
    }

    function _canReceive(
      bytes32 _partition,
      address _from,
      address _to,
      uint _value,
      bytes memory _userData,
      bytes memory _operatorData
    ) internal pure returns(bool) {

        // // Check token
        // address tokenImplementation = _ERC1820_REGISTRY.getInterfaceImplementer(_from, ERC777_TOKENS_INTERFACE_HASH);

        // if((tokenImplementation != address(0)) && !IERC777(tokenImplementation).isOperatorFor(_operator, _from)) {
        //    return false; // "Transfer Blocked - Identity restriction"
        // }
        // if(_to == address(0)) {
        //    return false ; // Transfer Blocked - Receiver not eligible
        // }
        // // if((tokenImplementation != address(0)) && !IERC777(tokenImplementation).isMultiple(_value)) {
        // //    return false; // Transfer Blocked - Receiver not eligible
        // // }

        // // Check if token sender and reciever interfaces are being used
        // address receiverImplementation = _ERC1820_REGISTRY.getInterfaceImplementer(_from, TOKENS_RECIPIENT_INTERFACE_HASH);

        // if((receiverImplementation != address(0)) && !IERC777Sender(receiverImplementation).canSend( _from, _to, _value, _userData, _operatorData)) {
        //    return false; // Transfer Blocked - Sender not eligible
        // }
        return true;
    }



    function senderFor(address account) public {
        _registerInterfaceForAddress(TOKENS_SENDER_INTERFACE_HASH, account);

        address self = address(this);
        if (account == self) {
            registerSender(self);
        }
    }

    function registerSender(address sender) public {
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_SENDER_INTERFACE_HASH, sender);
    }

    function recipientFor(address account) public {
        _registerInterfaceForAddress(TOKENS_RECIPIENT_INTERFACE_HASH, account);

        address self = address(this);
        if (account == self) {
            registerRecipient(self);
        }
    }

    function registerRecipient(address recipient) public {
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, recipient);
    }

    function setShouldRevertSend(bool allowTokens) public {
        allowTokensToSend = allowTokens;
    }

    function setShouldRevertReceive(bool allowTokens) public {
        allowTokensToReceive = allowTokens;
    }

    // function send(IERC777 token, address to, uint256 amount, bytes memory data) public {
    //     // This is 777's send function, not the Solidity send function
    //     token.send(to, amount, data); // solhint-disable-line check-send-result
    // }

    // function burn(IERC777 token, uint256 amount, bytes memory data) public {
    //     token.burn(amount, data);
    // }


    // // solhint-disable-next-line no-unused-vars
    // function canImplementInterfaceForAddress(address addr, bytes32 interfaceHash) public view returns(bytes32) {
    //     require(addr != address(0) && (interfaceHash == TOKEN_RULES_INTERFACE_HASH || interfaceHash == TOKENS_SENDER_INTERFACE_HASH || interfaceHash == TOKENS_RECIPIENT_INTERFACE_HASH));
    //     return keccak256("ERC1820_ACCEPT_MAGIC");
    // }

}
