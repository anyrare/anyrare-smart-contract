pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/LibAppStorage.sol";

library LibACL {
    function isMember(AppStorage storage s, address addr)
        internal
        view
        returns (bool)
    {
        return s.member.members[addr].addr != address(0);
    }

    function isManager(AppStorage storage s, address addr)
        internal
        view
        returns (bool)
    {
        if (
            s.governance.managersAddress[addr] != 0 &&
            s.governance.managers[s.governance.managersAddress[addr]].addr ==
            addr
        ) return true;
        else if (s.governance.managers[0].addr == addr) return true;
        else return false;
    }

    function isOperation(AppStorage storage s, address addr)
        internal
        view
        returns (bool)
    {
        if (
            s.governance.operationsAddress[addr] != 0 &&
            s
                .governance
                .operations[s.governance.operationsAddress[addr]]
                .addr ==
            addr
        ) return true;
        else if (s.governance.operations[0].addr == addr) return true;
        else return false;
    }

    function isAuditor(AppStorage storage s, address addr)
        internal
        view
        returns (bool)
    {
        return s.governance.auditors[addr].approve;
    }

    function isCustodian(AppStorage storage s, address addr)
        internal
        view
        returns (bool)
    {
        return s.governance.custodians[addr].approve;
    }
}
