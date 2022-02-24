// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import {CollectionERC20} from "./CollectionERC20.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import "hardhat/console.sol";

contract MemberFacet {
    AppStorage internal s;
    
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

    // function mintT(uint256 k) external {
    //     CollectionERC20 token = new CollectionERC20();
    //     token.setTemp(k);
    //     console.log(address(token));
    //     s.collections[s.totalCollection] = address(token);
    //     s.totalCollection += 1;
    // }

    // function getMintAddress(uint256 index) external view returns (address) {
    //     return s.collections[index];
    // }
}
