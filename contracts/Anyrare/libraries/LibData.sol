// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage, GovernanceManager, GovernancePolicy, CollectionInfo} from "../libraries/LibAppStorage.sol";
import {IERC20} from "../../shared/interfaces/IERC20.sol";
import "../../shared/libraries/LibUtils.sol";
import "../interfaces/IMember.sol";

library LibData {
    function isMember(AppStorage storage s, address addr)
        external
        view
        returns (bool)
    {
        return s.member.members[addr].referral != address(0);
    }

    function getReferral(AppStorage storage s, address addr)
        external
        view
        returns (address)
    {
        return s.member.members[addr].referral;
    }

    function getAddressByUsername(AppStorage storage s, string memory username)
        external
        view
        returns (address)
    {
        return s.member.usernames[LibUtils.stringToBytes32(username)];
    }

    function getMember(AppStorage storage s, address addr)
        external
        view
        returns (IMember.MemberInfo memory m0)
    {
        IMember.MemberInfo memory m;

        m.addr = addr;
        m.referral = s.member.members[addr].referral;
        m.username = s.member.members[addr].username;
        m.thumbnail = s.member.members[addr].thumbnail;
        m.totalAsset = s.member.members[addr].totalAsset;
        m.totalBidAuction = s.member.members[addr].totalBidAuction;
        m.totalWonAuction = s.member.members[addr].totalWonAuction;
        m.totalFounderCollection = s
            .member
            .members[addr]
            .totalFounderCollection;
        m.totalOwnCollection = s.member.members[addr].totalOwnCollection;

        return m;
    }

    function getManager(AppStorage storage s, uint8 index)
        external
        view
        returns (GovernanceManager memory manager)
    {
        return s.governance.managers[index];
    }

    function getManagerByAddress(AppStorage storage s, address addr)
        public
        view
        returns (GovernanceManager memory manager)
    {
        return s.governance.managers[s.governance.managersAddress[addr]];
    }

    function getTotalManager(AppStorage storage s)
        external
        view
        returns (uint16)
    {
        return s.governance.totalManager;
    }

    function getManagerMaxControlWeight(AppStorage storage s)
        external
        view
        returns (uint256)
    {
        return s.governance.managerMaxControlWeight;
    }

    function isManager(AppStorage storage s, address addr)
        external
        view
        returns (bool)
    {
        if (
            s.governance.managersAddress[addr] != 0 &&
            s.governance.managers[s.governance.managersAddress[addr]].addr ==
            addr
        ) return true;
        else if (s.governance.managers[0].addr == addr) return true;
        else return false;
    }

    function isAuditor(AppStorage storage s, address addr)
        external
        view
        returns (bool)
    {
        return s.governance.auditors[addr].approve;
    }

    function isCustodian(AppStorage storage s, address addr)
        external
        view
        returns (bool)
    {
        return s.governance.custodians[addr].approve;
    }

    function getPolicy(AppStorage storage s, string memory policyName)
        public
        view
        returns (GovernancePolicy memory policy)
    {
        return s.governance.policies[LibUtils.stringToBytes32(policyName)];
    }

    function getPolicyByIndex(AppStorage storage s, bytes32 policyIndex)
        public
        view
        returns (GovernancePolicy memory policy)
    {
        return s.governance.policies[policyIndex];
    }

    function calculateFeeFromPolicy(
        AppStorage storage s,
        uint256 value,
        string memory policyName
    ) external view returns (uint256) {
        return
            (value * getPolicy(s, policyName).policyWeight) /
            getPolicy(s, policyName).maxWeight;
    }

    function getTotalCollection(AppStorage storage s)
        external
        view
        returns (uint256)
    {
        return s.collection.totalCollection;
    }

    function getCollectionByIndex(AppStorage storage s, uint256 index)
        external
        view
        returns (CollectionInfo memory info)
    {
        return s.collection.collections[index];
    }

    function getCollectionIndexByAddress(AppStorage storage s, address addr)
        external
        view
        returns (uint256)
    {
        return s.collection.collectionIndexes[addr];
    }

    function getBalanceOfERC20(address addr, address owner)
        public
        view
        returns (uint256)
    {
        return IERC20(addr).balanceOf(owner);
    }

    function getCollectionBidsPrice(AppStorage storage s, uint256 collectionId)
        external
        view
        returns (uint256[255] memory prices)
    {
        return s.collection.bidsPrice[collectionId];
    }

    function getCollectionOffersPrice(
        AppStorage storage s,
        uint256 collectionId
    ) external view returns (uint256[255] memory prices) {
        return s.collection.offersPrice[collectionId];
    }

    function getCollectionBidsVolume(
        AppStorage storage s,
        uint256 collectionId,
        uint8 posIndex,
        uint8 bitIndex
    ) external view returns (uint256) {
        return s.collection.bidsVolume[collectionId][posIndex][bitIndex];
    }

    function getCollectionOffersVolume(
        AppStorage storage s,
        uint256 collectionId,
        uint8 posIndex,
        uint8 bitIndex
    ) external view returns (uint256) {
        return s.collection.offersVolume[collectionId][posIndex][bitIndex];
    }

    function getCollectionBalanceById(
        AppStorage storage s,
        uint256 collectionId,
        address addr
    ) external view returns (uint256) {
        return
            getBalanceOfERC20(
                s.collection.collections[collectionId].addr,
                addr
            );
    }
}
