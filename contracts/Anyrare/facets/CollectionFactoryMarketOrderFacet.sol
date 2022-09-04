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

contract CollectionFactoryMarketOrderFacet {
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
                LibData.isMember(s, msg.sender)
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
            if (data.priceSlot == 0) {
                if (
                    posIndex ==
                    s.collection.offersPriceLastPosIndex[args.collectionId]
                ) {
                    break;
                } else {
                    posIndex++;
                    continue;
                }
            }

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
                            LibCollectionFactory
                                .calculateBuyMarketTransferLMList(
                                    s,
                                    ICollectionFactory
                                        .CollectionBuyMarketTransferLMListArgs({
                                            orderValue: data.orderValue,
                                            collector: s
                                                .collection
                                                .collections[args.collectionId]
                                                .collector,
                                            owner: s
                                                .collection
                                                .offersInfo[orderbookInfoIndex]
                                                .owner,
                                            platformFeeLM: s
                                                .collection
                                                .offersInfo[orderbookInfoIndex]
                                                .platformFee,
                                            referralFeeLM: s
                                                .collection
                                                .offersInfo[orderbookInfoIndex]
                                                .referralFee,
                                            collectorFeeLM: s
                                                .collection
                                                .offersInfo[orderbookInfoIndex]
                                                .collectorFee,
                                            referralCollectorFeeLM: s
                                                .collection
                                                .offersInfo[orderbookInfoIndex]
                                                .referralCollectorFee,
                                            custodianFeeLM: s
                                                .collection
                                                .offersInfo[orderbookInfoIndex]
                                                .custodianFee
                                        })
                                ),
                            1
                        );

                        data.platformFeeLM += s
                            .collection
                            .offersInfo[orderbookInfoIndex]
                            .platformFee;

                        data.collectorFeeLM += s
                            .collection
                            .offersInfo[orderbookInfoIndex]
                            .collectorFee;

                        data.referralCollectorFeeLM += s
                            .collection
                            .offersInfo[orderbookInfoIndex]
                            .referralCollectorFee;

                        data.custodianFeeLM += s
                            .collection
                            .offersInfo[orderbookInfoIndex]
                            .custodianFee;
                    }
                }
                bitIndex++;
            }

            if (posIndex == 255) break;
            posIndex++;
        }

        require(
            data.remainVolume == 0 &&
                (args.slippage == 0 || data.totalOrderValue <= args.slippage)
        );

        currency().transferFrom(
            msg.sender,
            address(this),
            LibCollectionFactory.calculateBuyMarketTransferFeeValue(
                s,
                data.totalOrderValue
            )
        );

        collection(args.collectionId).transferFrom(
            address(this),
            msg.sender,
            args.volume
        );

        transferCurrencyFromContract(
            LibCollectionFactory.calculateBuyMarketTransferFeeList(
                s,
                ICollectionFactory.CollectionBuyMarketTransferFeeListArgs({
                    orderValue: data.totalOrderValue,
                    collector: s
                        .collection
                        .collections[args.collectionId]
                        .collector,
                    buyer: msg.sender,
                    platformFeeLM: data.platformFeeLM,
                    collectorFeeLM: data.collectorFeeLM,
                    referralCollectorFeeLM: data.referralCollectorFeeLM
                })
            ),
            4
        );

        s.collection.custodiansPool[args.collectionId] +=
            data.custodianFeeLM +
            (LibData.calculateFeeFromPolicy(
                s,
                data.totalOrderValue,
                "COLLECTION_CUSTODIAN_FEE"
            ) / 2);

        s.collection.orders[args.collectionId][
            s.collection.ordersTotal[args.collectionId]++
        ] = CollectionOrder({
            isBuy: true,
            collectionId: args.collectionId,
            liquidityTaker: msg.sender,
            volume: args.volume,
            orderValue: data.totalOrderValue,
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

            if (data.priceSlot == 0) {
                if (posIndex == 0) {
                    break;
                } else {
                    posIndex--;
                    continue;
                }
            }

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

                        currency().transferFrom(
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
                ICollectionFactory.CollectionSellMarketTransferFeeListArgs({
                    orderValue: data.totalOrderValue,
                    collector: s
                        .collection
                        .collections[args.collectionId]
                        .collector,
                    seller: msg.sender,
                    platformFeeLM: data.platformFeeLM,
                    collectorFeeLM: data.collectorFeeLM,
                    referralCollectorFeeLM: data.referralCollectorFeeLM
                })
            ),
            5
        );

        s.collection.custodiansPool[args.collectionId] +=
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
