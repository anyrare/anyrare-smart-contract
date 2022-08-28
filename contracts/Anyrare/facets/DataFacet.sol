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
}
