// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";

struct MemberInfo {
    address addr;
    address referral;
    uint8 accountType;
    string username;
    string thumbnail;
    uint8 multiSigTotalAddress;
    uint8 multiSigTotalApprove;
    uint32 totalAsset;
    uint256 totalBidAuction;
    uint256 totalWonAuction;
    uint32 totalFounderCollection;
    uint32 totalOwnCollection;
    mapping(uint8 => address) multiSigAddresses;
    mapping(uint32 => uint256) assets;
}

struct Member {
    uint256 totalMember;
    mapping(address => MemberInfo) members;
    mapping(bytes32 => address) usernames;
}

struct CollectionInfo {
    address addr;
}

struct Collection {
    mapping(uint256 => address) collections;
    mapping(address => uint256) collectionIndexes;
    uint256 totalCollection;
}

struct CollectionStorage {
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => uint256) balances;
    address[] approvedContracts;
    mapping(address => uint256) approvedContractIndexes;
    bytes32[1000] emptyMapSlots;
    address contractOwner;
    uint96 totalSupply;
    string name;
    string symbol;
    string tokenURI;
}

struct Asset {
    address addr;
}

struct AssetInfo {
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

struct AssetStorage {
    address owner;
    string name;
    string symbol;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    mapping(uint256 => string) tokenURIs;
    mapping(uint256 => AssetInfo) infos;
}

struct AppStorage {
    address araToken;
    Member member;
    Collection collection;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}
