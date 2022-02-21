pragma solidity ^0.8.0;

import {AppStorage, GovernancePolicy} from "../libraries/LibAppStorage.sol";
import {LibUtils} from "../libraries/LibUtils.sol";

library LibGovernance {
    function getPolicy(AppStorage storage s, string memory policyName)
        internal
        view
        returns (GovernancePolicy memory p)
    {
        s.governance.policies[LibUtils.stringToBytes32(policyName)];
    }

    function getPolicyByIndex(AppStorage storage s, bytes32 policyIndex)
        internal
        view
        returns (GovernancePolicy memory p)
    {
        s.governance.policies[policyIndex];
    }
}
