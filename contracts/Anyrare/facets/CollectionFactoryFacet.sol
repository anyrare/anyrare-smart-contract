// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {CollectionERC20} from "./CollectionERC20.sol";
import {AppStorage, CollectionInfo} from "../libraries/LibAppStorage.sol";
import {AssetFacet} from "../../Asset/facets/AssetFacet.sol";
import {ARAFacet} from "../../ARA/facets/ARAFacet.sol";
import {AssetInfo, AssetAuction} from "../../Asset/libraries/LibAppStorage.sol";
import "hardhat/console.sol";
import "./CollectionERC20.sol";
import "../libraries/LibData.sol";
import "hardhat/console.sol";

contract CollectionFactoryFacet {
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

    function mint(
        string memory name,
        string memory symbol,
        string memory tokenURI,
        uint256 initialValue,
        uint256 maxWeight,
        uint256 collateralWeight,
        uint256 collectorFeeWeight,
        uint32 totalAsset,
        uint256[] memory assets
    ) external payable {
        CollectionERC20 token = new CollectionERC20();
        token.setMetadata(name, symbol, tokenURI);

        for (uint32 i; i < totalAsset; i++) {
            require(asset().ownerOf(assets[i]) == msg.sender);
        }

        for (uint32 i; i < totalAsset; i++) {
            asset().transferFrom(msg.sender, address(this), assets[i]);
            s.collection.collectionAssets[s.collection.totalCollection][
                    i
                ] = assets[i];
        }

        token.mintTo(
            msg.sender,
            (initialValue * collateralWeight) / maxWeight
        );

        s.collection.collectionIndexes[address(token)] = s
            .collection
            .totalCollection;
        s.collection.collections[
            s.collection.totalCollection
        ] =
            CollectionInfo({
            addr: address(token),
            collector: msg.sender,
            name: name,
            symbol: symbol,
            tokenURI: tokenURI,
            maxWeight: maxWeight,
            collateralWeight: collateralWeight,
            collectorFeeWeight: collectorFeeWeight,
            totalAsset: totalAsset
        });
    }
}
