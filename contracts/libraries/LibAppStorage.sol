pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";

struct AppStorage {
    uint256 x;
    uint256 y;
    uint256 sum;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}
