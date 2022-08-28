// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import "../../shared/libraries/LibUtils.sol";
import "../interfaces/IMember.sol";

library LibData {
    function isMember(AppStorage storage s, address addr)
        external
        view
        returns (bool)
    {
        return s.member.members[addr].referral != address(0);
    }

    function getReferral(AppStorage storage s, address addr)
        external
        view
        returns (address)
    {
        return s.member.members[addr].referral;
    }

    function getAddressByUsername(AppStorage storage s, string memory username)
        external
        view
        returns (address)
    {
        return s.member.usernames[LibUtils.stringToBytes32(username)];
    }

    function getMember(AppStorage storage s, address addr)
        external
        view
        returns (IMember.MemberInfo memory m0)
    {
        IMember.MemberInfo memory m;

        m.addr = addr;
        m.referral = s.member.members[addr].referral;
        m.username = s.member.members[addr].username;
        m.thumbnail = s.member.members[addr].thumbnail;
        m.totalAsset = s.member.members[addr].totalAsset;
        m.totalBidAuction = s.member.members[addr].totalBidAuction;
        m.totalWonAuction = s.member.members[addr].totalWonAuction;
        m.totalFounderCollection = s
            .member
            .members[addr]
            .totalFounderCollection;
        m.totalOwnCollection = s.member.members[addr].totalOwnCollection;

        return m;
    }
}
