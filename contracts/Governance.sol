pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
        uint32 minimumWeightOpenVote;
        uint32 minimumWeightValidVote;
        uint32 minimumWeightApproveVote;
        bool exists;
        bool isOpenVote;
        address currentProposal;
    }

    struct Voter {
        bool voted;
        bool approve;
    }

    struct Proposal {
        bytes8 policyIndex;
        bool isOpenVote;
        uint64 closeVoteUnixTimestamp;
        uint32 policyWeight;
        uint32 maxWeight;
        uint32 voteDurationSecond;
        uint32 minimumWeightOpenVote;
        uint32 minimumWeightValidVote;
        uint32 minimumWeightApproveVote;
        uint256 totalVoteToken;
        uint256 totalApproveToken;
        uint256 totalSupplyToken;
        bool voteResult;
        uint64 calculateResultTimestamp;
        mapping(address => Voter) voters;
    }

    address public memberContract;
    address public auctionContract;
    address public collectionContract;
    address public ARATokenContract;

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
    }

    function stringToBytes8(string memory str) private pure returns (bytes8) {
        bytes8 temp = 0x0;
        assembly {
            temp := mload(add(str, 32))
        }
        return temp;
    }

    function setMemberContract(address _memberContract) public {
        memberContract = _memberContract;
    }

    function getMemberContract() public view returns (address) {
        return memberContract;
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

    function isManager(address addr) public returns (bool) {
        for (uint16 i = 0; i < totalManager; i++) {
            if (managers[i].addr == addr && addr != address(0x0)) {
                return true;
            }
        }
        return false;
    }

    function initPolicy(string memory policyName, Policy memory v) public {
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
        p.policyWeight = v.policyWeight;
        p.maxWeight = v.maxWeight;
        p.voteDurationSecond = v.voteDurationSecond;
        p.minimumWeightOpenVote = v.minimumWeightOpenVote;
        p.minimumWeightValidVote = v.minimumWeightValidVote;
        p.minimumWeightApproveVote = v.minimumWeightApproveVote;
        p.isOpenVote = false;
    }

    function openProposal(string memory policyName, Policy memory v) public {
        bytes8 policyIndex = stringToBytes8(policyName);
        Policy memory p = policies[policyIndex];

        require(
            ERC20(ARATokenContract).balanceOf(msg.sender) >=
                (ERC20(ARATokenContract).totalSupply() *
                    p.minimumWeightOpenVote) /
                    p.maxWeight,
            "Error 3002: Insufficient token to open proposal."
        );
    }
}
