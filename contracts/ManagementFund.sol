pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";

contract ManagementFund {
    address private governanceContract;
    uint256 public managementFundValue;
    uint256 public lockupFundValue;
    uint256 public lastDistributeFundTimestamp;
    uint256 public totalLockupFundSlot;
    uint256 public totalUnsettleLockupFundSlot;
    uint256 public firstUnsettleLockupFundSlot;
    uint256 public lastUnsettleLockupFundSlot;

    struct LockupFundList {
        address addr;
        uint256 amount;
    }

    struct LockupFund {
        uint256 startingTotalARAValue;
        uint256 targetTotalARAValue;
        uint256 lastUnlockTotalARAValue;
        uint256 remainLockup;
        uint256 totalLockup;
        uint256 nextUnsettleLockupFundSlot;
        mapping(uint16 => LockupFundList) lists;
    }

    mapping(uint256 => LockupFund) lockupFunds;

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function t() private view returns (ARAToken) {
        return ARAToken(g().getARATokenContract());
    }

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
        lastDistributeFundTimestamp = block.timestamp;
    }

    function distributeFund() public {
        require(
            block.timestamp >=
                lastDistributeFundTimestamp +
                    g()
                        .getPolicy("MANAGEMENT_FUND_DISTRIBUTEFUND_PERIOD")
                        .policyValue
        );

        uint256 financingCashflow = t().getManagementFundValue() -
            managementFundValue;
        uint256 operatingCashflow = t().balanceOf(address(this)) -
            financingCashflow -
            lockupFundValue;
        managementFundValue = t().getManagementFundValue();
        uint256 buybackFund = (operatingCashflow *
            g().getPolicy("BUYBACK_WEIGHT").policyWeight) /
            g().getPolicy("BUYBACK_WEIGHT").maxWeight;

        uint256 lockupFinancingCashflow = (financingCashflow *
            g().getPolicy("FINANCING_CASHFLOW_LOCKUP_WEIGHT").policyWeight) /
            g().getPolicy("FINANCING_CASHFLOW_LOCKUP_WEIGHT").maxWeight;
        uint256 unlockupFinancingCashflow = financingCashflow -
            lockupFinancingCashflow;

        uint256 lockupFund = lockupFinancingCashflow;
        uint256 unlockupFund = unlockupFinancingCashflow +
            operatingCashflow -
            buybackFund;

        uint256 managementLockupFund = (lockupFund *
            g().getPolicy("MANAGEMENT_FUND_MANAGER_WEIGHT").policyWeight) /
            g().getPolicy("MANAGEMENT_FUND_MANAGER_WEIGHT").maxWeight;
        uint256 operationLockupFund = (lockupFund - managementLockupFund);

        uint256 managementUnlockupFund = (unlockupFund *
            g().getPolicy("MANAGEMENT_FUND_MANAGER_WEIGHT").policyWeight) /
            g().getPolicy("MANAGEMENT_FUND_MANAGER_WEIGHT").maxWeight;
        uint256 operationUnlockupFund = (unlockupFund - managementUnlockupFund);

        lockupFundValue += lockupFund;

        t().burn(buybackFund);

        LockupFund storage lf = lockupFunds[totalLockupFundSlot];

        lf.startingTotalARAValue = t().currentTotalValue();
        lf.targetTotalARAValue =
            t().currentTotalValue() *
            g()
                .getPolicy("FINANCING_CASHFLOW_UNLOCKUP_TARGET_VALUE_WEIGHT")
                .policyValue;
        lf.lastUnlockTotalARAValue = 0;
        lf.remainLockup = lockupFund;
        lf.totalLockup = lockupFund;
        lf.nextUnsettleLockupFundSlot = totalLockupFundSlot;
        totalLockupFundSlot++;

        uint16 lockupListIndex = 0;

        for (uint16 i = 0; i < g().getTotalManager(); i++) {
            t().transferFrom(
                address(this),
                g().getManager(i).addr,
                (managementUnlockupFund * g().getManager(i).controlWeight) /
                    g().getManagerMaxControlWeight()
            );

            lf.lists[lockupListIndex] = LockupFundList({
                addr: g().getManager(i).addr,
                amount: (managementLockupFund *
                    g().getManager(i).controlWeight) /
                    g().getManagerMaxControlWeight()
            });
            lockupListIndex += 1;
        }

        for (uint16 i = 0; i < g().getTotalOperation(); i++) {
            uint256 amount = (operationUnlockupFund *
                g().getOperation(i).controlWeight) /
                g().getOperationMaxControlWeight();
            t().transferFrom(
                address(this),
                g().getOperation(i).addr,
                (operationUnlockupFund * g().getOperation(i).controlWeight) /
                    g().getOperationMaxControlWeight()
            );

            lf.lists[lockupListIndex] = LockupFundList({
                addr: g().getOperation(i).addr,
                amount: (managementLockupFund *
                    g().getOperation(i).controlWeight) /
                    g().getOperationMaxControlWeight()
            });
            lockupListIndex += 1;
        }
    }
}

// TODO: Add developerment fund to support developer and infrastructure cost
// TODO: ARA from minting new token should be lock with x/y weight
// ARA that come from revenue can be freely transfer
// TODO: Before unlocked fund to developer and partner must be buyback
// TODO: Internal --> Developer (Employee) / 70, / 30 Partner (Founder, 45, 45, 10)
// Agency Problem: Employee, Manager, Owner
