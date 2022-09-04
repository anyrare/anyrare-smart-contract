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

contract CollectionFactoryFacet {
    AppStorage internal s;

    function currency() internal view returns (IERC20) {
        require(
            s.contractAddress.currency != address(0),
            "CollectionFactoryFacet: currency address cannot be 0"
        );
        return IERC20(s.contractAddress.currency);
    }

    function asset() internal view returns (AssetFacet) {
        require(
            s.contractAddress.assetDiamond != address(0),
            "CollectionFactoryFacet: assetDiamond address cannot be 0"
        );
        return AssetFacet(s.contractAddress.assetDiamond);
    }

    function collection(uint256 collectionId) internal view returns (IERC20) {
        return IERC20(s.collection.collections[collectionId].addr);
    }

    function mintCollection(ICollectionFactory.CollectionMintArgs memory args)
        external
        payable
    {
        require(
            LibData.isMember(s, msg.sender) &&
                args.totalAsset > 0 &&
                args.totalSupply > 0
        );

        CollectionERC20 token = new CollectionERC20();
        token.setMetadata(args.name, args.symbol, args.tokenURI);

        for (uint16 i; i < args.totalAsset; i++) {
            require(asset().ownerOf(args.assets[i]) == msg.sender);
        }

        for (uint16 i; i < args.totalAsset; i++) {
            asset().transferFrom(msg.sender, address(this), args.assets[i]);
            s.collection.collectionAssets[s.collection.totalCollection][
                i
            ] = args.assets[i];
        }

        transferCurrencyFromContract(
            LibCollectionFactory.calculateMintCollectionFeeLists(s, msg.sender),
            2
        );

        token.mintTo(msg.sender, args.totalSupply);

        s.collection.collectionIndexes[address(token)] = s
            .collection
            .totalCollection;
        s.collection.collections[
            s.collection.totalCollection
        ] = CollectionInfo({
            addr: address(token),
            collector: msg.sender,
            name: args.name,
            symbol: args.symbol,
            tokenURI: args.tokenURI,
            decimal: args.decimal,
            precision: args.precision,
            totalSupply: args.totalSupply,
            maxWeight: args.maxWeight,
            collectorFeeWeight: args.collectorFeeWeight,
            totalAsset: args.totalAsset,
            totalShareholder: 1,
            isAuction: false,
            isFreeze: false,
            targetPrice: 0,
            targetPriceTotalSum: 0,
            targetPriceTotalVoteToken: 0,
            targetPriceTotalVoter: 0
        });

        s.collection.shareholders[s.collection.totalCollection][0] = msg.sender;
        s.collection.shareholderIndexes[s.collection.totalCollection][
            msg.sender
        ] = 0;
        s.collection.totalCollection += 1;
    }

    function buyLimit(ICollectionFactory.CollectionLimitOrderArgs memory args)
        external
        payable
    {
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

        require(LibData.isMember(s, msg.sender));

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
            orderValue: orderValue,
            platformFee: platformFee,
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

        s.collection.totalBidInfo++;

        // TODO: Add order detail for user to cancel
    }

    function sellLimit(ICollectionFactory.CollectionLimitOrderArgs memory args)
        external
        payable
    {
        require(
            LibData.isMember(s, msg.sender) &&
                collection(args.collectionId).balanceOf(msg.sender) >=
                args.volume
        );

        collection(args.collectionId).transferFrom(
            msg.sender,
            address(this),
            args.volume
        );

        // TODO: Fee

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
            status: 0
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

        s.collection.totalOfferInfo++;
    }

    function buyMarketTargetVolume(
        ICollectionFactory.CollectionMarketOrderTargetVolumeArgs memory args
    ) external payable {
        ICollectionFactory.CollectionBuyMarketTargetVolumeData memory data;
        data.remainVolume = args.volume;
        data.orderValue;
        data.totalOrderValue = 0;

        require(
            collection(args.collectionId).balanceOf(address(this)) >=
                args.volume &&
                LibData.isMember(s, msg.sender),
            "Not Enough Volume"
        );

        uint8 posIndex = s.collection.offersPriceFirstPosIndex[
            args.collectionId
        ];

        while (
            posIndex <=
            s.collection.offersPriceLastPosIndex[args.collectionId] &&
            data.remainVolume > 0
        ) {
            data.priceSlot = s.collection.offersPrice[args.collectionId][
                posIndex
            ];
            if (data.priceSlot == 0) continue;

            uint8 bitIndex = 0;
            while (data.remainVolume > 0 && bitIndex < 255) {
                if (
                    LibUtils.findValueKthBit(data.priceSlot, bitIndex + 1) == 1
                ) {
                    for (
                        uint256 orderbookInfoIndexByPriceSlot = s
                            .collection
                            .offersInfoIndexStart[args.collectionId][posIndex][
                                bitIndex
                            ];
                        orderbookInfoIndexByPriceSlot <
                        s.collection.offersInfoIndexTotal[args.collectionId][
                            posIndex
                        ][bitIndex] &&
                            data.remainVolume > 0;
                        orderbookInfoIndexByPriceSlot++
                    ) {
                        uint256 orderbookInfoIndex = s
                            .collection
                            .offersInfoIndex[args.collectionId][posIndex][
                                bitIndex
                            ][orderbookInfoIndexByPriceSlot];

                        if (
                            s
                                .collection
                                .offersInfo[orderbookInfoIndex]
                                .status != 0
                        ) continue;

                        data.volume = LibUtils.min(
                            data.remainVolume,
                            s.collection.offersInfo[orderbookInfoIndex].volume
                        );
                        s
                            .collection
                            .offersInfo[orderbookInfoIndex]
                            .filledVolume += data.volume;
                        data.remainVolume -= data.volume;

                        if (
                            s
                                .collection
                                .offersInfo[orderbookInfoIndex]
                                .filledVolume ==
                            s.collection.offersInfo[orderbookInfoIndex].volume
                        ) {
                            s
                                .collection
                                .offersInfo[orderbookInfoIndex]
                                .status = 1;
                            s.collection.offersInfoIndexStart[
                                args.collectionId
                            ][posIndex][bitIndex] = orderbookInfoIndex + 1;

                            if (
                                orderbookInfoIndex + 1 ==
                                s.collection.offersInfoIndexTotal[
                                    args.collectionId
                                ][posIndex][bitIndex]
                            ) {
                                s.collection.offersPriceFirstPosIndex[
                                    args.collectionId
                                ]++;
                            }
                        }

                        data.orderValue = LibCollectionFactory
                            .calculateCurrencyFromPriceSlot(
                                LibUtils.getPriceFromPriceIndex(
                                    posIndex,
                                    bitIndex,
                                    s
                                        .collection
                                        .collections[args.collectionId]
                                        .precision
                                ) * data.volume,
                                currency().decimals(),
                                s
                                    .collection
                                    .collections[args.collectionId]
                                    .decimal
                            );

                        data.totalOrderValue += data.orderValue;

                        currency().transferFrom(
                            msg.sender,
                            address(this),
                            LibCollectionFactory
                                .calculateBuyMarketTransferValue(
                                    s,
                                    data.orderValue
                                )
                        );

                        transferCurrencyFromContract(
                            LibCollectionFactory.calculateBuyMarketTransferList(
                                s,
                                data.orderValue,
                                s
                                    .collection
                                    .collections[args.collectionId]
                                    .collector,
                                s
                                    .collection
                                    .offersInfo[orderbookInfoIndex]
                                    .owner
                            ),
                            1
                        );
                    }
                }
                bitIndex++;
            }

            if (posIndex == 255) break;
            posIndex++;
        }

        require(
            data.remainVolume == 0 &&
                (args.slippage == 0 || data.orderValue <= args.slippage)
        );

        collection(args.collectionId).transferFrom(
            address(this),
            msg.sender,
            args.volume
        );

        s.collection.orders[args.collectionId][
            s.collection.ordersTotal[args.collectionId]++
        ] = CollectionOrder({
            isBuy: true,
            collectionId: args.collectionId,
            liquidityTaker: msg.sender,
            volume: args.volume,
            orderValue: data.orderValue,
            timestamp: block.timestamp
        });
    }

    function sellMarketTargetVolume(
        ICollectionFactory.CollectionMarketOrderTargetVolumeArgs memory args
    ) external payable {
        ICollectionFactory.CollectionSellMarketTargetVolumeData memory data;
        data.remainVolume = args.volume;
        data.orderValue;
        data.totalOrderValue = 0;

        collection(args.collectionId).transferFrom(
            msg.sender,
            address(this),
            args.volume
        );

        uint8 posIndex = s.collection.bidsPriceLastPosIndex[args.collectionId];

        while (
            posIndex >=
            s.collection.bidsPriceFirstPosIndex[args.collectionId] &&
            data.remainVolume > 0
        ) {
            data.priceSlot = s.collection.bidsPrice[args.collectionId][
                posIndex
            ];
            if (data.priceSlot == 0) continue;

            uint8 bitIndex = LibUtils.maxBitIndex(data.priceSlot);
            while (data.remainVolume > 0 && bitIndex >= 0) {
                if (
                    LibUtils.findValueKthBit(data.priceSlot, bitIndex + 1) == 1
                ) {
                    for (
                        uint256 orderbookInfoIndexByPriceSlot = s
                            .collection
                            .bidsInfoIndexStart[args.collectionId][posIndex][
                                bitIndex
                            ];
                        orderbookInfoIndexByPriceSlot <
                        s.collection.bidsInfoIndexTotal[args.collectionId][
                            posIndex
                        ][bitIndex] &&
                            data.remainVolume > 0;
                        orderbookInfoIndexByPriceSlot++
                    ) {
                        uint256 orderbookInfoIndex = s.collection.bidsInfoIndex[
                            args.collectionId
                        ][posIndex][bitIndex][orderbookInfoIndexByPriceSlot];

                        if (
                            s.collection.bidsInfo[orderbookInfoIndex].status !=
                            0
                        ) continue;

                        data.volume = LibUtils.min(
                            data.remainVolume,
                            s.collection.bidsInfo[orderbookInfoIndex].volume
                        );
                        s
                            .collection
                            .bidsInfo[orderbookInfoIndex]
                            .filledVolume += data.volume;
                        data.remainVolume -= data.volume;

                        if (
                            s
                                .collection
                                .bidsInfo[orderbookInfoIndex]
                                .filledVolume ==
                            s.collection.bidsInfo[orderbookInfoIndex].volume
                        ) {
                            s
                                .collection
                                .bidsInfo[orderbookInfoIndex]
                                .status = 1;
                            s.collection.bidsInfoIndexStart[args.collectionId][
                                posIndex
                            ][bitIndex] = orderbookInfoIndex + 1;

                            if (
                                orderbookInfoIndex + 1 ==
                                s.collection.bidsInfoIndexTotal[
                                    args.collectionId
                                ][posIndex][bitIndex]
                            ) {
                                s.collection.bidsPriceFirstPosIndex[
                                    args.collectionId
                                ]++;
                            }
                        }

                        data.orderValue = LibCollectionFactory
                            .calculateCurrencyFromPriceSlot(
                                LibUtils.getPriceFromPriceIndex(
                                    posIndex,
                                    bitIndex,
                                    s
                                        .collection
                                        .collections[args.collectionId]
                                        .precision
                                ) * data.volume,
                                currency().decimals(),
                                s
                                    .collection
                                    .collections[args.collectionId]
                                    .decimal
                            );

                        data.totalOrderValue += data.orderValue;

                        collection(args.collectionId).transferFrom(
                            address(this),
                            s.collection.bidsInfo[orderbookInfoIndex].owner,
                            data.volume
                        );

                        currency().transferForm(
                            address(this),
                            LibData.getReferral(
                                s,
                                s.collection.bidsInfo[orderbookInfoIndex].owner
                            ),
                            s
                                .collection
                                .bidsInfo[orderbookInfoIndex]
                                .referralFee
                        );

                        data.platformFeeLM += s
                            .collection
                            .bidsInfo[orderbookInfoIndex]
                            .platformFee;

                        data.collectorFeeLM += s
                            .collection
                            .bidsInfo[orderbookInfoIndex]
                            .collectorFee;

                        data.referralCollectorFeeLM += s
                            .collection
                            .bidsInfo[orderbookInfoIndex]
                            .referralCollectorFee;

                        data.custodianFeeLM += s
                            .collection
                            .bidsInfo[orderbookInfoIndex]
                            .custodianFee;
                    }
                }

                if (bitIndex == 0) break;
                bitIndex--;
            }

            if (posIndex == 0) break;
            posIndex--;
        }

        require(
            data.remainVolume == 0 &&
                (args.slippage == 0 || data.totalOrderValue >= args.slippage)
        );

        transferCurrencyFromContract(
            LibCollectionFactory.calculateSellMarketTransferList(
                s,
                data.totalOrderValue,
                s.collection.collections[args.collectionId].collector,
                msg.sender,
                data.platformFeeLM,
                data.collectorFeeLM,
                data.referralCollectorLM
            ),
            5
        );

        s.collection.custodiansPool[args.collectorId] +=
            data.custodianFeeLM +
            (LibData.calculateFeeFromPolicy(
                s,
                data.totalOrderValue,
                "COLLECTION_CUSTODIAN_FEE"
            ) / 2);

        s.collection.orders[args.collectionId][
            s.collection.ordersTotal[args.collectionId]++
        ] = CollectionOrder({
            isBuy: false,
            collectionId: args.collectionId,
            liquidityTaker: msg.sender,
            volume: args.volume,
            orderValue: data.orderValue,
            timestamp: block.timestamp
        });
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
