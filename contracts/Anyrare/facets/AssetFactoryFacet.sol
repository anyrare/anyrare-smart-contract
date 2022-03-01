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
import {AssetInfo} from "../../Asset/libraries/LibAppStorage.sol";
import "../libraries/LibData.sol";
import "hardhat/console.sol";

contract AssetFactoryFacet {
    AppStorage internal s;

    function initAssetFactory(address assetToken) public {
        require(
            s.asset.assetToken == address(0),
            "AssetFactoryFacet: already init"
        );
        s.asset.assetToken = assetToken;
    }

    function mintAsset(IAssetFactory.AssetMintArgs memory args)
        external
        payable
    {
        require(
            s.asset.assetToken != address(0),
            "AssetFactoryFacet: failed to mint"
        );

        address c = s.asset.assetToken;
        AssetFacet(c).mint(
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
        AssetFacet(s.contractAddress.assetToken).custodianSign(
            tokenId,
            msg.sender
        );
    }

    function payFeeAndClaimToken(uint256 tokenId) external {
        ARAFacet ara = ARAFacet(s.contractAddress.araToken);
        AssetFacet asset = AssetFacet(s.contractAddress.assetToken);
        AssetInfo memory info = asset.tokenInfo(tokenId);
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

        ara.transferFrom(msg.sender, address(this), fee);
        ara.transfer(info.auditor, auditFee);
        ara.transfer(LibData.getReferral(s, info.founder), referralFounderFee);
        ara.transfer(LibData.getReferral(s, info.auditor), auditReferralFee);

        asset.payFeeAndClaimToken(tokenId, msg.sender);
    }

    function openAuction(
        uint256 tokenId,
        uint256 closeAuctionPeriodSecond,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 maxWeight,
        uint256 nextBidWeight
    ) external {
        ARAFacet ara = ARAFacet(s.contractAddress.araToken);
        AssetFacet asset = AssetFacet(s.contractAddress.assetToken);
        AssetInfo memory info = asset.tokenInfo(tokenId);

        require(
            asset.ownerOf(tokenId) == msg.sender &&
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

        ara.transferFrom(msg.sender, address(this), fee);
        ara.transfer(LibData.getReferral(s, msg.sender), referralFee);

        asset.transferFrom(msg.sender, address(this), tokenId);

        asset.setOpenAuction(
            msg.sender,
            tokenId,
            closeAuctionPeriodSecond,
            startingPrice,
            reservePrice,
            maxWeight,
            nextBidWeight
        );
    }

    function bidAuction() external {}

    function processAuction() external {}

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
}
