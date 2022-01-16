import { expect } from "chai";

export const testDistributeManagementFund = async (
  ethers: any,
  araTokenContract: any,
  governanceContract: any,
  managementFundContract: any
) => {
  console.log("\n*** Test distribute management fund");

  const manager0 = (await governanceContract.getManager(0)).addr;
  const operation0 = (await governanceContract.getOperation(0)).addr;
  console.log(manager0, operation0);

  const contractBalance0 = +(await araTokenContract.balanceOf(
    managementFundContract.address
  ));
  const manager0Balance0 = +(await araTokenContract.balanceOf(manager0));
  const operation0Balance0 = +(await araTokenContract.balanceOf(operation0));
  console.log("Contract Balance", contractBalance0);

  await ethers.provider.send("evm_increaseTime", [86400000]);

  await managementFundContract.distributeFund();
  console.log("Distribute unlock fund");

  const contractBalance1 = +(await araTokenContract.balanceOf(
    managementFundContract.address
  ));
  const manager0Balance1 = +(await araTokenContract.balanceOf(manager0));
  const operation0Balance1 = +(await araTokenContract.balanceOf(operation0));

  console.log(
    "Balance: contract (before, after, diff)",
    contractBalance0,
    contractBalance1,
    contractBalance1 - contractBalance0
  );

  console.log(
    "Balance: manager0 (before, after, diff)",
    manager0Balance0,
    manager0Balance1,
    manager0Balance1 - manager0Balance0
  );

  console.log(
    "Balance: operation0 (before, after, diff)",
    operation0Balance0,
    operation0Balance1,
    operation0Balance1 - operation0Balance0
  );

  await managementFundContract.distributeLockupFund();
  console.log("Distribute lockup fund");

  const contractBalance2 = +(await araTokenContract.balanceOf(
    managementFundContract.address
  ));
  const manager0Balance2 = +(await araTokenContract.balanceOf(manager0));
  const operation0Balance2 = +(await araTokenContract.balanceOf(operation0));

  console.log(
    "Balance: contract (before, after, diff)",
    contractBalance1,
    contractBalance2,
    contractBalance2 - contractBalance1
  );

  console.log(
    "Balance: manager0 (before, after, diff)",
    manager0Balance1,
    manager0Balance2,
    manager0Balance2 - manager0Balance1
  );

  console.log(
    "Balance: operation0 (before, after, diff)",
    operation0Balance1,
    operation0Balance2,
    operation0Balance2 - operation0Balance1
  );
};
