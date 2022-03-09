// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {LibUtils} from "../../shared/libraries/LibUtils.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IAssetFactory} from "../interfaces/IAssetFactory.sol";
import {IARA} from "../interfaces/IARA.sol";
import {IAsset} from "../../Asset/interfaces/IAsset.sol";
import {AssetFacet} from "../../Asset/facets/AssetFacet.sol";
import {AssetInfo, AssetAuction} from "../../Asset/libraries/LibAppStorage.sol";
import "../libraries/LibData.sol";
import "hardhat/console.sol";

library LibAssetFactory {
    function calculatePayFeeAndClaimTokenFeeLists(
        AppStorage storage s,
        AssetInfo memory info
    ) public view returns (IARA.TransferARA[] memory fees) {
        uint256 referralAuditorFee = LibData.calculateFeeFromPolicy(
            s,
            info.auditFee,
            "MINT_NFT_REFERRAL_AUDITOR_FEE"
        );

        uint256 platformAuditorFee = LibData.calculateFeeFromPolicy(
            s,
            info.auditFee,
            "MINT_NFT_PLATFORM_AUDITOR_FEE"
        );
        uint256 auditorFee = info.auditFee -
            referralAuditorFee -
            platformAuditorFee;
        uint256 platformFee = info.mintFee + platformAuditorFee;

        IARA.TransferARA[] memory feeLists = new IARA.TransferARA[](3);
        feeLists[0] = IARA.TransferARA({
            receiver: info.auditor,
            amount: auditorFee
        });
        feeLists[1] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.auditor),
            amount: referralAuditorFee
        });
        feeLists[2] = IARA.TransferARA({
            receiver: address(this),
            amount: platformFee
        });

        return feeLists;
    }

    function calculateAuctionTransferFeeLists(
        AppStorage storage s,
        AssetInfo memory info,
        AssetAuction memory auction
    ) public view returns (IARA.TransferARA[] memory fees) {
        IAssetFactory.AssetAuctionTransferFee memory f = IAssetFactory
            .AssetAuctionTransferFee({
                _founderFee: (auction.value * info.founderWeight) /
                    info.maxWeight,
                founderFee: 0,
                referralFounderFee: 0,
                platformFounderFee: 0,
                _custodianFee: (auction.value * info.custodianWeight) /
                    info.maxWeight,
                custodianFee: 0,
                referralCustodianFee: 0,
                platformCustodianFee: 0,
                sellerFee: 0,
                referralSellerFee: LibData.calculateFeeFromPolicy(
                    s,
                    auction.value,
                    "CLOSE_AUCTION_NFT_REFERRAL_SELLER_FEE"
                ),
                referralBuyerFee: LibData.calculateFeeFromPolicy(
                    s,
                    auction.value,
                    "CLOSE_AUCTION_NFT_REFERRAL_BUYER_FEE"
                ),
                platformFee: 0
            });

        f.referralFounderFee = LibData.calculateFeeFromPolicy(
            s,
            f._founderFee,
            "CLOSE_AUCTION_NFT_REFERRAL_FOUNDER_FEE"
        );
        f.platformFounderFee = LibData.calculateFeeFromPolicy(
            s,
            f._founderFee,
            "CLOSE_AUCTION_NFT_PLATFORM_FOUNDER_FEE"
        );
        f.founderFee =
            f._founderFee -
            f.referralFounderFee -
            f.platformFounderFee;
        f.referralCustodianFee = LibData.calculateFeeFromPolicy(
            s,
            f._custodianFee,
            "CLOSE_AUCTION_NFT_REFERRAL_CUSTODIAN_FEE"
        );
        f.platformCustodianFee = LibData.calculateFeeFromPolicy(
            s,
            f._custodianFee,
            "CLOSE_AUCTION_NFT_PLATFORM_CUSTODIAN_FEE"
        );
        f.custodianFee =
            f._custodianFee -
            f.referralCustodianFee -
            f.platformCustodianFee;
        f.platformFee =
            LibData.calculateFeeFromPolicy(
                s,
                auction.value,
                "CLOSE_AUCTION_NFT_PLATFORM_FEE"
            ) +
            f.platformFounderFee +
            f.platformCustodianFee;
        f.sellerFee =
            auction.value -
            f.founderFee -
            f.referralFounderFee -
            f.custodianFee -
            f.referralCustodianFee -
            f.platformFee -
            f.referralBuyerFee -
            f.referralSellerFee;

        IARA.TransferARA[] memory feeLists = new IARA.TransferARA[](9);
        feeLists[0] = IARA.TransferARA({
            receiver: auction.owner,
            amount: f.sellerFee
        });
        feeLists[1] = IARA.TransferARA({
            receiver: info.founder,
            amount: f.founderFee
        });
        feeLists[2] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.founder),
            amount: f.referralFounderFee
        });
        feeLists[3] = IARA.TransferARA({
            receiver: info.custodian,
            amount: f.custodianFee
        });
        feeLists[4] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.custodian),
            amount: f.referralCustodianFee
        });
        feeLists[5] = IARA.TransferARA({
            receiver: address(this),
            amount: f.platformFee
        });
        feeLists[6] = IARA.TransferARA({
            receiver: LibData.getReferral(s, auction.bidder),
            amount: f.referralBuyerFee
        });
        feeLists[7] = IARA.TransferARA({
            receiver: LibData.getReferral(s, auction.owner),
            amount: f.referralSellerFee
        });
        feeLists[8] = IARA.TransferARA({
            receiver: auction.bidder,
            amount: auction.maxBid - auction.value
        });

        return feeLists;
    }

    function calculateOfferTransferFeeLists(
        AppStorage storage s,
        AssetInfo memory info
    ) public view returns (IARA.TransferARA[] memory fees) {
        IAssetFactory.AssetOfferTransferFee memory f = IAssetFactory
            .AssetOfferTransferFee({
                _founderFee: (info.offerValue * info.founderWeight) /
                    info.maxWeight,
                founderFee: 0,
                referralFounderFee: 0,
                platformFounderFee: 0,
                _custodianFee: (info.offerValue * info.custodianWeight) /
                    info.maxWeight,
                custodianFee: 0,
                referralCustodianFee: 0,
                platformCustodianFee: 0,
                sellerFee: 0,
                referralSellerFee: LibData.calculateFeeFromPolicy(
                    s,
                    info.offerValue,
                    "OFFER_NFT_REFERRAL_SELLER_FEE"
                ),
                referralBuyerFee: LibData.calculateFeeFromPolicy(
                    s,
                    info.offerValue,
                    "OFFER_NFT_REFERRAL_BUYER_FEE"
                ),
                platformFee: 0
            });

        f.referralFounderFee = LibData.calculateFeeFromPolicy(
            s,
            f._founderFee,
            "OFFER_NFT_REFERRAL_FOUNDER_FEE"
        );
        f.platformFounderFee = LibData.calculateFeeFromPolicy(
            s,
            f._founderFee,
            "OFFER_NFT_PLATFORM_FOUNDER_FEE"
        );
        f.founderFee =
            f._founderFee -
            f.referralFounderFee -
            f.platformFounderFee;
        f.referralCustodianFee = LibData.calculateFeeFromPolicy(
            s,
            f._custodianFee,
            "OFFER_NFT_REFERRAL_CUSTODIAN_FEE"
        );
        f.platformCustodianFee = LibData.calculateFeeFromPolicy(
            s,
            f._custodianFee,
            "OFFER_NFT_PLATFORM_CUSTODIAN_FEE"
        );
        f.custodianFee =
            f._custodianFee -
            f.referralCustodianFee -
            f.platformCustodianFee;
        f.platformFee =
            LibData.calculateFeeFromPolicy(
                s,
                info.offerValue,
                "OFFER_NFT_PLATFORM_FEE"
            ) +
            f.platformFounderFee +
            f.platformCustodianFee;
        f.sellerFee =
            info.offerValue -
            f.founderFee -
            f.referralFounderFee -
            f.custodianFee -
            f.referralCustodianFee -
            f.platformFee -
            f.referralBuyerFee -
            f.referralSellerFee;

        IARA.TransferARA[] memory feeLists = new IARA.TransferARA[](8);

        feeLists[0] = IARA.TransferARA({
            receiver: info.owner,
            amount: f.sellerFee
        });
        feeLists[1] = IARA.TransferARA({
            receiver: info.founder,
            amount: f.founderFee
        });
        feeLists[2] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.founder),
            amount: f.referralFounderFee
        });
        feeLists[3] = IARA.TransferARA({
            receiver: info.custodian,
            amount: f.custodianFee
        });
        feeLists[4] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.custodian),
            amount: f.referralCustodianFee
        });
        feeLists[5] = IARA.TransferARA({
            receiver: address(this),
            amount: f.platformFee
        });
        feeLists[6] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.offerBidder),
            amount: f.referralBuyerFee
        });
        feeLists[7] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.offerOwner),
            amount: f.referralSellerFee
        });

        return feeLists;
    }

    function calculateBuyItNowTransferFeeLists(
        AppStorage storage s,
        AssetInfo memory info,
        address buyer
    ) public view returns (IARA.TransferARA[] memory fees) {
        IAssetFactory.AssetBuyItNowTransferFee memory f = IAssetFactory
            .AssetBuyItNowTransferFee({
                _founderFee: (info.buyItNowValue * info.founderWeight) /
                    info.maxWeight,
                founderFee: 0,
                referralFounderFee: 0,
                platformFounderFee: 0,
                _custodianFee: (info.buyItNowValue * info.custodianWeight) /
                    info.maxWeight,
                custodianFee: 0,
                referralCustodianFee: 0,
                platformCustodianFee: 0,
                sellerFee: 0,
                referralSellerFee: LibData.calculateFeeFromPolicy(
                    s,
                    info.buyItNowValue,
                    "BUY_IT_NOW_NFT_REFERRAL_SELLER_FEE"
                ),
                referralBuyerFee: LibData.calculateFeeFromPolicy(
                    s,
                    info.buyItNowValue,
                    "BUY_IT_NOW_NFT_REFERRAL_BUYER_FEE"
                ),
                platformFee: 0
            });

        f.referralFounderFee = LibData.calculateFeeFromPolicy(
            s,
            f._founderFee,
            "BUY_IT_NOW_NFT_REFERRAL_FOUNDER_FEE"
        );
        f.platformFounderFee = LibData.calculateFeeFromPolicy(
            s,
            f._founderFee,
            "BUY_IT_NOW_NFT_PLATFORM_FOUNDER_FEE"
        );
        f.founderFee =
            f._founderFee -
            f.referralFounderFee -
            f.platformFounderFee;
        f.referralCustodianFee = LibData.calculateFeeFromPolicy(
            s,
            f._custodianFee,
            "BUY_IT_NOW_NFT_REFERRAL_CUSTODIAN_FEE"
        );
        f.platformCustodianFee = LibData.calculateFeeFromPolicy(
            s,
            f._custodianFee,
            "BUY_IT_NOW_NFT_PLATFORM_CUSTODIAN_FEE"
        );
        f.custodianFee =
            f._custodianFee -
            f.referralCustodianFee -
            f.platformCustodianFee;
        f.platformFee =
            LibData.calculateFeeFromPolicy(
                s,
                info.buyItNowValue,
                "BUY_IT_NOW_NFT_PLATFORM_FEE"
            ) +
            f.platformFounderFee +
            f.platformCustodianFee;
        f.sellerFee =
            info.buyItNowValue -
            f.founderFee -
            f.referralFounderFee -
            f.custodianFee -
            f.referralCustodianFee -
            f.platformFee -
            f.referralBuyerFee -
            f.referralSellerFee;

        IARA.TransferARA[] memory feeLists = new IARA.TransferARA[](8);

        feeLists[0] = IARA.TransferARA({
            receiver: info.buyItNowOwner,
            amount: f.sellerFee
        });
        feeLists[1] = IARA.TransferARA({
            receiver: info.founder,
            amount: f.founderFee
        });
        feeLists[2] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.founder),
            amount: f.referralFounderFee
        });
        feeLists[3] = IARA.TransferARA({
            receiver: info.custodian,
            amount: f.custodianFee
        });
        feeLists[4] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.custodian),
            amount: f.referralCustodianFee
        });
        feeLists[5] = IARA.TransferARA({
            receiver: address(this),
            amount: f.platformFee
        });
        feeLists[6] = IARA.TransferARA({
            receiver: LibData.getReferral(s, buyer),
            amount: f.referralBuyerFee
        });
        feeLists[7] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.buyItNowOwner),
            amount: f.referralSellerFee
        });

        return feeLists;
    }

    function calculateRedeemFeeStruct(
        AppStorage storage s,
        AssetInfo memory info,
        uint256 auctionValue
    ) public view returns (IAssetFactory.AssetRedeemFee memory fees) {
        IAssetFactory.AssetRedeemFee memory f = IAssetFactory.AssetRedeemFee({
            value: LibUtils.max(
                auctionValue,
                LibUtils.max(info.buyItNowValue, info.offerValue)
            ),
            _founderFee: 0,
            founderFee: 0,
            referralFounderFee: 0,
            platformFounderFee: 0,
            _custodianFee: 0,
            custodianFee: 0,
            referralCustodianFee: 0,
            platformCustodianFee: 0,
            referralOwnerFee: 0,
            platformFee: 0
        });

        f._founderFee = LibUtils.max(
            info.founderGeneralFee,
            (f.value * info.founderRedeemWeight) / info.maxWeight
        );
        f.referralFounderFee = LibData.calculateFeeFromPolicy(
            s,
            f._founderFee,
            "REDEEM_NFT_REFERRAL_FOUNDER_FEE"
        );
        f.platformFounderFee = LibData.calculateFeeFromPolicy(
            s,
            f._founderFee,
            "REDEEM_NFT_PLATFORM_FOUNDER_FEE"
        );
        f.founderFee =
            f._founderFee -
            f.referralFounderFee -
            f.platformFounderFee;

        f._custodianFee = LibUtils.max(
            info.custodianGeneralFee,
            (f.value * info.custodianRedeemWeight) / info.maxWeight
        );
        f.referralCustodianFee = LibData.calculateFeeFromPolicy(
            s,
            f._custodianFee,
            "REDEEM_NFT_REFERRAL_CUSTODIAN_FEE"
        );
        f.platformCustodianFee = LibData.calculateFeeFromPolicy(
            s,
            f._custodianFee,
            "REDEEM_NFT_PLATFORM_CUSTODIAN_FEE"
        );
        f.custodianFee =
            f._custodianFee -
            f.referralCustodianFee -
            f.platformCustodianFee;

        f.platformFee =
            LibUtils.max(
                LibData.getPolicy(s, "REDEEM_NFT_PLATFORM_FEE").policyValue,
                LibData.calculateFeeFromPolicy(
                    s,
                    f.value,
                    "REDEEM_NFT_PLATFORM_FEE"
                )
            ) +
            f.platformFounderFee +
            f.platformCustodianFee;

        f.referralOwnerFee = LibUtils.max(
            LibData.getPolicy(s, "REDEEM_NFT_REFERRAL_OWNER_FEE").policyValue,
            LibData.calculateFeeFromPolicy(
                s,
                f.value,
                "REDEEM_NFT_REFERRAL_OWNER_FEE"
            )
        );

        return f;
    }

    function calculateRedeemFee(
        AppStorage storage s,
        AssetInfo memory info,
        uint256 auctionValue
    ) public view returns (uint256) {
        IAssetFactory.AssetRedeemFee memory f = calculateRedeemFeeStruct(
            s,
            info,
            auctionValue
        );

        return
            f.founderFee +
            f.referralFounderFee +
            f.custodianFee +
            f.referralCustodianFee +
            f.platformFee +
            f.referralOwnerFee;
    }

    function calculateRedeemFeeLists(
        AppStorage storage s,
        AssetInfo memory info,
        uint256 auctionValue
    ) public view returns (IARA.TransferARA[] memory f) {
        IAssetFactory.AssetRedeemFee memory f = calculateRedeemFeeStruct(
            s,
            info,
            auctionValue
        );

        IARA.TransferARA[] memory feeLists = new IARA.TransferARA[](6);
        feeLists[0] = IARA.TransferARA({
            receiver: info.founder,
            amount: f.founderFee
        });
        feeLists[1] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.founder),
            amount: f.referralFounderFee
        });
        feeLists[2] = IARA.TransferARA({
            receiver: info.custodian,
            amount: f.custodianFee
        });
        feeLists[3] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.custodian),
            amount: f.referralCustodianFee
        });
        feeLists[4] = IARA.TransferARA({
            receiver: address(this),
            amount: f.platformFee
        });
        feeLists[5] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.owner),
            amount: f.referralOwnerFee
        });

        return feeLists;
    }

    function calculateTransferFeeStruct(
        AppStorage storage s,
        AssetInfo memory info,
        uint256 auctionValue
    ) public view returns (IAssetFactory.AssetTransferFee memory fees) {
        IAssetFactory.AssetTransferFee memory f = IAssetFactory
            .AssetTransferFee({
                value: LibUtils.max(
                    auctionValue,
                    LibUtils.max(info.buyItNowValue, info.offerValue)
                ),
                _founderFee: 0,
                founderFee: 0,
                referralFounderFee: 0,
                platformFounderFee: 0,
                _custodianFee: 0,
                custodianFee: 0,
                referralCustodianFee: 0,
                platformCustodianFee: 0,
                referralSenderFee: 0,
                referralReceiverFee: 0,
                platformFee: 0
            });

        f._founderFee = LibUtils.max(
            info.founderGeneralFee,
            (f.value * info.founderWeight) / info.maxWeight
        );
        f.referralFounderFee = LibData.calculateFeeFromPolicy(
            s,
            f._founderFee,
            "TRANSFER_NFT_REFERRAL_FOUNDER_FEE"
        );
        f.platformFounderFee = LibData.calculateFeeFromPolicy(
            s,
            f._founderFee,
            "TRANSFER_NFT_PLATFORM_FOUNDER_FEE"
        );
        f.founderFee =
            f._founderFee -
            f.referralFounderFee -
            f.platformFounderFee;

        f._custodianFee = LibUtils.max(
            info.custodianGeneralFee,
            (f.value * info.custodianRedeemWeight) / info.maxWeight
        );
        f.referralCustodianFee = LibData.calculateFeeFromPolicy(
            s,
            f._custodianFee,
            "TRANSFER_NFT_REFERRAL_CUSTODIAN_FEE"
        );
        f.platformCustodianFee = LibData.calculateFeeFromPolicy(
            s,
            f._custodianFee,
            "TRANSFER_NFT_PLATFORM_CUSTODIAN_FEE"
        );
        f.custodianFee =
            f._custodianFee -
            f.referralCustodianFee -
            f.platformCustodianFee;

        f.platformFee =
            LibUtils.max(
                LibData.getPolicy(s, "TRANSFER_NFT_PLATFORM_FEE").policyValue,
                LibData.calculateFeeFromPolicy(
                    s,
                    f.value,
                    "TRANSFER_NFT_PLATFORM_FEE"
                )
            ) +
            f.platformFounderFee +
            f.platformCustodianFee;

        f.referralSenderFee = LibData.calculateFeeFromPolicy(
            s,
            f.value,
            "TRANSFER_NFT_REFERRAL_SENDER_FEE"
        );

        f.referralReceiverFee = LibData.calculateFeeFromPolicy(
            s,
            f.value,
            "TRANSFER_NFT_REFERRAL_RECEIVER_FEE"
        );

        return f;
    }

    function calculateTransferFee(
        AppStorage storage s,
        AssetInfo memory info,
        uint256 auctionValue
    ) public view returns (uint256) {
        IAssetFactory.AssetTransferFee memory f = calculateTransferFeeStruct(
            s,
            info,
            auctionValue
        );

        return
            f.founderFee +
            f.referralFounderFee +
            f.custodianFee +
            f.referralCustodianFee +
            f.platformFee +
            f.referralSenderFee +
            f.referralReceiverFee;
    }

    function calculateTransferFeeLists(
        AppStorage storage s,
        AssetInfo memory info,
        uint256 auctionValue,
        address sender,
        address receiver
    ) public view returns (IARA.TransferARA[] memory f) {
        IAssetFactory.AssetTransferFee memory f = calculateTransferFeeStruct(
            s,
            info,
            auctionValue
        );

        IARA.TransferARA[] memory feeLists = new IARA.TransferARA[](7);
        feeLists[0] = IARA.TransferARA({
            receiver: info.founder,
            amount: f.founderFee
        });
        feeLists[1] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.founder),
            amount: f.referralFounderFee
        });
        feeLists[2] = IARA.TransferARA({
            receiver: info.custodian,
            amount: f.custodianFee
        });
        feeLists[3] = IARA.TransferARA({
            receiver: LibData.getReferral(s, info.custodian),
            amount: f.referralCustodianFee
        });
        feeLists[4] = IARA.TransferARA({
            receiver: address(this),
            amount: f.platformFee
        });
        feeLists[5] = IARA.TransferARA({
            receiver: LibData.getReferral(s, sender),
            amount: f.referralSenderFee
        });
        feeLists[6] = IARA.TransferARA({
            receiver: LibData.getReferral(s, receiver),
            amount: f.referralReceiverFee
        });

        return feeLists;
    }
}
