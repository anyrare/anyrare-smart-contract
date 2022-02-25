// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IGovernance.sol";
import "../../shared/libraries/LibUtils.sol";
import {AppStorage, GovernanceManager, GovernanceFounder, GovernanceOperation, GovernancePolicy} from "../libraries/LibAppStorage.sol";

contract GovernanceFacet {
    AppStorage internal s;

    function initContractAddress(address araToken, address assetToken)
        external
    {
        require(
            !s.governance.isInitContractAddress,
            "GovernanceFacet: already init contract address"
        );
        s.governance.isInitContractAddress = true;
        s.contractAddress.araToken = araToken;
        s.contractAddress.assetToken = assetToken;
    }

    function initPolicy(
        uint16 totalFounder,
        IGovernance.Founder[] memory founders,
        address manager,
        address operation,
        address auditor,
        address custodian,
        uint16 totalPolicy,
        IGovernance.InitPolicy[] memory policies
    ) external {
        require(
            !s.governance.isInitPolicy,
            "GovernanceFacet: already init policy"
        );

        s.governance.isInitPolicy = true;
        s.governance.founderMaxControlWeight = 10**6;
        s.governance.totalFounder = totalFounder;

        for (uint16 i; i < totalFounder; i++) {
            s.governance.founders[i].addr = founders[i].addr;
            s.governance.founders[i].controlWeight = founders[i].controlWeight;
        }

        s.governance.managers[0].addr = manager;
        s.governance.managers[0].controlWeight = 10**6;
        s.governance.managerMaxControlWeight = 10**6;
        s.governance.totalManager = 1;
        s.governance.managersAddress[manager] = 0;

        s.governance.operations[0].addr = operation;
        s.governance.operations[0].controlWeight = 10**6;
        s.governance.operationMaxControlWeight = 10**6;
        s.governance.totalOperation = 1;
        s.governance.operationsAddress[operation] = 0;

        s.governance.auditors[auditor].approve = true;
        s.governance.custodians[custodian].approve = true;

        s.governance.admins[0] = msg.sender;

        for (uint16 i; i < totalPolicy; i++) {
            bytes32 policyIndex = LibUtils.stringToBytes32(
                policies[i].policyName
            );

            s.governance.policies[policyIndex].policyName = policies[i]
                .policyName;
            s.governance.policies[policyIndex].policyWeight = policies[i]
                .policyWeight;
            s.governance.policies[policyIndex].maxWeight = policies[i]
                .maxWeight;
            s.governance.policies[policyIndex].voteDuration = policies[i]
                .voteDuration;
            s.governance.policies[policyIndex].effectiveDuration = policies[i]
                .effectiveDuration;
            s.governance.policies[policyIndex].minWeightOpenVote = policies[i]
                .minWeightOpenVote;
            s.governance.policies[policyIndex].minWeightValidVote = policies[i]
                .minWeightValidVote;
            s.governance.policies[policyIndex].minWeightApproveVote = policies[
                i
            ].minWeightApproveVote;
            s.governance.policies[policyIndex].policyValue = policies[i]
                .policyValue;
            s.governance.policies[policyIndex].decider = policies[i].decider;
            s.governance.policies[policyIndex].exists = true;
            s.governance.policies[policyIndex].openVote = false;
        }
    }

    function getFounder(uint16 index)
        public
        view
        returns (GovernanceFounder memory founder)
    {
        return s.governance.founders[index];
    }

    function getFounderByAddress(address addr)
        public
        view
        returns (GovernanceFounder memory founder)
    {
        return s.governance.founders[s.governance.foundersAddress[addr]];
    }

    function getTotalFounder() public view returns (uint16) {
        return s.governance.totalFounder;
    }

    function getFounderMaxControlWeight() public view returns (uint256) {
        return s.governance.founderMaxControlWeight;
    }

    function getManager(uint16 index)
        public
        view
        returns (GovernanceManager memory manager)
    {
        return s.governance.managers[index];
    }

    function getManagerByAddress(address addr)
        public
        view
        returns (GovernanceManager memory manager)
    {
        return s.governance.managers[s.governance.managersAddress[addr]];
    }

    function getTotalManager() public view returns (uint16) {
        return s.governance.totalManager;
    }

    function getManagerMaxControlWeight() public view returns (uint256) {
        return s.governance.managerMaxControlWeight;
    }

    function getOperation(uint16 index)
        public
        view
        returns (GovernanceOperation memory operation)
    {
        return s.governance.operations[index];
    }

    function getOperationByAddress(address addr)
        public
        view
        returns (GovernanceOperation memory operation)
    {
        return s.governance.operations[s.governance.operationsAddress[addr]];
    }

    function getTotalOperation() public view returns (uint16) {
        return s.governance.totalOperation;
    }

    function getOperationMaxControlWeight() public view returns (uint256) {
        return s.governance.operationMaxControlWeight;
    }

    function getPolicy(string memory policyName)
        public
        view
        returns (GovernancePolicy memory policy)
    {
        return s.governance.policies[LibUtils.stringToBytes32(policyName)];
    }

    function getPolicyByIndex(bytes32 policyIndex)
        public
        view
        returns (GovernancePolicy memory policy)
    {
        return s.governance.policies[policyIndex];
    }

    function isManager(address addr) public view returns (bool) {
        if (
            s.governance.managersAddress[addr] != 0 &&
            s.governance.managers[s.governance.managersAddress[addr]].addr ==
            addr
        ) return true;
        else if (s.governance.managers[0].addr == addr) return true;
        else return false;
    }

    function isOperation(address addr) public view returns (bool) {
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

    function isAuditor(address addr) public view returns (bool) {
        return s.governance.auditors[addr].approve;
    }

    function isCustodian(address addr) public view returns (bool) {
        return s.governance.custodians[addr].approve;
    }
}
