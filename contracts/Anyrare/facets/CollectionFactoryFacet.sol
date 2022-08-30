// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {CollectionERC20} from "./CollectionERC20.sol";
import {AppStorage, CollectionInfo} from "../libraries/LibAppStorage.sol";
import {ICurrency} from "../interfaces/ICurrency.sol";
import {ICollectionFactory} from "../interfaces/ICollectionFactory.sol";
import {IERC20} from "../../shared/interfaces/IERC20.sol";
import {AssetFacet} from "../../Asset/facets/AssetFacet.sol";
import {ARAFacet} from "../../ARA/facets/ARAFacet.sol";
import {AssetInfo, AssetAuction} from "../../Asset/libraries/LibAppStorage.sol";
import "./CollectionERC20.sol";
import "../libraries/LibData.sol";
import "../libraries/LibCollectionFactory.sol";

contract CollectionFactoryFacet {
    AppStorage internal s;

    function currency() private view returns (IERC20) {
        require(
            s.contractAddress.currency != address(0),
            "CollectionFactoryFacet: currency address cannot be 0"
        );
        return IERC20(s.contractAddress.currency);
    }

    function asset() private view returns (AssetFacet) {
        require(
            s.contractAddress.assetDiamond != address(0),
            "CollectionFactoryFacet: assetDiamond address cannot be 0"
        );
        return AssetFacet(s.contractAddress.assetDiamond);
    }

    function mintCollection(ICollectionFactory.CollectionMintArgs memory args)
        external
        payable
    {
        require(args.totalAsset > 0 && args.totalSupply > 0);

        CollectionERC20 token = new CollectionERC20();
        token.setMetadata(args.name, args.symbol, args.tokenURI);

        for (uint16 i; i < args.totalAsset; i++) {
            require(asset().ownerOf(args.assets[i]) == msg.sender);
        }

        for (uint16 i; i < args.totalAsset; i++) {
            asset().transferFrom(msg.sender, address(this), args.assets[i]);
            s.collection.collectionAssets[s.collection.totalCollection][
                i
            ] = args.assets[i];
        }

        transferCurrencyFromContract(
            LibCollectionFactory.calculateMintCollectionFeeLists(s, msg.sender),
            2
        );

        token.mintTo(msg.sender, args.totalSupply);

        s.collection.collectionIndexes[address(token)] = s
            .collection
            .totalCollection;
        s.collection.collections[
            s.collection.totalCollection
        ] = CollectionInfo({
            addr: address(token),
            collector: msg.sender,
            name: args.name,
            symbol: args.symbol,
            tokenURI: args.tokenURI,
            lowestDecimal: args.lowestDecimal,
            precisionDigit: args.precisionDigit,
            totalSupply: args.totalSupply,
            maxWeight: args.maxWeight,
            collectorFeeWeight: args.collectorFeeWeight,
            totalAsset: args.totalAsset,
            totalShareholder: 1,
            isAuction: false,
            isFreeze: false,
            targetPrice: 0,
            targetPriceTotalSum: 0,
            targetPriceTotalVoteToken: 0,
            targetPriceTotalVoter: 0
        });

        s.collection.shareholders[s.collection.totalCollection][0] = msg.sender;
        s.collection.shareholderIndexes[s.collection.totalCollection][
            msg.sender
        ] = 0;
        s.collection.totalCollection += 1;
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

    function buyLimit(
        address collectionAddr,
        uint256 collectionId,
        uint256 price,
        uint256 amount
    ) external payable {
        IERC20 collection = IERC20(collectionAddr);
    }
}
