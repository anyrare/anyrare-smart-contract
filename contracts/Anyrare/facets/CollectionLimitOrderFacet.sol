// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {CollectionERC20} from "./CollectionERC20.sol";
import {AppStorage, CollectionInfo, CollectionOrderbookInfo, CollectionOrder} from "../libraries/LibAppStorage.sol";
import {ICurrency} from "../interfaces/ICurrency.sol";
import {ICollectionFactory} from "../interfaces/ICollectionFactory.sol";
import {IERC20} from "../../shared/interfaces/IERC20.sol";
import {AssetFacet} from "../../Asset/facets/AssetFacet.sol";
import {ARAFacet} from "../../ARA/facets/ARAFacet.sol";
import {AssetInfo, AssetAuction} from "../../Asset/libraries/LibAppStorage.sol";
import "./CollectionERC20.sol";
import "../libraries/LibData.sol";
import "../libraries/LibCollectionFactory.sol";
import "../../shared/libraries/LibUtils.sol";
import "hardhat/console.sol";

contract CollectionLimitOrderFacet {
    AppStorage internal s;

    function currency() internal view returns (IERC20) {
        require(
            s.contractAddress.currency != address(0),
            "CollectionFactoryFacet: currency address cannot be 0"
        );
        return IERC20(s.contractAddress.currency);
    }

    function collection(uint256 collectionId) internal view returns (IERC20) {
        return IERC20(s.collection.collections[collectionId].addr);
    }

    function buyLimit(ICollectionFactory.CollectionLimitOrderArgs memory args)
        external
        payable
    {
        require(
            LibData.isMember(s, msg.sender) &&
                !s.collection.collections[args.collectionId].isFreeze
        );

        uint256 orderValue = LibCollectionFactory
            .calculateCurrencyFromPriceSlot(
                args.price * args.volume,
                currency().decimals(),
                s.collection.collections[args.collectionId].decimal
            );

        uint256 platformFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_LIQUIDITY_MAKER_FEE"
        );

        uint256 referralFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_REFERRAL_LIQUIDITY_MAKER_FEE"
        );

        uint256 collectorFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_COLLECTOR_FEE"
        ) / 2;

        uint256 referralCollectorFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_REFERRAL_COLLECTOR_FEE"
        ) / 2;

        uint256 custodianFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_CUSTODIAN_FEE"
        ) / 2;

        currency().transferFrom(
            msg.sender,
            address(this),
            orderValue +
                platformFee +
                referralFee +
                collectorFee +
                referralCollectorFee +
                custodianFee
        );

        uint256 priceIndex = LibUtils.calculatePriceIndex(
            args.price,
            s.collection.collections[args.collectionId].precision
        );

        (uint8 posIndex, uint8 bitIndex) = LibUtils.calculatePriceIndexSlot(
            priceIndex
        );

        s.collection.bidsPrice[args.collectionId][posIndex] |= (1 << bitIndex);
        s.collection.bidsVolume[args.collectionId][posIndex][bitIndex] += args
            .volume;
        s.collection.bidsInfo[
            s.collection.totalBidInfo
        ] = CollectionOrderbookInfo({
            collectionId: args.collectionId,
            owner: msg.sender,
            price: args.price,
            volume: args.volume,
            filledVolume: 0,
            timestamp: block.timestamp,
            status: 0,
            posIndex: posIndex,
            bitIndex: bitIndex,
            platformFee: platformFee,
            referralFee: referralFee,
            collectorFee: collectorFee,
            referralCollectorFee: referralCollectorFee,
            custodianFee: custodianFee
        });
        s.collection.bidsInfoIndex[args.collectionId][posIndex][bitIndex][
            s.collection.bidsInfoIndexTotal[args.collectionId][posIndex][
                bitIndex
            ]++
        ] = s.collection.totalBidInfo;

        if (posIndex < s.collection.bidsPriceFirstPosIndex[args.collectionId]) {
            s.collection.bidsPriceFirstPosIndex[args.collectionId] = posIndex;
        }

        if (posIndex > s.collection.bidsPriceLastPosIndex[args.collectionId]) {
            s.collection.bidsPriceLastPosIndex[args.collectionId] = posIndex;
        }

        s.collection.bidsInfoIndexByAddress[args.collectionId][msg.sender] = s
            .collection
            .totalBidInfo;
        s.collection.totalBidInfoByAddress[args.collectionId][msg.sender]++;

        s.collection.totalBidInfo++;
    }

    function sellLimit(ICollectionFactory.CollectionLimitOrderArgs memory args)
        external
        payable
    {
        require(
            LibData.isMember(s, msg.sender) &&
                !s.collection.collections[args.collectionId].isFreeze
        );

        collection(args.collectionId).transferFrom(
            msg.sender,
            address(this),
            args.volume
        );

        uint256 orderValue = LibCollectionFactory
            .calculateCurrencyFromPriceSlot(
                args.price * args.volume,
                currency().decimals(),
                s.collection.collections[args.collectionId].decimal
            );

        uint256 platformFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_LIQUIDITY_MAKER_FEE"
        );

        uint256 referralFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_REFERRAL_LIQUIDITY_MAKER_FEE"
        );

        uint256 collectorFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_COLLECTOR_FEE"
        ) / 2;

        uint256 referralCollectorFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_REFERRAL_COLLECTOR_FEE"
        ) / 2;

        uint256 custodianFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_CUSTODIAN_FEE"
        ) / 2;

        uint256 priceIndex = LibUtils.calculatePriceIndex(
            args.price,
            s.collection.collections[args.collectionId].precision
        );

        (uint8 posIndex, uint8 bitIndex) = LibUtils.calculatePriceIndexSlot(
            priceIndex
        );

        s.collection.offersPrice[args.collectionId][posIndex] |= (1 <<
            bitIndex);
        s.collection.offersVolume[args.collectionId][posIndex][bitIndex] += args
            .volume;
        s.collection.offersInfo[
            s.collection.totalOfferInfo
        ] = CollectionOrderbookInfo({
            collectionId: args.collectionId,
            owner: msg.sender,
            price: args.price,
            volume: args.volume,
            filledVolume: 0,
            timestamp: block.timestamp,
            status: 0,
            posIndex: posIndex,
            bitIndex: bitIndex,
            platformFee: platformFee,
            collectorFee: collectorFee,
            referralFee: referralFee,
            referralCollectorFee: referralCollectorFee,
            custodianFee: custodianFee
        });
        s.collection.offersInfoIndex[args.collectionId][posIndex][bitIndex][
            s.collection.offersInfoIndexTotal[args.collectionId][posIndex][
                bitIndex
            ]++
        ] = s.collection.totalOfferInfo;

        if (
            posIndex < s.collection.offersPriceFirstPosIndex[args.collectionId]
        ) {
            s.collection.offersPriceFirstPosIndex[args.collectionId] = posIndex;
        }

        if (
            posIndex > s.collection.offersPriceLastPosIndex[args.collectionId]
        ) {
            s.collection.offersPriceLastPosIndex[args.collectionId] = posIndex;
        }

        s.collection.offersInfoIndexByAddress[args.collectionId][msg.sender] = s
            .collection
            .totalOfferInfo;
        s.collection.totalOfferInfoByAddress[args.collectionId][msg.sender]++;

        s.collection.totalOfferInfo++;
    }

    function cancelBuyLimit(uint256 bidId) external {
        require(
            s.collection.bidsInfo[bidId].owner == msg.sender &&
                s.collection.bidsInfo[bidId].status == 0 &&
                (s.collection.bidsInfo[bidId].volume >
                    s.collection.bidsInfo[bidId].filledVolume)
        );
        currency().transferFrom(
            address(this),
            msg.sender,
            LibCollectionFactory.calculateCurrencyFromPriceSlot(
                (s.collection.bidsInfo[bidId].volume -
                    s.collection.bidsInfo[bidId].filledVolume) *
                    s.collection.bidsInfo[bidId].price,
                currency().decimals(),
                s
                    .collection
                    .collections[s.collection.bidsInfo[bidId].collectionId]
                    .decimal
            )
        );
        s.collection.bidsInfo[bidId].status == 2;
    }

    function cancelSellLimit(uint256 offerId) external {
        require(
            s.collection.offersInfo[offerId].owner == msg.sender &&
                s.collection.offersInfo[offerId].status == 0 &&
                s.collection.offersInfo[offerId].volume >
                s.collection.offersInfo[offerId].filledVolume
        );
        collection(s.collection.offersInfo[offerId].collectionId).transferFrom(
            address(this),
            msg.sender,
            s.collection.offersInfo[offerId].volume -
                s.collection.offersInfo[offerId].filledVolume
        );
        s.collection.offersInfo[offerId].status = 2;
    }

    function transferCurrencyFromContract(
        ICurrency.TransferCurrency[] memory lists,
        uint8 length
    ) private {
        for (uint8 i = 0; i < length; i++) {
            if (lists[i].amount > 0) {
                uint256 amount = LibUtils.min(
                    lists[i].amount,
                    currency().balanceOf(address(this))
                );

                if (lists[i].receiver == address(this)) {
                    s.managementFund.managementFundValue += amount;
                } else {
                    currency().transferFrom(
                        address(this),
                        lists[i].receiver,
                        amount
                    );
                }
            }
        }
    }
}
