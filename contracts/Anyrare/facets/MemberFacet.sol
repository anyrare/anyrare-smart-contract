// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import {CollectionERC20} from "./CollectionERC20.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import "../../shared/libraries/LibUtils.sol";
import "../libraries/LibData.sol";
import "hardhat/console.sol";

contract MemberFacet {
    AppStorage internal s;

    event CreateMember(address addr, address referral, string username);
    event UpdateMember(address addr, string username);

    function initMember() external {
        require(
            s.member.totalMember == 0,
            "MemberFacet: Failed to init member"
        );
        createMember(msg.sender, msg.sender, "root", "");
    }

    function createMember(
        address addr,
        address referral,
        string memory username,
        string memory thumbnail
    ) public {
        require(
            (msg.sender == addr &&
                s.member.members[addr].referral == address(0) &&
                ((s.member.members[referral].referral != address(0) &&
                    addr != referral) || s.member.totalMember == 0) &&
                s.member.usernames[LibUtils.stringToBytes32(username)] ==
                address(0)),
            "MemberFacet: Failed to create member"
        );

        s.member.members[addr].addr = addr;
        s.member.members[addr].referral = referral;
        s.member.members[addr].accountType = 0;
        s.member.members[addr].username = username;
        s.member.members[addr].thumbnail = thumbnail;
        s.member.usernames[LibUtils.stringToBytes32(username)] = addr;
        s.member.totalMember += 1;

        emit CreateMember(addr, referral, username);
    }

    function updateMember(
        address addr,
        string memory username,
        string memory thumbnail
    ) external {
        require(
            msg.sender == addr &&
                (s.member.usernames[LibUtils.stringToBytes32(username)] ==
                    address(0) ||
                    s.member.usernames[LibUtils.stringToBytes32(username)] ==
                    addr),
            "MemberFacet: Failed to update member"
        );

        s.member.members[addr].thumbnail = thumbnail;

        if (
            LibUtils.stringToBytes32(s.member.members[addr].username) !=
            LibUtils.stringToBytes32(username)
        ) {
            s.member.usernames[
                LibUtils.stringToBytes32(s.member.members[addr].username)
            ] = address(0);
            s.member.usernames[LibUtils.stringToBytes32(username)] = addr;
            s.member.members[addr].username = username;
        }

        emit UpdateMember(addr, username);
    }
}
