pragma solidity ^0.8.0;
pragma abicoder v2;

import {AppStorage, GovernanceFounder, GovernanceManager, GovernanceOperation, GovernancePolicy, GovernanceInitPolicy} from "../libraries/LibAppStorage.sol";
import {LibUtils} from "../libraries/LibUtils.sol";
import {LibACL} from "../libraries/LibACL.sol";

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
        require(
            !s.governance.isInitPolicy,
            "GovernanceFacet: Failed to init policy"
        );

        s.governance.isInitPolicy = true;

        s.governance.founderMaxControlWeight = 10**6;
        s.governance.totalFounder = _totalFounder;

        s.governance.admins[0] = msg.sender;
        s.governance.totalAdmin = 1;

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

    function setPolicyByProposal(
        bytes32 policyIndex,
        uint256 policyWeight,
        uint256 maxWeight,
        uint32 voteDuration,
        uint256 minWeightOpenVote,
        uint256 minWeightValidVote,
        uint256 minWeightApproveVote,
        uint256 policyValue,
        uint8 decider
    ) external {
        require(msg.sender == address(this));

        s.governance.policies[policyIndex].policyWeight = policyWeight;
        s.governance.policies[policyIndex].maxWeight = maxWeight;
        s.governance.policies[policyIndex].voteDuration = voteDuration;
        s
            .governance
            .policies[policyIndex]
            .minWeightOpenVote = minWeightOpenVote;
        s
            .governance
            .policies[policyIndex]
            .minWeightValidVote = minWeightValidVote;
        s
            .governance
            .policies[policyIndex]
            .minWeightApproveVote = minWeightApproveVote;
        s.governance.policies[policyIndex].policyValue = policyValue;
        s.governance.policies[policyIndex].decider = decider;
        s.governance.policies[policyIndex].openVote = false;
    }

    function setManagerAtIndexByProposal(
        uint16 _totalManager,
        uint16 managerIndex,
        address addr,
        uint256 controlWeight,
        uint256 maxWeight,
        string memory dataURI
    ) external {
        require(msg.sender == address(this));

        s.governance.totalManager = _totalManager;

        s.governance.managers[managerIndex].addr = addr;
        s.governance.managers[managerIndex].controlWeight = controlWeight;
        s.governance.managers[managerIndex].dataURI = dataURI;
        s.governance.managersAddress[addr] = managerIndex;
        s.governance.managerMaxControlWeight = maxWeight;
    }

    function setOperationAtIndexByProposal(
        uint16 _totalOperation,
        uint16 operationIndex,
        address addr,
        uint256 controlWeight,
        uint256 maxWeight,
        string memory dataURI
    ) external {
        require(msg.sender == address(this));

        s.governance.totalOperation = _totalOperation;

        s.governance.operations[operationIndex].addr = addr;
        s.governance.operations[operationIndex].controlWeight = controlWeight;
        s.governance.operations[operationIndex].dataURI = dataURI;
        s.governance.operationsAddress[addr] = operationIndex;
        s.governance.operationMaxControlWeight = maxWeight;
    }

    function setAuditorByProposal(
        address addr,
        bool approve,
        string memory dataURI
    ) external {
        require(msg.sender == address(this));

        s.governance.auditors[addr].approve = approve;
        s.governance.auditors[addr].dataURI = dataURI;
    }

    function setCustodianByProposal(
        address addr,
        bool approve,
        string memory dataURI
    ) external {
        require(msg.sender == address(this));

        s.governance.custodians[addr].approve = approve;
        s.governance.custodians[addr].dataURI = dataURI;
    }

    function getFounder(uint16 index)
        external
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
        return LibACL.isManager(s, addr);
    }

    function isOperation(address addr) public view returns (bool) {
        return LibACL.isOperation(s, addr);
    }

    function isAuditor(address addr) public view returns (bool) {
        return s.governance.auditors[addr].approve;
    }

    function isCustodian(address addr) public view returns (bool) {
        return s.governance.custodians[addr].approve;
    }
}
