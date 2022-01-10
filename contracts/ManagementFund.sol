pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";

contract ManagementFund {
    address private governanceContract;

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
    }

    function distributeFundToManagers() public {
        Governance g = Governance(governanceContract);
        ARAToken t = ARAToken(g.getARATokenContract());

        require(t.balanceOf(address(this)) > 0, "60");

        uint256 managementFund = t.balanceOf(address(this));
        for (uint16 i = 0; i < g.getTotalManager(); i++) {
            if (
                g.getManager(i).addr != address(0x0) &&
                g.getManager(i).controlWeight > 0
            ) {
                uint256 amount = (managementFund *
                    g.getManager(i).controlWeight) /
                    g.getManagerMaxControlWeight();
                t.transferFrom(address(this), g.getManager(i).addr, amount);
            }
        }
    }
}
