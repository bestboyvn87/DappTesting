pragma solidity ^0.4.23;

contract SmartPool {
    address public onwer;

    uint256 public constant BONUS = 5;
    uint256 public constant SOFT_CAP = 50000 ether;
    uint256 public constant MID_CAP = 100000 ether;
    uint256 public constant HARD_CAP = 150000 ether;
    uint256 public constant SALE_END_TIME = 1535281223; // Sunday, August 26, 2018 11:00:23 AM

    constructor() public {
        owner = msg.sender;
    }

    function deposit() external payable {}

    function getTotalAmount() public returns(uint256) {}

    function getUserInfo() public returns() {}

    function userWithdraw() public payable {}

    function ownerWithdrawNTY() public payable onlyOwner {}

    /**
    * Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * Allows the current owner to transfer control of the contract to a newOwner.
    * _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        require(_newOwner != address(0x0));
        owner = _newOwner;
    }

    /**
    * SafeMath
    * Math operations with safety checks that throw on error
    */
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
