// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMember {
    struct MemberInfo {
        address addr;
        address referral;
        string username;
        string thumbnail;
        uint256 totalAsset;
        uint256 totalBidAuction;
        uint256 totalWonAuction;
        uint256 totalFounderCollection;
        uint256 totalOwnCollection;
    }
}
