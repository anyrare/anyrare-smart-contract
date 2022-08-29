// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollectionFactory {
    struct CollectionMintArgs {
        string name;
        string symbol;
        string tokenURI;
        uint8 lowestDecimal;
        uint8 precisionDigit;
        uint256 totalSupply;
        uint256 maxWeight;
        uint256 collectorFeeWeight;
        uint16 totalAsset;
        uint256[] assets;
    }
}
