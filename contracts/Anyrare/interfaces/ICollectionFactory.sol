// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollectionFactory {
    struct CollectionMintArgs {
        string name;
        string symbol;
        string tokenURI;
        uint8 decimal;
        uint8 precision;
        uint256 totalSupply;
        uint256 maxWeight;
        uint256 collectorFeeWeight;
        uint16 totalAsset;
        uint256[] assets;
    }

    struct CollectionLimitOrderArgs {
        address collectionAddr;
        uint256 collectionId;
        uint256 price;
        uint256 volume;
    }

    struct CollectionMarketOrderTargetVolumeArgs {
        uint256 collectionId;
        uint256 volume;
        uint256 slippage;
    }

    struct CollectionMarketOrderPriceList {
        uint8 posIndex;
        uint8 bitIndex;
        uint256 volume;
    }

    struct CollectionOrderPriceInfo {
        uint256 orderId;
        address owner;
        uint256 price;
        uint256 volume;
    }

    struct CollectionCalculateBuyMarketTransferListArgs {
        uint256 orderValue;
        uint256 collectionId;
        uint8 currencyDecimal;
        uint256 totalPriceInfo;
        CollectionOrderPriceInfo[] priceInfos;
    }

    struct CollectionBuyMarketTargetVolumeData {
        uint256 remainVolume;
        uint256 orderValue;
        uint256 totalOrderValue;
        uint256 priceSlot;
        uint256 volume;
    }
        
    struct CollectionSellMarketTargetVolumeData {
        uint256 remainVolume;
        uint256 orderValue;
        uint256 totalOrderValue;
        uint256 priceSlot;
        uint256 volume;
        uint256 platformFeeLM;
        uint256 collectorFeeLM;
        uint256 referralCollectorFeeLM;
        uint256 custodianFeeLM;
    }
}