pragma solidity ^0.8.0;

library LibUtils {
    function stringToBytes32(string memory str) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }
}
