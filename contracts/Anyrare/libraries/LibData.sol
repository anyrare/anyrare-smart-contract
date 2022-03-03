// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage, GovernanceManager, GovernanceFounder, GovernanceOperation, GovernancePolicy, PolicyProposalInfo} from "../libraries/LibAppStorage.sol";
import "../../shared/libraries/LibUtils.sol";
import "../interfaces/IMember.sol";
import {ARAFacet} from "../../ARA/facets/ARAFacet.sol";

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
        returns (IMember.MemberInfo memory m)
    {
        IMember.MemberInfo memory m;

        m.addr = addr;
        m.referral = s.member.members[addr].referral;
        m.accountType = s.member.members[addr].accountType;
        m.username = s.member.members[addr].username;
        m.thumbnail = s.member.members[addr].thumbnail;
        m.multiSigTotalAddress = s.member.members[addr].multiSigTotalAddress;
        m.multiSigTotalApprove = s.member.members[addr].multiSigTotalApprove;
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

    function getFounder(AppStorage storage s, uint16 index)
        public
        view
        returns (GovernanceFounder memory founder)
    {
        return s.governance.founders[index];
    }

    function getFounderByAddress(AppStorage storage s, address addr)
        public
        view
        returns (GovernanceFounder memory founder)
    {
        return s.governance.founders[s.governance.foundersAddress[addr]];
    }

    function getTotalFounder(AppStorage storage s)
        public
        view
        returns (uint16)
    {
        return s.governance.totalFounder;
    }

    function getFounderMaxControlWeight(AppStorage storage s)
        public
        view
        returns (uint256)
    {
        return s.governance.founderMaxControlWeight;
    }

    function getManager(AppStorage storage s, uint16 index)
        public
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
        public
        view
        returns (uint16)
    {
        return s.governance.totalManager;
    }

    function getManagerMaxControlWeight(AppStorage storage s)
        public
        view
        returns (uint256)
    {
        return s.governance.managerMaxControlWeight;
    }

    function getOperation(AppStorage storage s, uint16 index)
        public
        view
        returns (GovernanceOperation memory operation)
    {
        return s.governance.operations[index];
    }

    function getOperationByAddress(AppStorage storage s, address addr)
        public
        view
        returns (GovernanceOperation memory operation)
    {
        return s.governance.operations[s.governance.operationsAddress[addr]];
    }

    function getTotalOperation(AppStorage storage s)
        public
        view
        returns (uint16)
    {
        return s.governance.totalOperation;
    }

    function getOperationMaxControlWeight(AppStorage storage s)
        public
        view
        returns (uint256)
    {
        return s.governance.operationMaxControlWeight;
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

    function isManager(AppStorage storage s, address addr)
        public
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

    function isOperation(AppStorage storage s, address addr)
        public
        view
        returns (bool)
    {
        if (
            s.governance.operationsAddress[addr] != 0 &&
            s
                .governance
                .operations[s.governance.operationsAddress[addr]]
                .addr ==
            addr
        ) return true;
        else if (s.governance.operations[0].addr == addr) return true;
        else return false;
    }

    function isAuditor(AppStorage storage s, address addr)
        public
        view
        returns (bool)
    {
        return s.governance.auditors[addr].approve;
    }

    function isCustodian(AppStorage storage s, address addr)
        public
        view
        returns (bool)
    {
        return s.governance.custodians[addr].approve;
    }

    function getTotalCollection(AppStorage storage s)
        external
        view
        returns (uint256)
    {
        return s.collection.totalCollection;
    }

    function isValidCollection(AppStorage storage s, address addr)
        external
        view
        returns (bool)
    {
        return
            addr ==
            s.collection.collections[s.collection.collectionIndexes[addr]].addr;
    }

    function araTotalSupply(AppStorage storage s)
        external
        view
        returns (uint256)
    {
        ARAFacet c = ARAFacet(s.contractAddress.araToken);
        return c.totalSupply();
    }

    function araTotalFreeFloatSupply(AppStorage storage s)
        external
        view
        returns (uint256)
    {
        ARAFacet c = ARAFacet(s.contractAddress.araToken);
        return c.totalSupply() - c.balanceOf(address(this));
    }

    function araBalanceOf(AppStorage storage s, address addr)
        external
        view
        returns (uint256)
    {
        ARAFacet c = ARAFacet(s.contractAddress.araToken);
        return c.balanceOf(addr);
    }

    function araCurrentTotalValue(AppStorage storage s)
        public
        view
        returns (uint256)
    {
        ARAFacet c = ARAFacet(s.contractAddress.araToken);
        return
            (c.totalSupply() * 1000000) /
            getPolicy(s, "ARA_COLLATERAL_WEIGHT").policyWeight;
    }

    function getCurrentPolicyProposal(
        AppStorage storage s,
        string memory policyName
    ) public view returns (PolicyProposalInfo memory policyProposalInfo) {
        bytes32 policyIndex = LibUtils.stringToBytes32(policyName);
        return
            s
                .proposal
                .policyProposals[
                    s.proposal.policyProposalIndexes[policyIndex].id
                ]
                .info;
    }

    function getCurrentPolicyProposalId(AppStorage storage s)
        public
        view
        returns (uint256)
    {
        return s.proposal.policyProposalId - 1;
    }

    function getCurrentListProposalId(AppStorage storage s)
        public
        view
        returns (uint256)
    {
        return s.proposal.listProposalId - 1;
    }

    function getManagementFundValue(AppStorage storage s)
        public
        view
        returns (uint256)
    {
        return s.managementFund.managementFundValue;
    }

    function calculateFeeFromPolicy(
        AppStorage storage s,
        uint256 value,
        string memory policyName
    ) public view returns (uint256) {
        return
            (value * getPolicy(s, policyName).policyWeight) /
            getPolicy(s, policyName).maxWeight;
    }
}
