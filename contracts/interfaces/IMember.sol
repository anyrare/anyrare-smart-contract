pragma solidity ^0.8.0;

interface IMember {
    struct MemberInfo {
        address memberAddress;
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
    }
}
