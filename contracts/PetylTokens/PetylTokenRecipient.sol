pragma solidity ^0.6.2;

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// From https://github.com/0xjac/ERC777

// ----------------------------------------------------------------------------
// Deepyr's Dynamic Security Token
//
// Authors:
// * Adrian Guerrera / Deepyr Pty Ltd
//
// Oct 20 2018
// ----------------------------------------------------------------------------

import "../../interfaces/IERC777Recipient.sol";
import "../Misc/Owned.sol";
import "../ERCs/ERC1820Implementer.sol";


abstract PetylTokenRecipient is ERC1820Implementer, IERC777Recipient, Owned {

    bool private allowTokensReceived;
    bytes32 constant ERC777TokensRecipientHash = keccak256("ERC777TokensRecipient");
    bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256("ERC1820_ACCEPT_MAGIC");

    constructor(bool _setInterface) public {
        if (_setInterface) {
            setInterfaceImplementation("ERC777TokensRecipient", address(this));
        }
        allowTokensReceived = true;
    }

    function canReceive(
        bytes32 /*partition*/,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata /*operatorData*/
    )
        external
        view override 
        returns (bool)
    {
        require(allowTokensReceived, "Receive not allowed");
        return (_canReceive(from, to, value, data));
    }

    function tokensReceived(
        address /*operator*/,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata/*operatorData*/
    )
        external override 
    {
        require(allowTokensReceived, "Receive not allowed");
        require(_canReceive(from, to, value, data), "A6: Transfer Blocked - Receiver not eligible");

    }

    function _canReceive(
        address /*from*/,
        address /*to*/,
        uint /*value*/,
        bytes memory data
    ) // Comments to avoid compilation warnings for unused variables.
        internal
        pure
        returns (bool)
    {
        bytes32 receiveRevert = 0x2200000000000000000000000000000000000000000000000000000000000000;
        // Default recipient hook failure data for the mock only
        bytes32 data32;
        assembly {
            data32 := mload(add(data, 32))
        }
        if (data32 == receiveRevert) {
            return false;
        } else {
            return true;
        }
    }

    function acceptTokens() public  {
        require(isOwner());
        allowTokensReceived = true;
    }

    function rejectTokens() public {
        require(isOwner());
        allowTokensReceived = false;
    }

    function canImplementInterfaceForAddress(address /*addr*/, bytes32 /*interfaceHash*/)
        public
        pure
        returns (bytes32)
    {
        // require (interfaceHash == ERC777TokensRecipientHash);
        return ERC1820_ACCEPT_MAGIC;
    }
}
