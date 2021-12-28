pragma solidity ^0.8.0;
pragma abicoder v2;

contract Governance {
    struct Manager {
        address addr;
        uint32 controlWeight;
        uint32 maxWeight;
    }

    struct Auditor {
        bool approve;
    }

    struct Custodian {
        bool approve;
    }

    struct Policy {
        uint32 policyWeight;
        uint32 maxWeight;
        uint32 voteDurationSecond;
        uint32 minWeightOpenVote;
        uint32 minWeightValidVote;
        uint32 minWeightApproveVote;
        uint256 policyValue;
        bool exists;
        bool openVote;
        address currentProposal;
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
        uint32 maxWeight;
        uint32 voteDurationSecond;
        uint32 minWeightOpenVote;
        uint32 minWeightValidVote;
        uint32 minWeightApproveVote;
        uint256 policyValue;
    }

    bool private isInitContractAddress;
    bool private isInitPolicy;
    address public memberContract;
    address public ARATokenContract;
    address public proposalContract;
    address public NFTFactoryContract;

    // TODO: add petty cash

    mapping(bytes8 => Policy) public policies;
    mapping(uint16 => Manager) public managers;
    mapping(address => Auditor) public auditors;
    mapping(address => Custodian) public custodians;

    uint16 public totalManager;

    constructor() public {
        Policy storage collateralWeight = policies[
            stringToBytes8("COLLATERAL_WEIGHT")
        ];
        collateralWeight.policyWeight = 400000;
        collateralWeight.maxWeight = 1000000;

        Manager storage m0 = managers[0];
        m0.addr = address(this);
        m0.controlWeight = 150;
        m0.maxWeight = 1000;
        totalManager = 1;

        isInitContractAddress = false;
        isInitPolicy = false;
    }

    function initContractAddress(
        address _memberContract,
        address _ARATokenContract,
        address _proposalContract,
        address _NFTFactoryContract
    ) public {
        require(
            !isInitContractAddress,
            "Error 3100: Already init contract address."
        );

        isInitContractAddress = true;
        memberContract = _memberContract;
        ARATokenContract = _ARATokenContract;
        proposalContract = _proposalContract;
        NFTFactoryContract = _NFTFactoryContract;
    }

    function initPolicy(
        address manager,
        address auditor,
        address custodian,
        InitPolicy[] memory policies
    ) public {
        require(!isInitPolicy, "Error 3101: Already init policy.");

        isInitPolicy = true;
    }

    function stringToBytes8(string memory str) public pure returns (bytes8) {
        bytes8 temp = 0x0;
        assembly {
            temp := mload(add(str, 32))
        }
        return temp;
    }

    function getARATokenContract() public view returns (address) {
        return ARATokenContract;
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

    function getManager(uint16 index)
        public
        view
        returns (Manager memory manager)
    {
        return managers[index];
    }

    function getTotalManager() public view returns (uint16) {
        return totalManager;
    }

    function getPolicy(string memory policyName)
        public
        view
        returns (Policy memory policy)
    {
        return policies[stringToBytes8(policyName)];
    }

    function getPolicyByIndex(bytes8 policyIndex)
        public
        view
        returns (Policy memory policy)
    {
        return policies[policyIndex];
    }

    function isManager(address addr) public view returns (bool) {
        for (uint16 i = 0; i < totalManager; i++) {
            if (managers[i].addr == addr && addr != address(0x0)) {
                return true;
            }
        }
        return false;
    }

    function isAuditor(address addr) public view returns (bool) {
        return auditors[addr].approve;
    }

    function isCustodian(address addr) public view returns (bool) {
        return custodians[addr].approve;
    }

    function initPolicy(
        string memory policyName,
        uint32 policyWeight,
        uint32 maxWeight,
        uint32 voteDurationSecond,
        uint32 minWeightOpenVote,
        uint32 minWeightValidVote,
        uint32 minWeightApproveVote,
        uint256 policyValue
    ) public {
        require(
            isManager(msg.sender),
            "Error 3000: No permission to init policy."
        );

        bytes8 policyIndex = stringToBytes8(policyName);
        require(
            !policies[policyIndex].exists,
            "Error 3001: This policy already exists."
        );

        Policy storage p = policies[policyIndex];
        p.exists = true;
        p.policyWeight = policyWeight;
        p.maxWeight = maxWeight;
        p.voteDurationSecond = voteDurationSecond;
        p.minWeightOpenVote = minWeightOpenVote;
        p.minWeightValidVote = minWeightValidVote;
        p.minWeightApproveVote = minWeightApproveVote;
        p.policyValue = policyValue;
        p.openVote = false;
    }

    function setPolicyByProposal(
        bytes8 policyIndex,
        address proposalAddress,
        uint32 policyWeight,
        uint32 maxWeight,
        uint32 voteDurationSecond,
        uint32 minWeightOpenVote,
        uint32 minWeightValidVote,
        uint32 minWeightApproveVote,
        uint256 policyValue
    ) public {
        require(
            msg.sender == proposalContract,
            "Error 3002: No permission to set policy."
        );

        Policy storage p = policies[policyIndex];

        require(
            proposalAddress == p.currentProposal,
            "Error 3003: Invalid proposal address."
        );

        p.policyWeight = policyWeight;
        p.maxWeight = maxWeight;
        p.voteDurationSecond = voteDurationSecond;
        p.minWeightOpenVote = minWeightOpenVote;
        p.minWeightValidVote = minWeightValidVote;
        p.minWeightApproveVote = minWeightApproveVote;
        p.policyValue = p.policyValue;
        p.openVote = false;
        p.currentProposal = address(0x0);
    }

    function setManagerAtIndexByProposal(
        uint16 _totalManager,
        uint16 managerIndex,
        address addr,
        uint32 controlWeight,
        uint32 maxWeight
    ) public {
        require(
            msg.sender == proposalContract,
            "Error 3004: No permission to set manager."
        );

        totalManager = _totalManager;

        managers[managerIndex].addr = addr;
        managers[managerIndex].controlWeight = controlWeight;
        managers[managerIndex].maxWeight = maxWeight;
    }

    function setAuditorByProposal(address addr, bool approve) public {
        require(
            msg.sender == proposalContract,
            "Error 3005: No permission to set auditor."
        );

        auditors[addr].approve = approve;
    }

    function setCustodianByProposal(address addr, bool approve) public {
        require(
            msg.sender == proposalContract,
            "Error 3006: No permission to set custodian."
        );

        custodians[addr].approve = approve;
    }
}
