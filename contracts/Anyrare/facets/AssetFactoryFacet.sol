// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibUtils} from "../../shared/libraries/LibUtils.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import "hardhat/console.sol";

contract AssetFactoryFacet {
    AppStorage internal s;

    struct MintAssetArgs {
        address founder;
        address custodian;
        string tokenURI;
        uint256 maxWeight;
        uint256 founderWeight;
        uint256 founderRedeemWeight;
        uint256 founderGeneralFee;
        uint256 auditFee;
        uint256 custodianWeight;
        uint256 custodianGeneralFee;
        uint256 custodianRedeemWeight;
    }

    struct Args {
        address owner;
        string c;
    }

    function initAssetFactory(address assetToken) public {
        require(
            s.asset.assetToken == address(0),
            "AssetFactoryFacet: already init"
        );
        s.asset.assetToken = assetToken;
    }

    function mintAsset(
        // MintAssetArgs memory args
        address founder
    ) external payable {
        console.log("C2112", s.asset.assetToken);
        require(
            s.asset.assetToken != address(0),
            "AssetFactoryFacet: failed to mint"
        );
        address c = s.asset.assetToken;

        // (bool success, bytes memory result) = c.call(
        //     abi.encodeWithSignature(
        //         "mint(address,address,address,string memory,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"
        //     ),
        //     msg.sender,
        //     founder,
        //     custodian,
        //     tokenURI,
        //     maxWeight,
        //     founderWeight,
        //     founderRedeemWeight,
        //     founderGeneralFee,
        //     auditFee,
        //     custodianWeight,
        //     custodianGeneralFee,
        //     custodianRedeemWeight
        // );

        Args memory a = Args(founder, "T10933");

        (bool success, bytes memory result) = c.call(
            abi.encodeWithSignature("t8((address,string))", a)
        );
    }
}
