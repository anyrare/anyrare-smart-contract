// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {CollectionERC20} from "./CollectionERC20.sol";
import {AppStorage, CollectionInfo, CollectionOrderbookInfo} from "../libraries/LibAppStorage.sol";
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

    function currency() private view returns (IERC20) {
        require(
            s.contractAddress.currency != address(0),
            "CollectionFactoryFacet: currency address cannot be 0"
        );
        return IERC20(s.contractAddress.currency);
    }

    function asset() private view returns (AssetFacet) {
        require(
            s.contractAddress.assetDiamond != address(0),
            "CollectionFactoryFacet: assetDiamond address cannot be 0"
        );
        return AssetFacet(s.contractAddress.assetDiamond);
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

        require(
            LibData.isMember(s, msg.sender) &&
                currency().balanceOf(msg.sender) >= orderValue
        );

        currency().transferFrom(
            msg.sender,
            address(this),
            LibCollectionFactory.calculateBuyLimitTransferValue(s, orderValue)
        );

        CollectionInfo memory collection = s.collection.collections[
            args.collectionId
        ];
        uint256 priceIndex = LibUtils.calculatePriceIndex(
            args.price,
            collection.precision
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
            collectionAddr: args.collectionAddr,
            collectionId: args.collectionId,
            owner: msg.sender,
            price: args.price,
            volume: args.volume,
            filledVolume: 0,
            timestamp: block.timestamp,
            status: 0
        });
        s.collection.bidsInfoIndex[args.collectionId][posIndex][bitIndex][
            s.collection.bidsInfoIndexTotal[args.collectionId][posIndex][
                bitIndex
            ]++
        ] = s.collection.totalBidInfo;

        if (posIndex < s.collection.bidsPriceFirstPosIndex[args.collectionId]) {
            s.collection.bidsPriceFirstPosIndex[args.collectionId] = posIndex;
        }
        s.collection.totalBidInfo++;
    }

    function buyMarketByVolume(
        ICollectionFactory.CollectionMarketOrderByVolumeArgs memory args
    ) external payable {
        ICollectionFactory.CollectionBuyMarketVolumeData memory data;
        data.remainVolume = args.volume;
        data.orderValue;
        data.totalOrderValue = 0;

        for (
            uint8 posIndex = s.collection.bidsPriceFirstPosIndex[
                args.collectionId
            ];
            posIndex < 255 && data.remainVolume > 0;
            posIndex++
        ) {
            data.priceSlot = s.collection.bidsPrice[args.collectionId][
                posIndex
            ];
            if (data.priceSlot == 0) continue;

            uint8 bitIndex = 0;
            while (data.remainVolume > 0 && bitIndex < 255) {
                if (
                    LibUtils.findValueKthBit(data.priceSlot, bitIndex + 1) == 1
                ) {
                    for (
                        uint256 orderbookInfoIndex = s
                            .collection
                            .bidsInfoIndexStart[args.collectionId][posIndex][
                                bitIndex
                            ];
                        orderbookInfoIndex <
                        s.collection.bidsInfoIndexTotal[args.collectionId][
                            posIndex
                        ][bitIndex] &&
                            data.remainVolume > 0;
                        orderbookInfoIndex++
                    ) {
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
                        
                        uint256 orderId = s.collection.bidsInfoIndex[
                            args.collectionId
                        ][posIndex][bitIndex][orderbookInfoIndex]++;
                        
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
                                s.collection.bidsInfo[orderbookInfoIndex].owner
                            ),
                            1
                        );
                    }
                }
                bitIndex++;
            }
        }

        // require(data.remainVolume == 0);
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
