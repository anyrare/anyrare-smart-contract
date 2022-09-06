// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {CollectionERC20} from "./CollectionERC20.sol";
import {AppStorage, CollectionInfo, CollectionOrderbookInfo, CollectionOrder, CollectionTargetPriceVoteInfo} from "../libraries/LibAppStorage.sol";
import {ICurrency} from "../interfaces/ICurrency.sol";
import {ICollectionFactory} from "../interfaces/ICollectionFactory.sol";
import {IERC20} from "../../shared/interfaces/IERC20.sol";
import {AssetFacet} from "../../Asset/facets/AssetFacet.sol";
import {ARAFacet} from "../../ARA/facets/ARAFacet.sol";
import {AssetInfo, AssetAuction} from "../../Asset/libraries/LibAppStorage.sol";
import "./CollectionERC20.sol";
import "../libraries/LibData.sol";
import "../libraries/LibCollectionFactory.sol";
import "../../shared/libraries/LibUtils.sol";
import "hardhat/console.sol";

contract CollectionBuyoutFacet {
    AppStorage internal s;

    function currency() internal view returns (IERC20) {
        require(
            s.contractAddress.currency != address(0),
            "CollectionFactoryFacet: currency address cannot be 0"
        );
        return IERC20(s.contractAddress.currency);
    }

    function asset() internal view returns (AssetFacet) {
        require(
            s.contractAddress.assetDiamond != address(0),
            "CollectionFactoryFacet: assetDiamond address cannot be 0"
        );
        return AssetFacet(s.contractAddress.assetDiamond);
    }

    function collection(uint256 collectionId) internal view returns (IERC20) {
        return IERC20(s.collection.collections[collectionId].addr);
    }

    function voteTargetPrice(uint256 collectionId, uint256 price)
        external
        payable
    {
        require(LibData.isMember(s, msg.sender));

        CollectionTargetPriceVoteInfo memory t = s.collection.targetPriceVotes[
            collectionId
        ][msg.sender];

        uint256 volume = collection(collectionId).balanceOf(msg.sender);

        s.collection.targetPriceVotes[collectionId][
                msg.sender
            ] = CollectionTargetPriceVoteInfo({
            collectionId: collectionId,
            price: price,
            volume: volume,
            vote: true,
            exists: true
        });

        s.collection.collections[collectionId].targetPriceVolume -=
            t.volume +
            volume;
        s.collection.collections[collectionId].targetPriceValue -=
            (t.price * t.volume) +
            (price * volume);
    }

    function buyoutCollection(uint256 collectionId) external payable {
        uint256 targetValue = (s
            .collection
            .collections[collectionId]
            .totalSupply *
            s.collection.collections[collectionId].targetPriceValue) /
            s.collection.collections[collectionId].targetPriceVolume;

        require(
            LibData.isMember(s, msg.sender) &&
                s.collection.collections[collectionId].targetPriceVolume >=
                LibData.calculateFeeFromPolicy(
                    s,
                    s.collection.collections[collectionId].totalSupply,
                    "COLLECTION_BUYOUT"
                ) &&
                collection(collectionId).balanceOf(msg.sender) >= targetValue
        );

        currency().transferFrom(msg.sender, address(this), targetValue);
    }

    function releaseBuyoutAsset(
        uint256 collectionId,
        address collectionAddr,
        address buyer
    ) internal {
        s.collection.collections[collectionId].isFreeze = true;
        for (
            uint16 i = 0;
            i < s.collection.collections[collectionId].totalAsset;
            i++
        ) {
            asset().transferFrom(
                collectionAddr,
                buyer,
                s.collection.collectionAssets[collectionId][i]
            );
        }
    }

    function claimBuyoutFund(
        uint256 collectionId,
        address collectionAddr,
        address buyer
    ) external {
        uint256 volume = collection(collectionId).balanceOf(msg.sender);

        collection(collectionId).transferFrom(
            msg.sender,
            address(this),
            volume
        );

        currency().transferFrom(
            address(this),
            msg.sender,
            (s.collection.collections[collectionId].targetPriceValue * volume) /
                s.collection.collections[collectionId].targetPriceVolume
        );
    }

    function transferCurrencyFromContract(
        ICurrency.TransferCurrency[] memory lists,
        uint8 length
    ) private {
        for (uint8 i = 0; i < length; i++) {
            if (lists[i].amount > 0) {
                uint256 amount = LibUtils.min(
                    lists[i].amount,
                    currency().balanceOf(address(this))
                );

                if (lists[i].receiver == address(this)) {
                    s.managementFund.managementFundValue += amount;
                } else {
                    currency().transferFrom(
                        address(this),
                        lists[i].receiver,
                        amount
                    );
                }
            }
        }
    }
}
