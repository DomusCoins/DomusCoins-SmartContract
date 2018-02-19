pragma solidity ^0.4.19;
library Math {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 r = a + b;

        assert(r >= a);

        return r;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        assert(a >= b);

        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 r = a * b;

        assert(a == 0 || r / a == b);

        return r;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}