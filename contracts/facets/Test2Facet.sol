// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {LibUtils} from "../libraries/LibUtils.sol";

contract Test2Facet {
    AppStorage internal s;

    function test2Func1() external {}

    function test2Func2() external {}

    function test2Func3() external {}

    function test2Func4() external {}

    function test2Func5() external {}

    function test2Func6() external {}

    function test2Func7() external {}

    function test2Func8() external {}

    function test2Func9() external {}

    function test2Func10() external {}

    function test2Func11() external {}

    function test2Func12() external {}

    function test2Func13() external {}

    function test2Func14() external {}

    function test2Func15() external {}

    function test2Func16() external {}

    function test2Func17() external {}

    function test2Func18() external {}

    function test2Func19() external {}

    function test2Func20() external {}

    function callAdd2() public returns (uint256) {
        // LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // bytes memory result = LibUtils.delegateCallFunc(
        //     ds,
        //     "add(uint256,uint256)"
        // );
        
        // uint256 x;
        // assembly {
        //     x := mload(add(result, 0x20))
        // }
        // return x;
        return 25;
    }

    function callAdd() external {
        s.x = 5;
        s.y = 7;
        s.sum = s.x + s.y;
    }

    function callAddView() external view returns (uint256) {
        return s.sum;
    }

    function callAddAndSave() external {
        uint256 a = callAdd2();

        s.x = a;
        s.y = 100;
        s.sum = s.x + s.y;
    }

    function callSender() public returns (bytes memory k) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 functionSelector = bytes4(keccak256("sender()"));
        address facetAddress_ = ds
            .facetAddressAndSelectorPosition[functionSelector]
            .facetAddress;
        uint16 functionSelector_ = ds
            .facetAddressAndSelectorPosition[functionSelector]
            .selectorPosition;
        (bool success, bytes memory result) = address(facetAddress_).call(
            abi.encodeWithSelector(functionSelector)
        );

        return result;
    }

    function callSenderSave() external returns (bytes memory k) {
        bytes memory m = callSender();
        s.m = m;
    }

    function callSenderView() external view returns (address k) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 functionSelector = bytes4(keccak256("bbb212()"));
        address facetAddress_ = ds
            .facetAddressAndSelectorPosition[functionSelector]
            .facetAddress;

        return address(this);
    }

    function callSenderStorage() external {
        uint8 a = 3;
        bytes memory m = callSender();
        address x;
        assembly {
            x := mload(add(m, 0x20))
        }

        s.m2 = x;
    }

    function callSenderStorageView() external view returns (address m) {
        return s.m2;
    }
}
