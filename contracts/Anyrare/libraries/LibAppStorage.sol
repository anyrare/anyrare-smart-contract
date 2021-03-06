// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";

struct MemberInfo {
    address addr;
    address referral;
    uint8 accountType;
    string username;
    string thumbnail;
    uint8 multiSigTotalAddress;
    uint8 multiSigTotalApprove;
    uint32 totalAsset;
    uint256 totalBidAuction;
    uint256 totalWonAuction;
    uint32 totalFounderCollection;
    uint32 totalOwnCollection;
    mapping(uint8 => address) multiSigAddresses;
    mapping(uint32 => uint256) assets;
}

struct Member {
    uint256 totalMember;
    mapping(address => MemberInfo) members;
    mapping(bytes32 => address) usernames;
}

struct CollectionTargetPriceVoteInfo {
    uint256 price;
    uint256 voteToken;
    bool vote;
    bool exists;
}

struct CollectionAuctionBid {
    uint256 timestamp;
    uint256 value;
    address bidder;
    bool autoRebid;
}

struct CollectionAuction {
    uint256 openAuctionTimestamp;
    uint256 closeAuctionTimestamp;
    address bidder;
    uint256 startingPrice;
    uint256 value;
    uint256 maxBid;
    uint256 maxWeight;
    uint256 nextBidWeight;
    uint32 totalBid;
}

struct CollectionInfo {
    address addr;
    address collector;
    string name;
    string symbol;
    string tokenURI;
    uint256 maxWeight;
    uint256 collateralWeight;
    uint256 collectorFeeWeight;
    uint256 dummyCollateralValue;
    uint32 totalAsset;
    uint32 totalShareholder;
    bool isAuction;
    bool isFreeze;
    uint256 targetPrice;
    uint256 targetPriceTotalSum;
    uint256 targetPriceTotalVoteToken;
    uint32 targetPriceTotalVoter;
    // uint32 targetPriceTotalVoterIndex;
}

struct Collection {
    mapping(uint256 => CollectionInfo) collections;
    mapping(address => uint256) collectionIndexes;
    mapping(uint256 => mapping(uint32 => uint256)) collectionAssets;
    mapping(uint32 => address) targetPriceVotersAddress;
    mapping(address => CollectionTargetPriceVoteInfo) targetPriceVotes;
    mapping(uint32 => CollectionAuctionBid) bids;
    mapping(address => uint32) shareholderIndexes;
    mapping(uint32 => address) shareholders;
    uint256 totalCollection;
}

struct CollectionStorage {
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => uint256) balances;
    address[] approvedContracts;
    mapping(address => uint256) approvedContractIndexes;
    bytes32[1000] emptyMapSlots;
    bool isInit;
    address owner;
    uint96 totalSupply;
    string name;
    string symbol;
    string tokenURI;
}

struct GovernanceFounder {
    address addr;
    uint256 controlWeight;
}

struct GovernanceManager {
    address addr;
    uint256 controlWeight;
    string dataURI;
}

struct GovernanceAuditor {
    bool approve;
    string dataURI;
}

struct GovernanceCustodian {
    bool approve;
    string dataURI;
}

struct GovernanceOperation {
    address addr;
    uint256 controlWeight;
    string dataURI;
}

struct GovernancePolicy {
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
    bool exists;
    bool openVote;
}

struct GovernanceVoter {
    bool voted;
    bool approve;
}

struct Governance {
    bool isInitContractAddress;
    bool isInitPolicy;
    uint16 totalFounder;
    uint16 totalManager;
    uint16 totalOperation;
    uint256 founderMaxControlWeight;
    uint256 managerMaxControlWeight;
    uint256 operationMaxControlWeight;
    mapping(bytes32 => GovernancePolicy) policies;
    mapping(uint16 => GovernanceFounder) founders;
    mapping(address => uint16) foundersAddress;
    mapping(uint16 => GovernanceManager) managers;
    mapping(address => uint16) managersAddress;
    mapping(uint16 => GovernanceOperation) operations;
    mapping(address => uint16) operationsAddress;
    mapping(address => GovernanceAuditor) auditors;
    mapping(address => GovernanceCustodian) custodians;
    mapping(uint16 => address) admins;
}

struct ContractAddress {
    address araToken;
    address assetToken;
}

struct ProposalVoter {
    bool voted;
    bool approve;
}

struct PolicyProposalIndex {
    bytes32 policyIndex;
    uint32 id;
    bool openVote;
    bool exists;
}

struct PolicyProposal {
    bool exists;
    PolicyProposalInfo info;
    mapping(uint32 => address) votersAddress;
    mapping(address => ProposalVoter) voters;
}

struct PolicyProposalInfo {
    bytes32 policyIndex;
    bool openVote;
    bool countVote;
    bool applyProposal;
    uint256 closeVoteTimestamp;
    uint256 policyWeight;
    uint256 maxWeight;
    uint32 voteDuration;
    uint32 effectiveDuration;
    uint256 minWeightOpenVote;
    uint256 minWeightValidVote;
    uint256 minWeightApproveVote;
    uint256 policyValue;
    uint8 decider;
    uint8 voteDecider;
    uint256 totalVoteToken;
    uint256 totalApproveToken;
    uint256 totalSupplyToken;
    bool voteResult;
    uint256 processResultTimestamp;
    uint32 totalVoter;
}

struct ListProposalListInfo {
    address addr;
    uint256 controlWeight;
    string dataURI;
}

struct ListProposalInfo {
    bytes32 policyIndex;
    bool openVote;
    bool countVote;
    bool applyProposal;
    bool voteValid;
    bool voteApprove;
    uint256 maxWeight;
    uint256 closeVoteTimestamp;
    uint256 totalVoteToken;
    uint256 totalApproveToken;
    uint256 totalSupplyToken;
    uint256 processResultTimestamp;
    uint32 totalVoter;
    uint16 totalList;
}

struct ListProposal {
    bool exists;
    ListProposalInfo info;
    mapping(uint32 => address) votersAddress;
    mapping(address => ProposalVoter) voters;
    mapping(uint16 => ListProposalListInfo) lists;
}

struct Proposal {
    uint32 policyProposalId;
    uint32 listProposalId;
    mapping(bytes32 => PolicyProposalIndex) policyProposalIndexes;
    mapping(uint32 => PolicyProposal) policyProposals;
    mapping(uint32 => ListProposal) listProposals;
}

struct LockupFundList {
    address addr;
    uint256 amount;
}

struct LockupFund {
    uint256 startingTotalARAValue;
    uint256 targetTotalARAValue;
    uint256 lastUnlockTotalARAValue;
    uint256 remainLockup;
    uint256 totalLockup;
    uint256 prevUnsettleLockupFundSlot;
    uint256 nextUnsettleLockupFundSlot;
    uint16 totalList;
    mapping(uint16 => LockupFundList) lists;
}

struct ManagementFund {
    uint256 managementFundValue;
    uint256 lockupFundValue;
    uint256 lastDistributeFundTimestamp;
    uint256 lastDistributeLockupFundTimestamp;
    uint256 totalLockupFundSlot;
    uint256 firstUnsettleLockupFundSlot;
    mapping(uint256 => LockupFund) lockupFunds;
}

struct AppStorage {
    address araToken;
    Member member;
    Collection collection;
    ContractAddress contractAddress;
    Governance governance;
    Proposal proposal;
    ManagementFund managementFund;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}
