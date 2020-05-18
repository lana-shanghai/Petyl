pragma solidity ^0.6.2;

import "../../interfaces/IERC777Sender.sol";
import "../Misc/Owned.sol";
import "../ERCs/ERC1820Implementer.sol";


abstract PetylTokenSender is IERC777Sender, ERC1820Implementer, Owned {

    bool private allowTokensToSend;
    bytes32 constant ERC777TokensSenderHash = keccak256("ERC777TokensSender");
    bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256("ERC1820_ACCEPT_MAGIC");

    constructor(string memory /*interfaceLabel*/) public /* ERC1820Implementer(interfaceLabel) */ {
        allowTokensToSend = true;
    }


    function acceptTokensToSend() public  {
        require(isOwner());
        allowTokensToSend = true;
    }

    function rejectTokensToSend() public {
        require(isOwner());
        allowTokensToSend = false;
    }

    function canSend(
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
        return (_canSend(from, to, value, data));
    }

    function tokensToSend(
        address /*operator*/,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata /*operatorData*/
    )
        external override 
    {
        require(allowTokensToSend, "Send not allowed");
        require(_canSend(from, to, value, data), "A5:	Transfer Blocked - Sender not eligible");
    }

    function _canSend(
        address /*from*/,
        address /*to*/,
        uint /*value*/,
        bytes memory data
    )
        internal
        pure
        returns (bool)
    {
        bytes32 transferRevert = 0x1100000000000000000000000000000000000000000000000000000000000000;
        // Default sender hook failure data for the mock only
        bytes32 data32;
        assembly {
            data32 := mload(add(data, 32))
        }
        if (data32 == transferRevert) {
            return false;
        } else {
            return true;
        }
    }

    function canImplementInterfaceForAddress(address /*addr*/, bytes32 /*interfaceHash*/)
        public
        pure
        returns (bytes32)
    {
        // require (interfaceHash == ERC777TokensSenderHash);
        return ERC1820_ACCEPT_MAGIC;
    }
}
