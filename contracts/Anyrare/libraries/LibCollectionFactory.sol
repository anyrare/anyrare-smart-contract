// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {LibUtils} from "../../shared/libraries/LibUtils.sol";
import {AppStorage, CollectionInfo} from "../libraries/LibAppStorage.sol";
import {ICurrency} from "../interfaces/ICurrency.sol";
import {ICollectionFactory} from "../interfaces/ICollectionFactory.sol";
import "../libraries/LibData.sol";

library LibCollectionFactory {
    function calculateMintCollectionFeeLists(
        AppStorage storage s,
        address collector
    ) public view returns (ICurrency.TransferCurrency[] memory fees) {
        uint256 referralCollectorFee = LibData
            .getPolicy(s, "MINT_COLLECTION_REFERRAL_COLLECTOR_FEE")
            .policyValue;
        uint256 platformFee = LibData
            .getPolicy(s, "MINT_COLLECTION_FEE")
            .policyValue;

        ICurrency.TransferCurrency[]
            memory feeLists = new ICurrency.TransferCurrency[](2);
        feeLists[0] = ICurrency.TransferCurrency({
            receiver: address(this),
            amount: platformFee
        });
        feeLists[1] = ICurrency.TransferCurrency({
            receiver: LibData.getReferral(s, collector),
            amount: referralCollectorFee
        });

        return feeLists;
    }

    function calculateBuyMarketTransferFee(
        AppStorage storage s,
        uint256 orderValue
    ) public view returns (uint256 fees) {
        uint256 platformFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "BUY_COLLECTION_PLATFORM_FEE"
        );
        uint256 collectorFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "BUY_COLLECTION_COLLECTOR_FEE"
        );
        uint256 referralCollectorFee = LibData.calculateFeeFromPolicy(
            s,
            collectorFee,
            "BUY_COLLECTION_REFERRAL_COLLECTOR_FEE"
        );
        uint256 custodianFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "BUY_COLLECTION_CUSTODIAN_FEE"
        );

        return platformFee + collectorFee + referralCollectorFee + custodianFee;
    }

    function calculateCurrencyFromPriceSlot(
        uint256 priceValue,
        uint8 currencyDecimal,
        uint8 collectionDecimal
    ) public view returns (uint256) {
        return priceValue * (10**(currencyDecimal - collectionDecimal));
    }

    function calculateBuyMarketTransferList(
        AppStorage storage s,
        ICollectionFactory.CollectionCalculateBuyMarketTransferListArgs
            memory args
    ) internal view returns (ICurrency.TransferCurrency[] memory fees) {
        ICurrency.TransferCurrency[]
            memory feeLists = new ICurrency.TransferCurrency[](
                args.totalPriceInfo + 5
            );

        uint256 feeIndex = 0;
        for (uint256 i = 0; i < args.totalPriceInfo; i++) {
            {
                uint256 value = calculateCurrencyFromPriceSlot(
                    args.priceInfos[i].price * args.priceInfos[i].volume,
                    args.currencyDecimal,
                    s.collection.collections[args.collectionId].decimal
                );

                uint256 referralFeeLiquidityMaker = LibData
                    .calculateFeeFromPolicy(
                        s,
                        value,
                        "BUY_COLLECTION_REFERRAL_LIQUIDITY_MAKER_FEE"
                    );

                feeLists[feeIndex++] = ICurrency.TransferCurrency({
                    receiver: args.priceInfos[i].owner,
                    amount: value -
                        LibData.calculateFeeFromPolicy(
                            s,
                            value,
                            "BUY_COLLECTION_PLATFORM_LIQUIDITY_MAKER_FEE"
                        ) -
                        referralFeeLiquidityMaker
                });

                feeLists[feeIndex++] = ICurrency.TransferCurrency({
                    receiver: LibData.getReferral(s, args.priceInfos[i].owner),
                    amount: referralFeeLiquidityMaker
                });
            }
        }

        feeLists[feeIndex++] = ICurrency.TransferCurrency({
            receiver: address(this),
            amount: LibData.calculateFeeFromPolicy(
                s,
                args.orderValue,
                "BUY_COLLECTION_PLATFORM_LIQUIDITY_TAKER_FEE"
            ) +
                LibData.calculateFeeFromPolicy(
                    s,
                    args.orderValue,
                    "BUY_COLLECTION_PLATFORM_LIQUIDITY_MAKER_FEE"
                )
        });

        feeLists[feeIndex++] = ICurrency.TransferCurrency({
            receiver: s.collection.collections[args.collectionId].collector,
            amount: LibData.calculateFeeFromPolicy(
                s,
                args.orderValue,
                "BUY_COLLECTION_COLLECTOR_FEE"
            )
        });

        feeLists[feeIndex++] = ICurrency.TransferCurrency({
            receiver: LibData.getReferral(
                s,
                s.collection.collections[args.collectionId].collector
            ),
            amount: LibData.calculateFeeFromPolicy(
                s,
                args.orderValue,
                "BUY_COLLECTION_REFERRAL_COLLECTOR_FEE"
            )
        });

        return feeLists;
    }
}
