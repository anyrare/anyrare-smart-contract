// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import "../libraries/LibData.sol";
import "../interfaces/IMember.sol";

contract DataFacet {
    AppStorage internal s;

    function isMember(address addr) external view returns (bool) {
        return LibData.isMember(s, addr);
    }

    function getReferral(address addr) external view returns (address) {
        return LibData.getReferral(s, addr);
    }

    function getAddressByUsername(string memory username)
        external
        view
        returns (address)
    {
        return LibData.getAddressByUsername(s, username);
    }

    function getMember(address addr)
        external
        view
        returns (IMember.MemberInfo memory m)
    {
        return LibData.getMember(s, addr);
    }

    function getManager(uint8 index)
        public
        view
        returns (GovernanceManager memory manager)
    {
        return LibData.getManager(s, index);
    }

    function getManagerByAddress(address addr)
        public
        view
        returns (GovernanceManager memory manager)
    {
        return LibData.getManagerByAddress(s, addr);
    }

    function getTotalManager() public view returns (uint16) {
        return LibData.getTotalManager(s);
    }

    function getManagerMaxControlWeight() public view returns (uint256) {
        return LibData.getManagerMaxControlWeight(s);
    }

    function isManager(address addr) public view returns (bool) {
        return LibData.isManager(s, addr);
    }

    function isAuditor(address addr) public view returns (bool) {
        return LibData.isAuditor(s, addr);
    }

    function isCustodian(address addr) public view returns (bool) {
        return LibData.isCustodian(s, addr);
    }
}
