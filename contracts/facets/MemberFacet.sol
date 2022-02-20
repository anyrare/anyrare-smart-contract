pragma solidity ^0.8.0;
pragma abicoder v2;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {LibUtils} from "../libraries/LibUtils.sol";

contract MemberFacet {
    AppStorage internal s;

    function setMember(
        address addr,
        address referral,
        string memory username,
        string memory thumbnail
    ) external {
        // require(
        //     msg.sender == addr &&
        //         members[addr].referral == address(0) &&
        //         members[referral].referral != address(0) &&
        //         usernames[stringToBytes32(username)] == address(0)
        // );
        // MemberInfo storage m = members[addr];
        // m.referral = referral;
        // m.username = username;
        // m.thumbnail = thumbnail;

        s.member.usernames[LibUtils.stringToBytes32(username)] = addr;
    }

    // function updateMember(
    //     address addr,
    //     string memory username,
    //     string memory thumbnail
    // ) public {
    //     require(msg.sender == addr && (usernames[stringToBytes32(username)] == address(0) || usernames[stringToBytes32(username)] == addr));

    //     MemberInfo storage m = members[addr];
    //     m.thumbnail = thumbnail;

    //     if (stringToBytes32(m.username) != stringToBytes32(username)) {
    //         usernames[stringToBytes32(m.username)] = address(0);
    //         usernames[stringToBytes32(username)] = addr;
    //         m.username = username;
    //     }
    // }

    // function isMember(address addr) public view returns (bool) {
    //     return members[addr].referral != address(0);
    // }

    // function getReferral(address addr) public view returns (address) {
    //     return members[addr].referral;
    // }

    // function getAddressByUsername(string memory username) public view returns (address) {
    //     return usernames[stringToBytes32(username)];
    // }
}
