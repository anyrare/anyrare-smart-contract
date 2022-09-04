// SPDX-License-Identifier: MIT
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

    function countDigit(uint256 num) internal view returns (uint8) {
        uint8 digit = 0;
        while (num > 0) {
            num /= 10;
            digit++;
        }
        return digit;
    }

    function calculatePriceIndex(uint256 num, uint8 precision)
        internal
        view
        returns (uint256 index)
    {
        uint8 digit = countDigit(num);
        uint8 power = digit > precision ? digit - precision : 0;
        return (10**(precision)) * power + (num / (10**power));
    }

    function calculatePriceIndexSlot(uint256 priceIndex)
        internal
        view
        returns (uint8, uint8)
    {
        uint8 posIndex = uint8(priceIndex / 256);
        uint8 bitIndex = uint8(priceIndex % 256);
        return (posIndex, bitIndex);
    }

    function getPriceFromPriceIndex(
        uint8 posIndex,
        uint8 bitIndex,
        uint8 precision
    ) internal view returns (uint256) {
        return (10**precision) * posIndex + bitIndex;
    }

    function findValueKthBit(uint256 n, uint16 k) internal view returns (uint16) {
        return uint16((n & (1 << (k - 1))) >> (k - 1));
    }

    function maxBitIndex(uint256 n) internal view returns (uint8) {
        uint8 count = 0;
        while (n > 0) {
            count++;
            n >>= 1;
        }
        return count == 0 ? 0 : uint8(count - 1);
    }
}
