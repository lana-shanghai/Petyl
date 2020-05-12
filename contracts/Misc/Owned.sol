pragma solidity ^0.6.2;

contract Owned {

    address public mOwner;      // AG: should be private
    bool public initialised;    // AG: should be private

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function _initOwned(address _owner) internal {
        require(!initialised);
        mOwner = _owner;
        initialised = true;
        emit OwnershipTransferred(address(0), mOwner);
    }
    function owner() public view returns (address) {
        return mOwner;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == mOwner;
    }
    function transferOwnership(address newOwner) public {
        require(isOwner());
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(mOwner, newOwner);
        mOwner = newOwner;
    }
}
