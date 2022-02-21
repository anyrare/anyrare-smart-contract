pragma solidity ^0.8.0;
pragma abicoder v2;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {LibUtils} from "../libraries/LibUtils.sol";

contract MemberFacet {
    AppStorage internal s;

    event CreateMember(address addr, address referral, string username);
    event UpdateMember(address addr, string username);

    function createMember(
        address addr,
        address referral,
        string memory username,
        string memory thumbnail
    ) external {
        require(
            msg.sender == addr &&
                s.member.members[addr].referral == address(0) &&
                s.member.members[referral].referral != address(0) &&
                s.member.usernames[LibUtils.stringToBytes32(username)] ==
                address(0),
            "MemberFacet: Failed to create member"
        );
        s.member.members[addr].referral = referral;
        s.member.members[addr].accountType = 0;
        s.member.members[addr].username = username;
        s.member.members[addr].thumbnail = thumbnail;
        s.member.usernames[LibUtils.stringToBytes32(username)] = addr;

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

    function isMember(address addr) external view returns (bool) {
        return s.member.members[addr].referral != address(0);
    }

    function getReferral(address addr) external view returns (address) {
        return s.member.members[addr].referral;
    }

    function getAddressByUsername(string memory username)
        external
        view
        returns (address)
    {
        return s.member.usernames[LibUtils.stringToBytes32(username)];
    }
}
