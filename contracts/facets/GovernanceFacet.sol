pragma solidity ^0.8.0;
pragma abicoder v2;

import {AppStorage, GovernanceFounder, GovernanceManager, GovernanceOperation, GovernancePolicy, GovernanceInitPolicy} from "../libraries/LibAppStorage.sol";
import {LibUtils} from "../libraries/LibUtils.sol";

contract GovernanceFacet {
    AppStorage internal s;

    function initPolicy(
        uint16 _totalFounder,
        GovernanceFounder[] memory _founders,
        address _manager,
        address _operation,
        address _auditor,
        address _custodian,
        uint16 _totalPolicy,
        GovernanceInitPolicy[] memory _policies
    ) external {
        require(!s.governance.isInitPolicy);

        s.governance.isInitPolicy = true;

        s.governance.founderMaxControlWeight = 10**6;
        s.governance.totalFounder = _totalFounder;

        for (uint16 i; i < _totalFounder; i++) {
            s.governance.founders[i] = _founders[i];
        }

        s.governance.managers[0].addr = _manager;
        s.governance.managers[0].controlWeight = 10**6;
        s.governance.managerMaxControlWeight = 10**6;
        s.governance.totalManager = 1;
        s.governance.managersAddress[_manager] = 0;

        s.governance.operations[0].addr = _operation;
        s.governance.operations[0].controlWeight = 10**6;
        s.governance.operationMaxControlWeight = 10**6;
        s.governance.totalOperation = 1;
        s.governance.operationsAddress[_operation] = 0;

        s.governance.auditors[_auditor].approve = true;
        s.governance.custodians[_custodian].approve = true;

        for (uint16 i; i < _totalPolicy; i++) {
            bytes32 policyIndex = LibUtils.stringToBytes32(
                _policies[i].policyName
            );

            s.governance.policies[policyIndex].policyWeight = _policies[i]
                .policyWeight;
            s.governance.policies[policyIndex].maxWeight = _policies[i]
                .maxWeight;
            s.governance.policies[policyIndex].voteDuration = _policies[i]
                .voteDuration;
            s.governance.policies[policyIndex].effectiveDuration = _policies[i]
                .effectiveDuration;
            s.governance.policies[policyIndex].minWeightOpenVote = _policies[i]
                .minWeightOpenVote;
            s.governance.policies[policyIndex].minWeightValidVote = _policies[i]
                .minWeightValidVote;
            s.governance.policies[policyIndex].minWeightApproveVote = _policies[
                i
            ].minWeightApproveVote;
            s.governance.policies[policyIndex].policyValue = _policies[i]
                .policyValue;
            s.governance.policies[policyIndex].decider = _policies[i].decider;
            s.governance.policies[policyIndex].exists = true;
        }
    }
}
