pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";

library LibUtils {
    function stringToBytes32(string memory str)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(str));
    }

    function max(uint256 x, uint256 y) internal view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) internal view returns (uint256) {
        return x < y ? x : y;
    }

    function delegateCallFunc(
        LibDiamond.DiamondStorage storage ds,
        string memory func
    ) internal returns (bytes memory k) {
        bytes4 functionSelector = bytes4(keccak256(abi.encodePacked(func)));
        address facetAddress_ = ds
            .facetAddressAndSelectorPosition[functionSelector]
            .facetAddress;
        uint16 functionSelector_ = ds
            .facetAddressAndSelectorPosition[functionSelector]
            .selectorPosition;
        (bool success, bytes memory result) = address(facetAddress_)
            .delegatecall(abi.encodeWithSelector(functionSelector));

        return result;
    }
    
    function callFunc(
        LibDiamond.DiamondStorage storage ds,
        string memory func
    ) internal returns (bytes memory k) {
        bytes4 functionSelector = bytes4(keccak256(abi.encodePacked(func)));
        address facetAddress_ = ds
            .facetAddressAndSelectorPosition[functionSelector]
            .facetAddress;
        uint16 functionSelector_ = ds
            .facetAddressAndSelectorPosition[functionSelector]
            .selectorPosition;
        (bool success, bytes memory result) = address(facetAddress_)
            .call(abi.encodeWithSelector(functionSelector));

        return result;
    }
}
