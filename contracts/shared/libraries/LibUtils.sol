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

    function facetAddressAndFunctionSelector(
        LibDiamond.DiamondStorage storage ds,
        string memory func
    ) internal returns (address, bytes4) {
        bytes4 functionSelector = bytes4(keccak256(abi.encodePacked(func)));
        address facetAddress = ds
            .facetAddressAndSelectorPosition[functionSelector]
            .facetAddress;

        return (facetAddress, functionSelector);
    }

    function delegateCallFunc(
        LibDiamond.DiamondStorage storage ds,
        address facetAddress,
        bytes memory data
    ) internal returns (bytes memory k) {
        (bool success, bytes memory result) = address(facetAddress)
            .delegatecall(data);

        return result;
    }

    function callFunc(LibDiamond.DiamondStorage storage ds, string memory func)
        internal
        returns (bytes memory k)
    {
        bytes4 functionSelector = bytes4(keccak256(abi.encodePacked(func)));
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

    function bytesToAddress(bytes memory k) internal returns (address) {
        address addr;
        assembly {
            addr := mload(add(k, 0x20))
        }
        return addr;
    }

    function bytesToUint256(bytes memory k) internal returns (uint256) {
        uint256 value;
        assembly {
            value := mload(add(k, 0x20))
        }
        return value;
    }
}
