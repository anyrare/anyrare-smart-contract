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
    }

    address public memberContract;
    address public auctionContract;
    address public collectionContract;
    address public ARATokenContract;

    mapping(bytes8 => Policy) public policies;
    mapping(uint8 => Manager) public managers;
    mapping(address => Auditor) public auditors;
    mapping(address => Custodian) public custodians;

    constructor() public {
        Policy storage collateralWeight = policies[stringToBytes8("COLLATERAL_WEIGHT")];
        collateralWeight.policyWeight = 400000;
        collateralWeight.maxWeight = 1000000;
    }

    function stringToBytes8(string memory str) private pure returns(bytes8) {
        bytes8 temp = 0x0;
        assembly {
            temp:= mload(add(str, 32))
        }
        return temp;
    }

    function setMemberContract(address _memberContract) public {
        memberContract = _memberContract;
    }

    function getMemberContract() public view returns(address) {
        return memberContract;
    }

    function getManager(uint8 index) public view returns(Manager memory manager) {
        return managers[index];
    }

    function getPolicy(string memory policyName) public view returns (Policy memory policy) {
        return policies[stringToBytes8(policyName)];
    }
}
