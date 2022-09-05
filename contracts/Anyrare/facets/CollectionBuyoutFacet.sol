// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {CollectionERC20} from "./CollectionERC20.sol";
import {AppStorage, CollectionInfo, CollectionOrderbookInfo, CollectionOrder} from "../libraries/LibAppStorage.sol";
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

    function collection(uint256 collectionId) internal view returns (IERC20) {
        return IERC20(s.collection.collections[collectionId].addr);
    }

    function buyoutCollection() public {}

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
