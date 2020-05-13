pragma solidity ^0.6.2;

import "../Misc/Owned.sol";


contract Controlled is Owned {
    mapping(address => bool) public controllers;
    bool private mIsControllable;

    event ControllerAdded(address _controller);
    event ControllerRemoved(address _controller);

    modifier onlyController() {
        require(controllers[msg.sender] || isOwner());
        _;
    }

    function _initControlled(address _owner) internal {
        _initOwned(_owner);
        controllers[_owner] = true;
        mIsControllable = true;
    }

    function addController(address _controller) public   {
        require(isOwner());
        require(!controllers[_controller]);
        controllers[_controller] = true;
        emit ControllerAdded(_controller);
    }

    // AG To Do - Remove #2 - was put for test coverage purposes only 
    function removeController(address _controller) public  {
        require(isOwner());
        require(controllers[_controller]);
        delete controllers[_controller];
        emit ControllerRemoved(_controller);
    }
    
    function isController() public view returns (bool) {
        if (mIsControllable) {
            return controllers[msg.sender];
        }
        return false;
    }
    function isControllable() public virtual view returns (bool) {
        return mIsControllable;
    }
    function setControllable(bool _isControllable) public  {
        require(isOwner());
        mIsControllable = _isControllable;
    }
}
