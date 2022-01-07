pragma solidity ^0.8.0;
pragma abicoder v2;

contract Governance {
    struct Manager {
        address addr;
        uint256 controlWeight;
    }

    struct Auditor {
        bool approve;
    }

    struct Custodian {
        bool approve;
    }

    struct Policy {
        uint256 policyWeight;
        uint256 maxWeight;
        uint32 voteDuration;
        uint32 timelockDuration;
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
        uint32 timelockDuration;
        uint256 minWeightOpenVote;
        uint256 minWeightValidVote;
        uint256 minWeightApproveVote;
        uint256 policyValue;
        uint8 decider;
    }

    bool private isInitContractAddress;
    bool private isInitPolicy;
    address private memberContract;
    address private ARATokenContract;
    address private bancorFormulaContract;
    address private proposalContract;
    address private NFTFactoryContract;
    address private NFTUtilsContract;
    address private managementFundContract;
    address private utilsContract;

    mapping(bytes32 => Policy) public policies;
    mapping(uint16 => Manager) public managers;
    mapping(address => uint16) public managersAddress;
    mapping(address => Auditor) public auditors;
    mapping(address => Custodian) public custodians;

    uint16 public totalManager;
    uint256 public managerMaxControlWeight;

    constructor() {
        isInitContractAddress = false;
        isInitPolicy = false;
    }

    function initContractAddress(
        address _memberContract,
        address _ARATokenContract,
        address _proposalContract,
        address _NFTFactoryContract,
        address _managementFundContract
    ) public {
        require(!isInitContractAddress, "30");

        isInitContractAddress = true;
        memberContract = _memberContract;
        ARATokenContract = _ARATokenContract;
        proposalContract = _proposalContract;
        NFTFactoryContract = _NFTFactoryContract;
        managementFundContract = _managementFundContract;
    }

    function initPolicy(
        address _manager,
        address _auditor,
        address _custodian,
        uint16 _totalPolicy,
        InitPolicy[] memory _policies
    ) public {
        require(!isInitPolicy, "31");

        isInitPolicy = true;

        Manager storage manager = managers[0];
        manager.addr = _manager;
        manager.controlWeight = 10**6;
        managerMaxControlWeight = 10**6;
        totalManager = 1;
        managersAddress[_manager] = 0;

        auditors[_auditor].approve = true;
        custodians[_custodian].approve = true;

        for (uint16 i = 0; i < _totalPolicy; i++) {
            Policy storage p = policies[
                stringToBytes32(_policies[i].policyName)
            ];
            p.policyWeight = _policies[i].policyWeight;
            p.maxWeight = _policies[i].maxWeight;
            p.voteDuration = _policies[i].voteDuration;
            p.minWeightOpenVote = _policies[i].minWeightOpenVote;
            p.minWeightValidVote = _policies[i].minWeightValidVote;
            p.minWeightApproveVote = _policies[i].minWeightApproveVote;
            p.decider = _policies[i].decider;
            p.exists = true;
            p.openVote = false;
        }
    }

    function stringToBytes32(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }

    function getARATokenContract() public view returns (address) {
        return ARATokenContract;
    }

    function getBancorFormulaContract() public view returns (address) {
        return bancorFormulaContract;
    }

    function getUtilsContract() public view returns (address) {
        return utilsContract;
    }

    function getMemberContract() public view returns (address) {
        return memberContract;
    }

    function getProposalContract() public view returns (address) {
        return proposalContract;
    }

    function getNFTFactoryContract() public view returns (address) {
        return NFTFactoryContract;
    }

    function getNFTUtilsContract() public view returns (address) {
        return NFTUtilsContract;
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
        require(msg.sender == proposalContract, "32");

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
        uint256 maxWeight
    ) public {
        require(msg.sender == proposalContract, "33");

        totalManager = _totalManager;

        managers[managerIndex].addr = addr;
        managers[managerIndex].controlWeight = controlWeight;
        managersAddress[addr] = managerIndex;
        managerMaxControlWeight = maxWeight;
    }

    function setAuditorByProposal(address addr, bool approve) public {
        require(msg.sender == proposalContract, "34");

        auditors[addr].approve = approve;
    }

    function setCustodianByProposal(address addr, bool approve) public {
        require(msg.sender == proposalContract, "35");

        custodians[addr].approve = approve;
    }
}
