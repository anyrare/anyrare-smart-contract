// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract MemberFacet {
    function t1(address c) external {
        (bool success, bytes memory result) = c.call(
            abi.encodeWithSignature("t2()")
        );

        console.log(c);

        uint256 num;
        assembly {
            num := mload(add(result, 0x20))
        }

        console.log("MemberFacet: ", num);
    }
}
