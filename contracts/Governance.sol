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
        uint32 voteDurationInSecond;
        uint32 minimumWeightToOpenVote;
        uint32 minimumWeightToValidVote;
        uint32 minimumWeightToApproveVote;
        bool exits;
        bool isOpenVote;
        address currentProposal;
    }

    struct Voter {
        bool voted;
        bool approve;
    }

    struct Proposal {
        bytes8 policyAddress;
        bool isOpenVote;
        uint64 closeVoteUnixTimestamp;
        uint32 policyWeight;
        uint32 maxWeight;
        uint32 voteDurationInSecond;
        uint32 minimumWeightToOpenVote;
        uint32 minimumWeightToValidVote;
        uint32 minimumWeightToApproveVote;
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
}
