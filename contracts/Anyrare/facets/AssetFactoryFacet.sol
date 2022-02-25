// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibUtils} from "../../shared/libraries/LibUtils.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IAssetFactory} from "../interfaces/IAssetFactory.sol";
import {IAsset} from "../../Asset/interfaces/IAsset.sol";
import {AssetFacet} from "../../Asset/facets/AssetFacet.sol";
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

        console.log("A203910: ", s.asset.assetToken);
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
        
    }
}
