pragma solidity ^0.8.0;
pragma abicoder v2;

contract Governance {
    struct Manager {
        address addr;
        uint256 controlWeight;
        string dataURI;
    }

    struct Auditor {
        bool approve;
        string dataURI;
    }

    struct Custodian {
        bool approve;
        string dataURI;
    }

    struct Operation {
        address addr;
        uint256 controlWeight;
        string dataURI;
    }

    struct Policy {
        uint256 policyWeight;
        uint256 maxWeight;
        uint32 voteDuration;
        uint32 effectiveDuration;
        uint256 minWeightOpenVote;
        uint256 minWeightValidVote;
        uint256 minWeightApproveVote;
        uint256 policyValue;
        uint8 decider;
        bool exists;
        bool openVote;
    }

    struct Voter {
        bool voted;
        bool approve;
    }

    struct InitPolicyAddress {
        address manager;
        address auditor;
        address custodian;
    }

    struct InitPolicy {
        string policyName;
        uint256 policyWeight;
        uint256 maxWeight;
        uint32 voteDuration;
        uint32 effectiveDuration;
        uint256 minWeightOpenVote;
        uint256 minWeightValidVote;
        uint256 minWeightApproveVote;
        uint256 policyValue;
        uint8 decider;
    }

    bool private isInitContractAddress;
    bool private isInitPolicy;
    address private memberContract;
    address private araTokenContract;
    address private bancorFormulaContract;
    address private proposalContract;
    address private nftFactoryContract;
    address private nftUtilsContract;
    address private collectionFactoryContract;
    address private collectionUtilsContract;
    address private managementFundContract;

    mapping(bytes32 => Policy) public policies;
    mapping(uint16 => Manager) public managers;
    mapping(address => uint16) public managersAddress;
    mapping(uint16 => Operation) public operations;
    mapping(address => uint16) public operationsAddress;
    mapping(address => Auditor) public auditors;
    mapping(address => Custodian) public custodians;

    uint16 public totalManager;
    uint16 public totalOperation;
    uint256 public managerMaxControlWeight;
    uint256 public operationMaxControlWeight;

    constructor() {
        isInitContractAddress = false;
        isInitPolicy = false;
    }

    function initContractAddress(
        address _memberContract,
        address _araTokenContract,
        address _bancorFormulaContract,
        address _proposalContract,
        address _nftFactoryContract,
        address _nftUtilsContract,
        address _collectionFactoryContract,
        address _collectionUtilsContract,
        address _managementFundContract
    ) public {
        require(!isInitContractAddress);

        isInitContractAddress = true;
        memberContract = _memberContract;
        araTokenContract = _araTokenContract;
        bancorFormulaContract = _bancorFormulaContract;
        proposalContract = _proposalContract;
        nftFactoryContract = _nftFactoryContract;
        nftUtilsContract = _nftUtilsContract;
        collectionFactoryContract = _collectionFactoryContract;
        collectionUtilsContract = _collectionUtilsContract;
        managementFundContract = _managementFundContract;
    }

    function initPolicy(
        address _manager,
        address _operation,
        address _auditor,
        address _custodian,
        uint16 _totalPolicy,
        InitPolicy[] memory _policies
    ) public {
        require(!isInitPolicy);

        isInitPolicy = true;

        Manager storage manager = managers[0];
        manager.addr = _manager;
        manager.controlWeight = 10**6;
        managerMaxControlWeight = 10**6;
        totalManager = 1;
        managersAddress[_manager] = 0;

        Operation storage operation = operations[0];
        operation.addr = _operation;
        operation.controlWeight = 10**6;
        operationMaxControlWeight = 10**6;
        totalOperation = 1;
        operationsAddress[_operation] = 0;

        auditors[_auditor].approve = true;
        custodians[_custodian].approve = true;

        for (uint16 i = 0; i < _totalPolicy; i++) {
            Policy storage p = policies[
                stringToBytes32(_policies[i].policyName)
            ];
            p.policyWeight = _policies[i].policyWeight;
            p.maxWeight = _policies[i].maxWeight;
            p.voteDuration = _policies[i].voteDuration;
            p.effectiveDuration = _policies[i].effectiveDuration;
            p.minWeightOpenVote = _policies[i].minWeightOpenVote;
            p.minWeightValidVote = _policies[i].minWeightValidVote;
            p.minWeightApproveVote = _policies[i].minWeightApproveVote;
            p.policyValue = _policies[i].policyValue;
            p.decider = _policies[i].decider;
            p.exists = true;
            p.openVote = false;
        }
    }

    function stringToBytes32(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }

    function getARATokenContract() public view returns (address) {
        return araTokenContract;
    }

    function getBancorFormulaContract() public view returns (address) {
        return bancorFormulaContract;
    }

    function getMemberContract() public view returns (address) {
        return memberContract;
    }

    function getProposalContract() public view returns (address) {
        return proposalContract;
    }
    
    function getNFTFactoryContract() public view returns (address) {
        return nftFactoryContract;
    }

    function getNFTUtilsContract() public view returns (address) {
        return nftUtilsContract;
    }

    function getCollectionFactoryContract() public view returns (address) {
        return collectionFactoryContract;
    }

    function getCollectionUtilsContract() public view returns (address) {
        return collectionUtilsContract;
    }

    function getManagementFundContract() public view returns (address) {
        return managementFundContract;
    }

    function getManager(uint16 index)
        public
        view
        returns (Manager memory manager)
    {
        return managers[index];
    }

    function getManagerByAddress(address addr)
        public
        view
        returns (Manager memory manager)
    {
        return managers[managersAddress[addr]];
    }

    function getTotalManager() public view returns (uint16) {
        return totalManager;
    }

    function getManagerMaxControlWeight() public view returns (uint256) {
        return managerMaxControlWeight;
    }

    function getOperation(uint16 index)
        public
        view
        returns (Operation memory operation)
    {
        return operations[index];
    }

    function getOperationByAddress(address addr)
        public
        view
        returns (Operation memory operation)
    {
        return operations[operationsAddress[addr]];
    }
    
    function getTotalOperation() public view returns (uint16) {
        return totalOperation;
    }

    function getOperationMaxControlWeight() public view returns (uint256) {
        return operationMaxControlWeight;
    }

    function getPolicy(string memory policyName)
        public
        view
        returns (Policy memory policy)
    {
        return policies[stringToBytes32(policyName)];
    }

    function getPolicyByIndex(bytes32 policyIndex)
        public
        view
        returns (Policy memory policy)
    {
        return policies[policyIndex];
    }

    function isManager(address addr) public view returns (bool) {
        if (
            managersAddress[addr] != 0 &&
            managers[managersAddress[addr]].addr == addr
        ) return true;
        else if (managers[0].addr == addr) return true;
        else return false;
    }

    function isOperation(address addr) public view returns (bool) {
        if (
            operationsAddress[addr] != 0 &&
            operations[operationsAddress[addr]].addr == addr
        ) return true;
        else if (operations[0].addr == addr) return true;
        else return false;
    }

    function isAuditor(address addr) public view returns (bool) {
        return auditors[addr].approve;
    }

    function isCustodian(address addr) public view returns (bool) {
        return custodians[addr].approve;
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
    ) public {
        require(msg.sender == proposalContract);

        Policy storage p = policies[policyIndex];

        p.policyWeight = policyWeight;
        p.maxWeight = maxWeight;
        p.voteDuration = voteDuration;
        p.minWeightOpenVote = minWeightOpenVote;
        p.minWeightValidVote = minWeightValidVote;
        p.minWeightApproveVote = minWeightApproveVote;
        p.policyValue = policyValue;
        p.decider = decider;
        p.openVote = false;
    }

    function setManagerAtIndexByProposal(
        uint16 _totalManager,
        uint16 managerIndex,
        address addr,
        uint256 controlWeight,
        uint256 maxWeight,
        string memory dataURI
    ) public {
        require(msg.sender == proposalContract);

        totalManager = _totalManager;

        managers[managerIndex].addr = addr;
        managers[managerIndex].controlWeight = controlWeight;
        managers[managerIndex].dataURI = dataURI;
        managersAddress[addr] = managerIndex;
        managerMaxControlWeight = maxWeight;
    }
    
    function setOperationAtIndexByProposal(
        uint16 _totalOperation,
        uint16 operationIndex,
        address addr,
        uint256 controlWeight,
        uint256 maxWeight,
        string memory dataURI
    ) public {
        require(msg.sender == proposalContract);

        totalOperation = _totalOperation;

        operations[operationIndex].addr = addr;
        operations[operationIndex].controlWeight = controlWeight;
        operations[operationIndex].dataURI = dataURI;
        operationsAddress[addr] = operationIndex;
        operationMaxControlWeight = maxWeight;
    }

    function setAuditorByProposal(address addr, bool approve, string memory dataURI) public {
        require(msg.sender == proposalContract);

        auditors[addr].approve = approve;
        auditors[addr].dataURI = dataURI;
    }

    function setCustodianByProposal(address addr, bool approve, string memory dataURI) public {
        require(msg.sender == proposalContract);

        custodians[addr].approve = approve;
        custodians[addr].dataURI = dataURI;
    }
}
