pragma solidity ^0.4.23;

/**
 * @title SafeMaths
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
        function weiToEther(uint256 value) internal constant returns (uint256) {
        return div(value,1000000000000000000);
    }
    
    function etherToWei(uint256 value) internal constant returns (uint256) {
        return mul(value,1000000000000000000);
    }
    
    function toBytes(uint256 x) internal constant returns (bytes b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
    
    function log(uint256 x) internal constant returns(uint256) { //tested
        assert(x>0);
        uint256 i=0;
        uint256 exp=1;
        while (exp<x) {
            exp*=2;
            i++;
        }
        if (exp!=x) return 0;
        return i;
    }
}
