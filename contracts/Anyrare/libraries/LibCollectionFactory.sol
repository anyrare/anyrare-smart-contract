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

    function calculateBuyLimitTransferValue(
        AppStorage storage s,
        uint256 orderValue
    ) public view returns (uint256 fees) {
        uint256 platformFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "BUY_COLLECTION_LIQUIDITY_MAKER_FEE"
        );

        uint256 referralFee = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "BUY_COLLECTION_REFERRAL_LIQUIDITY_MAKER_FEE"
        );

        return orderValue + platformFee + referralFee;
    }

    function calculateBuyMarketTransferValue(
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

    function calculateBuyMarketTransferList(
        AppStorage storage s,
        uint256 orderValue,
        address collector,
        address owner
    ) internal view returns (ICurrency.TransferCurrency[] memory fees) {
        ICurrency.TransferCurrency[]
            memory feeLists = new ICurrency.TransferCurrency[](5);

        uint256 referralFeeLiquidityMaker = LibData.calculateFeeFromPolicy(
            s,
            orderValue,
            "BUY_COLLECTION_REFERRAL_LIQUIDITY_MAKER_FEE"
        );

        feeLists[0] = ICurrency.TransferCurrency({
            receiver: owner,
            amount: orderValue -
                LibData.calculateFeeFromPolicy(
                    s,
                    orderValue,
                    "BUY_COLLECTION_LIQUIDITY_MAKER_FEE"
                ) -
                referralFeeLiquidityMaker
        });

        feeLists[1] = ICurrency.TransferCurrency({
            receiver: LibData.getReferral(s, owner),
            amount: referralFeeLiquidityMaker
        });

        feeLists[2] = ICurrency.TransferCurrency({
            receiver: address(this),
            amount: LibData.calculateFeeFromPolicy(
                s,
                orderValue,
                "BUY_COLLECTION_LIQUIDITY_TAKER_FEE"
            ) +
                LibData.calculateFeeFromPolicy(
                    s,
                    orderValue,
                    "BUY_COLLECTION_LIQUIDITY_MAKER_FEE"
                )
        });

        feeLists[3] = ICurrency.TransferCurrency({
            receiver: collector,
            amount: LibData.calculateFeeFromPolicy(
                s,
                orderValue,
                "BUY_COLLECTION_COLLECTOR_FEE"
            )
        });

        feeLists[4] = ICurrency.TransferCurrency({
            receiver: LibData.getReferral(s, collector),
            amount: LibData.calculateFeeFromPolicy(
                s,
                orderValue,
                "BUY_COLLECTION_REFERRAL_COLLECTOR_FEE"
            )
        });

        return feeLists;
    }
}
