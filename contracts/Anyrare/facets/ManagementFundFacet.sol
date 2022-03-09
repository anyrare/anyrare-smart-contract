// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IGovernance.sol";
import "../../shared/libraries/LibUtils.sol";
import {AppStorage, GovernanceManager, GovernanceFounder, GovernanceOperation, GovernancePolicy, PolicyProposalInfo, PolicyProposalIndex, PolicyProposal, ListProposalListInfo, ListProposal, GovernancePolicy, LockupFund, LockupFundList} from "../libraries/LibAppStorage.sol";
import "../libraries/LibData.sol";
import {ARAFacet} from "../../ARA/facets/ARAFacet.sol";
import "hardhat/console.sol";

contract ManagementFundFacet {
    AppStorage internal s;

    function calculateFounderFundPortion(uint256 totalFund, uint16 founderIndex)
        private
        view
        returns (uint256)
    {
        return
            (totalFund * LibData.getFounder(s, founderIndex).controlWeight) /
            LibData.getFounderMaxControlWeight(s);
    }

    function calculateValueFromPolicy(
        uint256 totalValue,
        string memory policyName
    ) private view returns (uint256) {
        return
            (totalValue * LibData.getPolicy(s, policyName).policyWeight) /
            LibData.getPolicy(s, policyName).maxWeight;
    }

    function distributeFund() public {
        require(
            block.timestamp >=
                s.managementFund.lastDistributeFundTimestamp +
                    LibData
                        .getPolicy(s, "MANAGEMENT_FUND_DISTRIBUTE_FUND_PERIOD")
                        .policyValue
        );

        s.managementFund.lastDistributeFundTimestamp = block.timestamp;

        uint256 _financingCashflow = LibData.getManagementFundValue(s) -
            s.managementFund.managementFundValue;
        uint256 founderCashflow = calculateValueFromPolicy(
            _financingCashflow,
            "MANAGEMENT_FUND_FOUNDER_WEIGHT"
        );
        uint256 financingCashflow = _financingCashflow - founderCashflow;
        uint256 operatingCashflow = LibData.araBalanceOf(s, address(this)) -
            _financingCashflow -
            s.managementFund.lockupFundValue;

        require(
            (financingCashflow + operatingCashflow) >=
                (LibData.getTotalManager(s) + LibData.getTotalOperation(s)) *
                    100
        );

        s.managementFund.managementFundValue = LibData.getManagementFundValue(
            s
        );
        uint256 buybackFund = calculateValueFromPolicy(
            operatingCashflow,
            "BUYBACK_WEIGHT"
        );

        uint256 lockupFinancingCashflow = calculateValueFromPolicy(
            financingCashflow,
            "FINANCING_CASHFLOW_LOCKUP_WEIGHT"
        );
        uint256 unlockupFinancingCashflow = financingCashflow -
            lockupFinancingCashflow;

        uint256 lockupFund = lockupFinancingCashflow;
        uint256 unlockupFund = unlockupFinancingCashflow +
            operatingCashflow -
            buybackFund;

        uint256 managementLockupFund = calculateValueFromPolicy(
            lockupFund,
            "MANAGEMENT_FUND_MANAGER_WEIGHT"
        );
        uint256 operationLockupFund = (lockupFund - managementLockupFund);

        uint256 managementUnlockupFund = calculateValueFromPolicy(
            unlockupFund,
            "MANAGEMENT_FUND_MANAGER_WEIGHT"
        );
        uint256 operationUnlockupFund = (unlockupFund - managementUnlockupFund);

        s.managementFund.lockupFundValue += lockupFund;

        if (buybackFund > 0) {
            ARAFacet(s.contractAddress.araToken).burn(buybackFund);
        }

        LockupFund storage lf = s.managementFund.lockupFunds[
            s.managementFund.totalLockupFundSlot
        ];

        lf.startingTotalARAValue = LibData.araCurrentTotalValue(s);
        lf.targetTotalARAValue =
            LibData.araCurrentTotalValue(s) *
            LibData
                .getPolicy(s, "FINANCING_CASHFLOW_LOCKUP_TARGET_VALUE_WEIGHT")
                .policyValue;
        lf.lastUnlockTotalARAValue = 0;
        lf.remainLockup = lockupFund;
        lf.totalLockup = lockupFund;
        lf.prevUnsettleLockupFundSlot = s.managementFund.totalLockupFundSlot ==
            0
            ? 0
            : s.managementFund.totalLockupFundSlot - 1;
        lf.nextUnsettleLockupFundSlot =
            s.managementFund.totalLockupFundSlot +
            1;
        s.managementFund.totalLockupFundSlot++;

        lf.totalList = 0;

        for (uint16 i; i < LibData.getTotalFounder(s); i++) {
            uint256 fund = calculateFounderFundPortion(founderCashflow, i);
            if (fund > 0) {
                ARAFacet(s.contractAddress.araToken).transfer(
                    LibData.getFounder(s, i).addr,
                    fund
                );
            }
        }

        for (uint16 i; i < LibData.getTotalManager(s); i++) {
            uint256 unlockupAmount = (managementUnlockupFund *
                LibData.getManager(s, i).controlWeight) /
                LibData.getManagerMaxControlWeight(s);
            uint256 lockupAmount = (managementLockupFund *
                LibData.getManager(s, i).controlWeight) /
                LibData.getManagerMaxControlWeight(s);

            if (unlockupAmount > 0) {
                ARAFacet(s.contractAddress.araToken).transfer(
                    LibData.getManager(s, i).addr,
                    unlockupAmount
                );
            }

            if (lockupAmount > 0) {
                lf.lists[lf.totalList] = LockupFundList({
                    addr: LibData.getManager(s, i).addr,
                    amount: lockupAmount
                });
                lf.totalList += 1;
            }
        }

        for (uint16 i; i < LibData.getTotalOperation(s); i++) {
            uint256 unlockupAmount = (operationUnlockupFund *
                LibData.getOperation(s, i).controlWeight) /
                LibData.getOperationMaxControlWeight(s);
            uint256 lockupAmount = (operationLockupFund *
                LibData.getOperation(s, i).controlWeight) /
                LibData.getOperationMaxControlWeight(s);

            if (unlockupAmount > 0) {
                ARAFacet(s.contractAddress.araToken).transfer(
                    LibData.getOperation(s, i).addr,
                    unlockupAmount
                );
            }

            if (lockupAmount > 0) {
                lf.lists[lf.totalList] = LockupFundList({
                    addr: LibData.getOperation(s, i).addr,
                    amount: lockupAmount
                });
                lf.totalList += 1;
            }
        }
    }

    function distributeLockupFund() public {
        require(
            block.timestamp >=
                s.managementFund.lastDistributeLockupFundTimestamp +
                    LibData
                        .getPolicy(
                            s,
                            "MANAGEMENT_FUND_DISTRIBUTE_LOCKUP_FUND_PERIOD"
                        )
                        .policyValue
        );

        s.managementFund.lastDistributeLockupFundTimestamp = block.timestamp;
        uint256 lastUnsettleLockupFundSlot = s
            .managementFund
            .firstUnsettleLockupFundSlot;

        for (
            uint256 i = s.managementFund.firstUnsettleLockupFundSlot;
            i < s.managementFund.totalLockupFundSlot;
            i++
        ) {
            LockupFund storage lf = s.managementFund.lockupFunds[i];
            uint256 currentTotalARAValue = LibData.araCurrentTotalValue(s);

            if (
                lf.remainLockup > 0 &&
                (
                    (currentTotalARAValue >=
                        lf.lastUnlockTotalARAValue +
                            (lf.lastUnlockTotalARAValue *
                                LibData
                                    .getPolicy(
                                        s,
                                        "FINANCING_CASHFLOW_LOCKUP_PARTIAL_UNLOCK_WEIGHT"
                                    )
                                    .policyWeight) /
                            LibData
                                .getPolicy(
                                    s,
                                    "FINANCING_CASHFLOW_LOCKUP_PARTIAL_UNLOCK_WEIGHT"
                                )
                                .maxWeight ||
                        currentTotalARAValue >= lf.targetTotalARAValue)
                )
            ) {
                uint256 unlockFund = LibUtils.min(
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

                for (uint16 j; j < lf.totalList; j++) {
                    ARAFacet(s.contractAddress.araToken).transfer(
                        lf.lists[j].addr,
                        ((lf.lists[j].amount * unlockFund) / lf.totalLockup)
                    );
                }
            }

            lf.prevUnsettleLockupFundSlot = lastUnsettleLockupFundSlot;

            if (lf.remainLockup == 0) {
                if (i == s.managementFund.firstUnsettleLockupFundSlot) {
                    s.managementFund.firstUnsettleLockupFundSlot = lf
                        .nextUnsettleLockupFundSlot;
                }
            } else {
                lastUnsettleLockupFundSlot = i;
            }
            i = lf.nextUnsettleLockupFundSlot - 1;
        }

        uint256 k = lastUnsettleLockupFundSlot;
        while (k >= s.managementFund.firstUnsettleLockupFundSlot) {
            if (s.managementFund.lockupFunds[k].remainLockup > 0) {
                s
                    .managementFund
                    .lockupFunds[k]
                    .nextUnsettleLockupFundSlot = lastUnsettleLockupFundSlot;
                lastUnsettleLockupFundSlot = k;
            }
            if (k == s.managementFund.firstUnsettleLockupFundSlot) {
                break;
            }
            k = s.managementFund.lockupFunds[k].prevUnsettleLockupFundSlot;
        }
    }
}
