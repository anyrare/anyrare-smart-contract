// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {LibUtils} from "../../shared/libraries/LibUtils.sol";
import {AppStorage, CollectionInfo} from "../libraries/LibAppStorage.sol";
import {ICurrency} from "../interfaces/ICurrency.sol";
import {ICollectionFactory} from "../interfaces/ICollectionFactory.sol";
import "../libraries/LibData.sol";
import "hardhat/console.sol";

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

    function calculateBuyMarketTransferValue(
        AppStorage storage s,
        uint256 orderValue
    ) public view returns (uint256 fees) {
        uint256 platformFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_PLATFORM_FEE"
        );
        uint256 collectorFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_COLLECTOR_FEE"
        );
        uint256 referralCollectorFee = LibData.calculateFeeFromPolicy(
            s,
            collectorFee,
            "COLLECTION_REFERRAL_COLLECTOR_FEE"
        );
        uint256 custodianFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_CUSTODIAN_FEE"
        );

        return
            orderValue +
            platformFee +
            collectorFee +
            referralCollectorFee +
            custodianFee;
    }

    function calculateCurrencyFromPriceSlot(
        uint256 priceValue,
        uint8 currencyDecimal,
        uint8 collectionDecimal
    ) public view returns (uint256) {
        return priceValue * (10**(currencyDecimal - collectionDecimal));
    }

    function calculateBuyMarketTransferLMList(
        AppStorage storage s,
        ICollectionFactory.CollectionBuyMarketTransferLMListArgs memory args
    ) internal view returns (ICurrency.TransferCurrency[] memory fees) {
        ICurrency.TransferCurrency[]
            memory feeLists = new ICurrency.TransferCurrency[](2);

        feeLists[0] = ICurrency.TransferCurrency({
            receiver: args.owner,
            amount: args.orderValue -
                args.platformFeeLM -
                args.referralFeeLM -
                args.collectorFeeLM -
                args.referralFeeLM -
                args.custodianFeeLM
        });

        feeLists[1] = ICurrency.TransferCurrency({
            receiver: LibData.getReferral(s, args.owner),
            amount: args.referralFeeLM
        });

        return feeLists;
    }

    function calculateBuyMarketTransferFeeValue(
        AppStorage storage s,
        uint256 orderValue
    ) internal view returns (uint256) {
        uint256 platformFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_LIQUIDITY_TAKER_FEE"
        );

        uint256 referralFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_REFERRAL_LIQUIDITY_TAKER_FEE"
        );

        uint256 collectorFee = (LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_COLLECTOR_FEE"
        ) / 2);

        uint256 referralCollectorFee = (LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_REFERRAL_COLLECTOR_FEE"
        ) / 2);

        uint256 custodianFee = (LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "COLLECTION_REFERRAL_COLLECTOR_FEE"
        ) / 2);

        return
            platformFee +
            referralFee +
            collectorFee +
            referralCollectorFee +
            custodianFee;
    }

    function calculateBuyMarketTransferFeeList(
        AppStorage storage s,
        ICollectionFactory.CollectionBuyMarketTransferFeeListArgs memory args
    ) internal view returns (ICurrency.TransferCurrency[] memory fees) {
        ICurrency.TransferCurrency[]
            memory feeLists = new ICurrency.TransferCurrency[](4);

        uint256 platformFee = LibData.calculateFeeFromPolicy(
            s,
            args.orderValue,
            "COLLECTION_LIQUIDITY_TAKER_FEE"
        ) + args.platformFeeLM;

        uint256 referralFee = LibData.calculateFeeFromPolicy(
            s,
            args.orderValue,
            "COLLECTION_REFERRAL_LIQUIDITY_TAKER_FEE"
        );

        uint256 collectorFee = (LibData.calculateFeeFromPolicy(
            s,
            args.orderValue,
            "COLLECTION_COLLECTOR_FEE"
        ) / 2) + args.collectorFeeLM;

        uint256 referralCollectorFee = (LibData.calculateFeeFromPolicy(
            s,
            args.orderValue,
            "COLLECTION_REFERRAL_COLLECTOR_FEE"
        ) / 2) + args.referralCollectorFeeLM;

        feeLists[0] = ICurrency.TransferCurrency({
            receiver: address(this),
            amount: platformFee
        });

        feeLists[1] = ICurrency.TransferCurrency({
            receiver: args.collector,
            amount: collectorFee
        });

        feeLists[2] = ICurrency.TransferCurrency({
            receiver: LibData.getReferral(s, args.buyer),
            amount: referralFee
        });

        feeLists[3] = ICurrency.TransferCurrency({
            receiver: LibData.getReferral(s, args.collector),
            amount: referralCollectorFee
        });

        return feeLists;
    }

    function calculateSellMarketTransferList(
        AppStorage storage s,
        ICollectionFactory.CollectionSellMarketTransferFeeListArgs memory args
    ) internal view returns (ICurrency.TransferCurrency[] memory fees) {
        ICurrency.TransferCurrency[]
            memory feeLists = new ICurrency.TransferCurrency[](5);

        uint256 platformFee = LibData.calculateFeeFromPolicy(
            s,
            args.orderValue,
            "COLLECTION_LIQUIDITY_TAKER_FEE"
        ) + args.platformFeeLM;

        uint256 referralFee = LibData.calculateFeeFromPolicy(
            s,
            args.orderValue,
            "COLLECTION_REFERRAL_LIQUIDITY_TAKER_FEE"
        );

        uint256 collectorFee = (LibData.calculateFeeFromPolicy(
            s,
            args.orderValue,
            "COLLECTION_COLLECTOR_FEE"
        ) / 2) + args.collectorFeeLM;

        uint256 referralCollectorFee = (LibData.calculateFeeFromPolicy(
            s,
            args.orderValue,
            "COLLECTION_REFERRAL_COLLECTOR_FEE"
        ) / 2) + args.referralCollectorFeeLM;

        feeLists[0] = ICurrency.TransferCurrency({
            receiver: args.seller,
            amount: args.orderValue -
                platformFee -
                referralFee -
                collectorFee -
                referralCollectorFee
        });

        feeLists[1] = ICurrency.TransferCurrency({
            receiver: address(this),
            amount: platformFee
        });

        feeLists[2] = ICurrency.TransferCurrency({
            receiver: args.collector,
            amount: collectorFee
        });

        feeLists[3] = ICurrency.TransferCurrency({
            receiver: LibData.getReferral(s, args.seller),
            amount: referralFee
        });

        feeLists[4] = ICurrency.TransferCurrency({
            receiver: LibData.getReferral(s, args.collector),
            amount: referralCollectorFee
        });

        return feeLists;
    }
}
