pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";

contract ManagementFund {
    address private governanceContract;
    uint256 public totalRestrictFund;

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function t() private view returns (ARAToken) {
        return ARAToken(g().getARATokenContract());
    }

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
        totalRestrictFund = 0;
    }

    function increaseTotalRestrictFund(uint256 restrictFund) public {
        totalRestrictFund += restrictFund;
    }

    function distributeUnrestrictFund() public {
        require(
            t().balanceOf(address(this)) > 0 &&
                t().balanceOf(address(this)) > totalRestrictFund
        );

        uint256 totalFund = t().balanceOf(address(this)) - totalRestrictFund;
        uint256 buybackFund = (totalFund *
            g().getPolicy("BUYBACK_WEIGHT").policyWeight) /
            g().getPolicy("BUYBACK_WEIGHT").maxWeight;
        uint256 managementFund = ((totalFund - buybackFund) *
            g().getPolicy("MANAGEMENT_FUND_MANAGER_WEIGHT").policyWeight) /
            g().getPolicy("MANAGEMENT_FUND_MANAGER_WEIGHT").maxWeight;
        uint256 operationFund = totalFund - buybackFund - managementFund;

        t().burn(buybackFund);

        for (uint16 i = 0; i < g().getTotalManager(); i++) {
            if (g().getManager(i).addr != address(0x0)) {
                uint256 amount = (managementFund *
                    g().getManager(i).controlWeight) /
                    g().getManagerMaxControlWeight();
                t().transferFrom(address(this), g().getManager(i).addr, amount);
            }
        }

        for (uint16 i = 0; i < g().getTotalOperation(); i++) {
            if (g().getOperation(i).addr != address(0x0)) {
                uint256 amount = (operationFund *
                    g().getOperation(i).controlWeight) /
                    g().getOperationMaxControlWeight();
                t().transferFrom(
                    address(this),
                    g().getOperation(i).addr,
                    amount
                );
            }
        }
    }
}

// TODO: Add developerment fund to support developer and infrastructure cost
// TODO: ARA from minting new token should be lock with x/y weight
// ARA that come from revenue can be freely transfer
// TODO: Before unlocked fund to developer and partner must be buyback
// TODO: Internal --> Developer (Employee) / 70, / 30 Partner (Founder, 45, 45, 10)
// Agency Problem: Employee, Manager, Owner
