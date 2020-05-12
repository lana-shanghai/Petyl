pragma solidity ^0.6.2;

import "../Misc/Owned.sol";


contract Controlled is Owned {
    mapping(address => bool) public controllers;

    event ControllerAdded(address _controller);
    event ControllerRemoved(address _controller);

    modifier onlyController() {
        require(controllers[msg.sender] || mOwner == msg.sender);
        _;
    }

    function _initControlled(address _owner) internal {
        _initOwned(_owner);
        controllers[_owner] = true;
    }

    function addController(address _controller) public  onlyOwner  {
        require(!controllers[_controller]);
        controllers[_controller] = true;
        emit ControllerAdded(_controller);
    }

    // AG To Do - Remove #2 - was put for test coverage purposes only 
    function removeController(address _controller) public  onlyOwner {
        require(controllers[_controller]);
        delete controllers[_controller];
        emit ControllerRemoved(_controller);
    }
    
    function isControllable() public view virtual returns (bool) {
        return controllers[msg.sender];
    }

}
