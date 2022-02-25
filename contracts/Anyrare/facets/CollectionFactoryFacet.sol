// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {CollectionERC20} from "./CollectionERC20.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import "hardhat/console.sol";

contract CollectionFactoryFacet {
    AppStorage internal s;

    function mint(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _initialValue,
        uint256 _maxWeight,
        uint256 _collateralWeight,
        uint256 _collectorFeeWeight,
        uint32 _totalAsset,
        uint256[] memory _assets
    ) external payable {
        

    }
}
