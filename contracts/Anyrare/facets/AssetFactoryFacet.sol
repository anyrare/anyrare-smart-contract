// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibUtils} from "../../shared/libraries/LibUtils.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IAssetFactory} from "../interfaces/IAssetFactory.sol";
import {IAsset} from "../../Asset/interfaces/IAsset.sol";
import {AssetFacet} from "../../Asset/facets/AssetFacet.sol";
import {ARAFacet} from "../../ARA/facets/ARAFacet.sol";
import {AssetInfo} from "../../Asset/libraries/LibAppStorage.sol";
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
        uint256 fee = info.auditFee;
        console.log("fee", fee);

        require(ara.balanceOf(msg.sender) >= fee);
        ara.transfer(info.auditor, info.auditFee);
        
        asset.payFeeAndClaimToken(tokenId, msg.sender);
    }

    function transferOpenFee() external {}

    function transferARAFromContract() external {}

    function getAuctionByAuctionId() external {}

    function openAuction() external {}

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
