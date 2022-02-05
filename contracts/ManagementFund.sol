pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";

contract ManagementFund {
    address private governanceContract;
    uint256 public managementFundValue;
    uint256 public lockupFundValue;
    uint256 public lastDistributeFundTimestamp;
    uint256 public lastDistributeLockupFundTimestamp;
    uint256 public totalLockupFundSlot;
    uint256 public firstUnsettleLockupFundSlot;

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
        uint256 prevUnsettleLockupFundSlot;
        uint256 nextUnsettleLockupFundSlot;
        uint16 totalList;
        mapping(uint16 => LockupFundList) lists;
    }

    mapping(uint256 => LockupFund) lockupFunds;

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function t() private view returns (ARAToken) {
        return ARAToken(g().getARATokenContract());
    }

    function max(uint256 x, uint256 y) public view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) public view returns (uint256) {
        return x < y ? x : y;
    }

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
        lastDistributeFundTimestamp = block.timestamp;
    }

    function calculateFounderFundPortion(uint256 totalFund, uint16 founderIndex) private view returns (uint256) {
        return totalFund * g().getFounder(founderIndex).controlWeight / g().getFounderMaxControlWeight();
    }

    function calculateValueFromPolicy(uint256 totalValue, string memory policyName) private view returns (uint256) {
        return (totalValue * g().getPolicy(policyName).policyWeight)/g().getPolicy(policyName).maxWeight;
    }

    function distributeFund() public {
        require(
            block.timestamp >=
            lastDistributeFundTimestamp +
            g()
            .getPolicy("MANAGEMENT_FUND_DISTRIBUTE_FUND_PERIOD")
            .policyValue
        );

        lastDistributeFundTimestamp = block.timestamp;

        uint256 _financingCashflow = t().getManagementFundValue() -
        managementFundValue;
        uint256 founderCashflow = calculateValueFromPolicy(_financingCashflow, "MANAGEMENT_FUND_FOUNDER_WEIGHT");
        uint256 financingCashflow = _financingCashflow - founderCashflow;
        uint256 operatingCashflow = t().balanceOf(address(this)) -
        _financingCashflow -
        lockupFundValue;

        require(
            (financingCashflow + operatingCashflow) >=
            (g().getTotalManager() + g().getTotalOperation()) * 100
        );

        managementFundValue = t().getManagementFundValue();
        uint256 buybackFund = calculateValueFromPolicy(operatingCashflow, "BUYBACK_WEIGHT");

        uint256 lockupFinancingCashflow = calculateValueFromPolicy(financingCashflow, "FINANCING_CASHFLOW_LOCKUP_WEIGHT");
        uint256 unlockupFinancingCashflow = financingCashflow -
        lockupFinancingCashflow;

        uint256 lockupFund = lockupFinancingCashflow;
        uint256 unlockupFund = unlockupFinancingCashflow +
        operatingCashflow -
        buybackFund;

        uint256 managementLockupFund = calculateValueFromPolicy(lockupFund, "MANAGEMENT_FUND_MANAGER_WEIGHT");
        uint256 operationLockupFund = (lockupFund - managementLockupFund);

        uint256 managementUnlockupFund = calculateValueFromPolicy(unlockupFund, "MANAGEMENT_FUND_MANAGER_WEIGHT");
        uint256 operationUnlockupFund = (unlockupFund - managementUnlockupFund);

        lockupFundValue += lockupFund;

        if (buybackFund > 0) {
            t().burn(buybackFund);
        }

        LockupFund storage lf = lockupFunds[totalLockupFundSlot];

        lf.startingTotalARAValue = t().currentTotalValue();
        lf.targetTotalARAValue =
        t().currentTotalValue() *
        g()
        .getPolicy("FINANCING_CASHFLOW_LOCKUP_TARGET_VALUE_WEIGHT")
        .policyValue;
        lf.lastUnlockTotalARAValue = 0;
        lf.remainLockup = lockupFund;
        lf.totalLockup = lockupFund;
        lf.prevUnsettleLockupFundSlot = totalLockupFundSlot == 0
        ? 0
        : totalLockupFundSlot - 1;
        lf.nextUnsettleLockupFundSlot = totalLockupFundSlot + 1;
        totalLockupFundSlot++;

        lf.totalList = 0;

        for(uint16 i = 0; i < g().getTotalFounder(); i++) {
            uint256 fund = calculateFounderFundPortion(founderCashflow, i);
            if (fund > 0) {
                t().transfer(
                    g().getFounder(i).addr,
                    fund);
            }
        }

        for (uint16 i = 0; i < g().getTotalManager(); i++) {
            uint256 unlockupAmount = (managementUnlockupFund *
                                      g().getManager(i).controlWeight) /
                                     g().getManagerMaxControlWeight();
            uint256 lockupAmount = (managementLockupFund *
                                    g().getManager(i).controlWeight) /
                                   g().getManagerMaxControlWeight();

            if (unlockupAmount > 0) {
                t().transfer(
                    g().getManager(i).addr,
                    unlockupAmount
                );
            }

            if (lockupAmount > 0) {
                lf.lists[lf.totalList] = LockupFundList({
addr: g().getManager(i).addr,
amount: lockupAmount
                });
                lf.totalList += 1;
            }
        }

        for (uint16 i = 0; i < g().getTotalOperation(); i++) {
            uint256 unlockupAmount = (operationUnlockupFund *
                                      g().getOperation(i).controlWeight) /
                                     g().getOperationMaxControlWeight();
            uint256 lockupAmount = (operationLockupFund *
                                    g().getOperation(i).controlWeight) /
                                   g().getOperationMaxControlWeight();

            if (unlockupAmount > 0) {
                t().transfer(
                    g().getOperation(i).addr,
                    unlockupAmount
                );
            }

            if (lockupAmount > 0) {
                lf.lists[lf.totalList] = LockupFundList({
addr: g().getOperation(i).addr,
amount: lockupAmount
                });
                lf.totalList += 1;
            }
        }
    }

    function distributeLockupFund() public {
        require(
            block.timestamp >=
            lastDistributeLockupFundTimestamp +
            g()
            .getPolicy(
                "MANAGEMENT_FUND_DISTRIBUTE_LOCKUP_FUND_PERIOD"
            )
            .policyValue
        );

        lastDistributeLockupFundTimestamp = block.timestamp;
        uint256 lastUnsettleLockupFundSlot = firstUnsettleLockupFundSlot;

        for (
            uint256 i = firstUnsettleLockupFundSlot;
            i < totalLockupFundSlot;
            i++
        ) {
            LockupFund storage lf = lockupFunds[i];
            uint256 currentTotalARAValue = t().currentTotalValue();

            if (
                lf.remainLockup > 0 &&
                (
                    (currentTotalARAValue >=
                     lf.lastUnlockTotalARAValue +
                     (lf.lastUnlockTotalARAValue *
                      g()
                      .getPolicy(
                          "FINANCING_CASHFLOW_LOCKUP_PARTIAL_UNLOCK_WEIGHT"
                      )
                      .policyWeight) /
                     g()
                     .getPolicy(
                         "FINANCING_CASHFLOW_LOCKUP_PARTIAL_UNLOCK_WEIGHT"
                     )
                     .maxWeight ||
                     currentTotalARAValue >= lf.targetTotalARAValue)
                )
            ) {
                uint256 unlockFund = min(
                    lf.remainLockup,
                    currentTotalARAValue >= lf.targetTotalARAValue
                    ? lf.remainLockup
                    : (lf.totalLockup *
                       (currentTotalARAValue -
                        lf.lastUnlockTotalARAValue)) /
                    (lf.targetTotalARAValue - lf.startingTotalARAValue)
                );

                lf.remainLockup -= unlockFund;
                lf.lastUnlockTotalARAValue = currentTotalARAValue;

                for (uint16 j = 0; j < lf.totalList; j++) {
                    t().transfer(
                        lf.lists[j].addr,
                        ((lf.lists[j].amount * unlockFund) / lf.totalLockup)
                    );
                }
            }

            lf.prevUnsettleLockupFundSlot = lastUnsettleLockupFundSlot;

            if (lf.remainLockup == 0) {
                if (i == firstUnsettleLockupFundSlot) {
                    firstUnsettleLockupFundSlot = lf.nextUnsettleLockupFundSlot;
                }
            } else {
                lastUnsettleLockupFundSlot = i;
            }
            i = lf.nextUnsettleLockupFundSlot - 1;
        }

        uint256 k = lastUnsettleLockupFundSlot;
        while (k >= firstUnsettleLockupFundSlot) {
            if (lockupFunds[k].remainLockup > 0) {
                lockupFunds[k]
                .nextUnsettleLockupFundSlot = lastUnsettleLockupFundSlot;
                lastUnsettleLockupFundSlot = k;
            }
            if (k == firstUnsettleLockupFundSlot) {
                break;
            }
            k = lockupFunds[k].prevUnsettleLockupFundSlot;
        }
    }
}
