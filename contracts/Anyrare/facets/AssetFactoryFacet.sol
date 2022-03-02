// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibUtils} from "../../shared/libraries/LibUtils.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IAssetFactory} from "../interfaces/IAssetFactory.sol";
import {IAsset} from "../../Asset/interfaces/IAsset.sol";
import {AssetFacet} from "../../Asset/facets/AssetFacet.sol";
import {ARAFacet} from "../../ARA/facets/ARAFacet.sol";
import {AssetInfo, AssetAuction} from "../../Asset/libraries/LibAppStorage.sol";
import "../libraries/LibData.sol";
import "../libraries/LibAssetFactory.sol";
import "hardhat/console.sol";

contract AssetFactoryFacet {
    AppStorage internal s;

    function ara() private view returns (ARAFacet) {
        require(
            s.contractAddress.araToken != address(0),
            "AssetFactoryFacet: araToken address cannot be 0"
        );
        return ARAFacet(s.contractAddress.araToken);
    }

    function asset() private view returns (AssetFacet) {
        require(
            s.contractAddress.assetToken != address(0),
            "AssetFactoryFacet: assetToken address cannot be 0"
        );
        return AssetFacet(s.contractAddress.assetToken);
    }

    function initAssetFactory(address assetToken) public {
        require(
            s.contractAddress.assetToken == address(0),
            "AssetFactoryFacet: already init"
        );
        s.contractAddress.assetToken = assetToken;
    }

    function mintAsset(IAssetFactory.AssetMintArgs memory args)
        external
        payable
    {
        asset().mint(
            IAsset.AssetMintArgs(
                msg.sender,
                args.founder,
                args.custodian,
                args.tokenURI,
                args.maxWeight,
                args.founderWeight,
                args.founderRedeemWeight,
                args.founderGeneralFee,
                args.auditFee,
                args.custodianWeight,
                args.custodianGeneralFee,
                args.custodianRedeemWeight
            )
        );
    }

    function custodianSign(uint256 tokenId) external {
        asset().custodianSign(tokenId, msg.sender);
    }

    function payFeeAndClaimToken(uint256 tokenId) external {
        AssetInfo memory info = asset().tokenInfo(tokenId);
        uint256 referralFounderFee = LibData.calculateFeeFromPolicy(
            s,
            LibData.getPolicy(s, "MINT_NFT_FEE").policyValue,
            "MINT_NFT_REFERRAL_FOUNDER_FEE"
        );
        uint256 platformFee = LibData.getPolicy(s, "MINT_NFT_FEE").policyValue -
            referralFounderFee;
        uint256 auditReferralFee = LibData.calculateFeeFromPolicy(
            s,
            info.auditFee,
            "MINT_NFT_REFERRAL_AUDITOR_FEE"
        );
        uint256 auditFee = info.auditFee - auditReferralFee;
        uint256 fee = platformFee + auditFee + auditReferralFee;

        ara().transferFrom(msg.sender, address(this), fee);

        transferARAFromContract(
            LibAssetFactory.calculatePayFeeAndClaimTokenFeeLists(s, info),
            3
        );

        asset().payFeeAndClaimToken(tokenId, msg.sender);
    }

    function openAuction(
        uint256 tokenId,
        uint256 closeAuctionPeriodSecond,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 maxWeight,
        uint256 nextBidWeight
    ) external {
        AssetInfo memory info = asset().tokenInfo(tokenId);

        require(
            asset().ownerOf(tokenId) == msg.sender &&
                info.isPayFeeAndClaimToken &&
                !info.isAuction &&
                !info.isLockInCollection &&
                !info.isRedeem &&
                !info.isFreeze
        );

        uint256 referralFee = LibData.calculateFeeFromPolicy(
            s,
            LibData.getPolicy(s, "OPEN_AUCTION_NFT_PLATFORM_FEE").policyValue,
            "OPEN_AUCTION_NFT_REFERRAL_FEE"
        );
        uint256 platformFee = LibData
            .getPolicy(s, "OPEN_AUCTION_NFT_PLATFORM_FEE")
            .policyValue - referralFee;
        uint256 fee = platformFee + referralFee;

        ara().transferFrom(msg.sender, address(this), fee);
        ara().transfer(LibData.getReferral(s, msg.sender), referralFee);

        asset().transferFrom(msg.sender, address(this), tokenId);
        asset().setOpenAuction(
            msg.sender,
            tokenId,
            closeAuctionPeriodSecond,
            startingPrice,
            reservePrice,
            maxWeight,
            nextBidWeight
        );
    }

    function bidAuction(
        uint256 tokenId,
        uint256 bidValue,
        uint256 maxBid
    ) external payable {
        AssetInfo memory info = asset().tokenInfo(tokenId);
        AssetAuction memory auction = asset().auctionInfo(
            tokenId,
            info.totalAuction - 1
        );
        uint256 minBidValue = (auction.value * auction.nextBidWeight) /
            auction.maxWeight +
            auction.value;

        require(
            info.isAuction &&
                LibData.isMember(s, msg.sender) &&
                (
                    auction.bidder != msg.sender
                        ? ara().balanceOf(msg.sender) >= maxBid
                        : (ara().balanceOf(msg.sender) >=
                            maxBid -
                                (auction.meetReservePrice ? auction.maxBid : 0))
                ) &&
                (
                    auction.totalBid == 0
                        ? maxBid >= auction.startingPrice
                        : maxBid >= minBidValue
                ) &&
                bidValue <= maxBid &&
                (block.timestamp < auction.closeAuctionTimestamp)
        );

        if (bidValue < auction.reservePrice && maxBid >= auction.reservePrice) {
            bidValue = auction.reservePrice;
        }

        if (bidValue < minBidValue && maxBid >= minBidValue) {
            bidValue = minBidValue;
        }

        asset().setBidAuction(
            tokenId,
            maxBid >= auction.reservePrice ? bidValue : maxBid,
            maxBid >= auction.reservePrice,
            msg.sender,
            false
        );

        if (maxBid <= auction.maxBid) {
            asset().setBidAuction(
                tokenId,
                maxBid,
                maxBid >= auction.reservePrice,
                auction.bidder,
                true
            );
            asset().updateAuction(tokenId, maxBid, 0, address(0));
        } else if (maxBid >= auction.reservePrice) {
            ara().transferFrom(
                msg.sender,
                address(this),
                auction.bidder != msg.sender
                    ? maxBid
                    : maxBid - (auction.meetReservePrice ? auction.maxBid : 0)
            );

            if (
                auction.bidder != msg.sender &&
                auction.bidder != address(0x0) &&
                auction.meetReservePrice
            ) {
                ara().transfer(auction.bidder, auction.maxBid);
            }

            asset().updateAuction(tokenId, bidValue, maxBid, msg.sender);
        } else {
            asset().updateAuction(tokenId, maxBid, maxBid, msg.sender);
        }

        if (
            auction.closeAuctionTimestamp <=
            block.timestamp +
                LibData
                    .getPolicy(s, "EXTENDED_AUCTION_NFT_TIME_TRIGGER")
                    .policyValue
        ) {
            auction.closeAuctionTimestamp =
                block.timestamp +
                LibData
                    .getPolicy(s, "EXTENDED_AUCTION_NFT_DURATION")
                    .policyValue;
        }
    }

    function processAuction(uint256 tokenId) external {
        AssetInfo memory info = asset().tokenInfo(tokenId);
        AssetAuction memory auction = asset().auctionInfo(
            tokenId,
            info.totalAuction - 1
        );

        require(
            info.isAuction && block.timestamp >= auction.closeAuctionTimestamp
        );

        asset().updateAssetIsAuction(tokenId, false);

        if (auction.totalBid > 0 && auction.value >= auction.reservePrice) {
            transferARAFromContract(
                LibAssetFactory.calculateAuctionTransferFeeLists(
                    s,
                    info,
                    auction
                ),
                9
            );
            asset().transferFrom(address(this), auction.bidder, tokenId);
        } else {
            asset().transferFrom(address(this), auction.owner, tokenId);
        }
    }

    function openBuyItNow() external {}

    function changeBuyItNowPrice() external {}

    function buyFromBuyItNow() external {}

    function closeBuyItNow() external {}

    function openOffer() external {}

    function acceptOffer() external {}

    function revertOffer() external {}

    function redeem() external {}

    function redeemCustodianSign() external {}

    function revertRedeem() external {}

    function transferFrom() external {}

    function transferFromCollectionFactory() external {}

    function transferOpenFee(
        string memory policyPlatform,
        string memory policyReferral
    ) private {
        uint256 platformFee = LibData.getPolicy(s, policyPlatform).policyValue;
        uint256 referralFee = LibData.getPolicy(s, policyReferral).policyValue;
        require(ara().balanceOf(msg.sender) >= platformFee + referralFee);

        ara().transferFrom(
            msg.sender,
            address(this),
            platformFee + referralFee
        );

        IAssetFactory.TransferARA[]
            memory feeLists = new IAssetFactory.TransferARA[](2);
        feeLists[0] = IAssetFactory.TransferARA({
            receiver: address(this),
            amount: platformFee
        });
        feeLists[1] = IAssetFactory.TransferARA({
            receiver: LibData.getReferral(s, msg.sender),
            amount: referralFee
        });

        transferARAFromContract(feeLists, 2);
    }

    function transferARAFromContract(
        IAssetFactory.TransferARA[] memory lists,
        uint8 length
    ) private {
        for (uint8 i = 0; i < length; i++) {
            if (lists[i].amount > 0) {
                uint256 amount = LibUtils.min(
                    lists[i].amount,
                    ara().balanceOf(address(this))
                );

                if (lists[i].receiver == address(this)) {
                    s.managementFund.managementFundValue += amount;
                } else {
                    ara().transferFrom(
                        address(this),
                        lists[i].receiver,
                        amount
                    );
                }
            }
        }
    }
}
