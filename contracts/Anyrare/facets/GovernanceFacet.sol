// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IGovernance.sol";
import "../../shared/libraries/LibUtils.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import "hardhat/console.sol";

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
}
