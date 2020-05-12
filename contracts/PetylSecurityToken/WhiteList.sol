pragma solidity ^0.6.2;

// ----------------------------------------------------------------------------
// BokkyPooBah's White List
//
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd. The MIT Licence.
// ----------------------------------------------------------------------------

import "../Misc/Controlled.sol";
import "../../interfaces/WhiteListInterface.sol";


// ----------------------------------------------------------------------------
// White List - on list or not
// ----------------------------------------------------------------------------
contract WhiteList is WhiteListInterface, Controlled {
    mapping(address => bool) public whiteList;

    event AccountListed(address indexed account, bool status);

    constructor() public {
    }

    function initWhiteList(address _owner) public override{
        _initControlled(_owner);
    }

    function isInWhiteList(address account) public view override returns (bool) {
        return whiteList[account];
    }

    function addWhiteList(address[] memory accounts) public override {  
        require(controllers[msg.sender] || mOwner == msg.sender);
        require(accounts.length != 0);
        for (uint i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0));
            if (!whiteList[accounts[i]]) {
                whiteList[accounts[i]] = true;
                emit AccountListed(accounts[i], true);
            }
        }
    }
    function removeWhiteList(address[] memory accounts) public override {
        require(controllers[msg.sender] || mOwner == msg.sender);
        require(accounts.length != 0);
        for (uint i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0));
            if (whiteList[accounts[i]]) {
                delete whiteList[accounts[i]];
                emit AccountListed(accounts[i], false);
            }
        }
    }
}
