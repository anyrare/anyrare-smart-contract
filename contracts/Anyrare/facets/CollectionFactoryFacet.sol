// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {CollectionERC20} from "./CollectionERC20.sol";
import {AppStorage, CollectionInfo} from "../libraries/LibAppStorage.sol";
import {IARA} from "../interfaces/IARA.sol";
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
        require(collateralWeight > 0 && totalAsset > 0 && initialValue > 0);

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

        token.mintTo(msg.sender, (initialValue * collateralWeight) / maxWeight);

        s.collection.collectionIndexes[address(token)] = s
            .collection
            .totalCollection;
        s.collection.collections[
            s.collection.totalCollection
        ] = CollectionInfo({
            addr: address(token),
            collector: msg.sender,
            name: name,
            symbol: symbol,
            tokenURI: tokenURI,
            maxWeight: maxWeight,
            collateralWeight: collateralWeight,
            collectorFeeWeight: collectorFeeWeight,
            dummyCollateralValue: (initialValue * collateralWeight) / maxWeight,
            totalAsset: totalAsset,
            totalShareholder: 1,
            isAuction: false,
            isFreeze: false,
            targetPrice: 0,
            targetPriceTotalSum: 0,
            targetPriceTotalVoteToken: 0,
            targetPriceTotalVoter: 0
        });
        s.collection.shareholders[0] = msg.sender;
        s.collection.shareholderIndexes[msg.sender] = 0;
        s.collection.totalCollection += 1;
    }

    function transferARAFromContract(
        IARA.TransferARA[] memory lists,
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
