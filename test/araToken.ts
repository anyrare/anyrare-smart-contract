import { expect } from "chai";

export const testMintARA = async (
  araTokenContract: any,
  collateralTokenContract: any,
  managementFundContract: any,
  user1: any,
  user2: any
) => {
  console.log("\n*** ARATokenContract");
  await expect(araTokenContract.connect(user2).mint(300)).to.be.reverted;
  console.log(
    "User3 try to mint new ARA token but failed because of is not a member."
  );
  await collateralTokenContract
    .connect(user1)
    .approve(araTokenContract.address, 2 ** 52);
  console.log(
    "User1 approve spending limit for ARATokenContract for 2 ** 52 wDAI."
  );
  expect(
    await collateralTokenContract
      .connect(user1)
      .allowance(user1.address, araTokenContract.address)
  ).to.equal(2 ** 52);
  console.log("Test: check spending limit for user1 to ARATokenContract.");
  expect(
    await collateralTokenContract.balanceOf(araTokenContract.address)
  ).to.equal(100);
  console.log(
    "Balance of wDAI for ARATokenContract as a collateral reserve is 100 wDAI."
  );
  console.log("\n**** Mint");
  expect(await araTokenContract.totalSupply()).to.equal(2 ** 32);
  const araTotalSupply0 = 2 ** 32;
  const araCollateral0 = +(await collateralTokenContract.balanceOf(
    araTokenContract.address
  ));
  await araTokenContract.connect(user1).mint(100);
  const araTotalSupply1 = +(await araTokenContract.totalSupply());
  const user1Balance0 = +(await araTokenContract.balanceOf(user1.address));
  const managementFundBalance0 = +(await araTokenContract.balanceOf(
    managementFundContract.address
  ));
  const araCollateral1 = +(await collateralTokenContract.balanceOf(
    araTokenContract.address
  ));
  console.log(
    "Balance: (user1, managementFund) ",
    user1Balance0,
    managementFundBalance0
  );
  console.log(
    "TotalSupply: (beforeMint, afterMint) ",
    araTotalSupply0,
    araTotalSupply1
  );
  expect(araTotalSupply1 - araTotalSupply0).to.equal(
    user1Balance0 + managementFundBalance0
  );
  console.log("Test: Increment supply = user1 + managementfund");
  expect(araCollateral1 - araCollateral0).to.equal(100);
  console.log(
    "Collateral: (beforeMint, afterMint) ",
    araCollateral0,
    araCollateral1
  );
};

export const testTransferARA = async (
  araTokenContract: any,
  user1: any,
  user2: any,
  user3: any
) => {
  console.log("\n**** Transfer");
  await araTokenContract.connect(user1).approve(user2.address, 2 ** 52);
  await araTokenContract.connect(user1).transfer(user2.address, 2 ** 16);
  expect(+(await araTokenContract.balanceOf(user2.address))).to.equal(2 ** 16);
  console.log("Test: transfer 2**16 ARA from user1 to user2");
  await araTokenContract.connect(user2).transfer(user3.address, 2 ** 4);
  expect(+(await araTokenContract.balanceOf(user3.address))).to.equal(2 ** 4);
  expect(+(await araTokenContract.balanceOf(user2.address))).to.equal(
    2 ** 16 - 2 ** 4
  );
  console.log("Test: transfer 2**4 ARA from user2 to user3");
  await araTokenContract.connect(user3).transfer(user1.address, 2 ** 2);
  console.log("Test: transfer 2**2 ARA from user3 to user1");
};

export const testWithdrawARA = async (
  araTokenContract: any,
  collateralTokenContract: any,
  managementFundContract: any,
  user1: any
) => {
  console.log("\n**** Withdraw");
  const user1CollateralBalance0 = +(await collateralTokenContract.balanceOf(
    user1.address
  ));
  const user1ARABalance0 = +(await araTokenContract.balanceOf(user1.address));
  const araTotalSupply0 = +(await araTokenContract.totalSupply());
  const araCollateralBalance0 = +(await collateralTokenContract.balanceOf(
    araTokenContract.address
  ));
  const managementFundBalance0 = +(await araTokenContract.balanceOf(
    managementFundContract.address
  ));
  await araTokenContract.connect(user1).withdraw(user1ARABalance0 / 3);
  const user1CollateralBalance1 = +(await collateralTokenContract.balanceOf(
    user1.address
  ));
  const user1ARABalance1 = +(await araTokenContract.balanceOf(user1.address));
  const araTotalSupply1 = +(await araTokenContract.totalSupply());
  const araCollateralBalance1 = +(await collateralTokenContract.balanceOf(
    araTokenContract.address
  ));
  const managementFundBalance1 = +(await araTokenContract.balanceOf(
    managementFundContract.address
  ));

  console.log(
    "User1 Collateral: (beforeWithdraw, afterWithdraw) ",
    user1CollateralBalance0,
    user1CollateralBalance1
  );
  console.log(
    "ARA Collateral: (beforeWithdraw, afterWithdraw) ",
    araCollateralBalance0,
    araCollateralBalance1
  );
  console.log(
    "User1 ARA: (beforeWithdraw, afterWithdraw, diff) ",
    user1ARABalance0,
    user1ARABalance1,
    user1ARABalance1 - user1ARABalance0
  );
  console.log(
    "ARA TotalSupply: (beforeWithdraw, afterWithdraw, diff) ",
    araTotalSupply0,
    araTotalSupply1,
    araTotalSupply1 - araTotalSupply0
  );
  console.log(
    "ManagmentFund ARA: (beforeWithdraw, afterWithdraw) ",
    managementFundBalance0,
    managementFundBalance1
  );
};

export const testBurnARA = async (
  araTokenContract: any,
  collateralTokenContract: any,
  bancorFormulaContract: any,
  user1: any
) => {
  console.log("\n**** Burn");
  const totalSupply0 = +(await araTokenContract.totalSupply());
  const user1Balance0 = +(await araTokenContract.balanceOf(user1.address));
  const collateral0 = +(await collateralTokenContract.balanceOf(
    araTokenContract.address
  ));
  const buyTarget0 = +(await bancorFormulaContract.purchaseTargetAmount(
    totalSupply0,
    collateral0,
    400000,
    3000
  ));
  await araTokenContract.connect(user1).burn(1000000);
  console.log("Burn: user1 burn 1000000");
  const totalSupply1 = +(await araTokenContract.totalSupply());
  const user1Balance1 = +(await araTokenContract.balanceOf(user1.address));
  const collateral1 = +(await collateralTokenContract.balanceOf(
    araTokenContract.address
  ));
  const buyTarget1 = +(await bancorFormulaContract.purchaseTargetAmount(
    totalSupply1,
    collateral1,
    400000,
    3000
  ));
  console.log(
    "Balance: user1 ",
    user1Balance0,
    user1Balance1,
    user1Balance1 - user1Balance0
  );
  console.log(
    "Balance: totalSupply ",
    totalSupply0,
    totalSupply1,
    totalSupply1 - totalSupply0
  );
  console.log(
    "Balance: collateral ",
    collateral0,
    collateral1,
    collateral1 - collateral0
  );
  console.log("Buy Target: ", buyTarget0, buyTarget1, buyTarget1 - buyTarget0);
};

export const distributeARAFromRootToUser = async (
  araTokenContract: any,
  root: any,
  user1: any,
  user2: any,
  user3: any,
  user4: any
) => {
  console.log("\n****Transfer token from root to user");
  await araTokenContract.connect(root).transfer(user1.address, 2 ** 32 / 4);
  await araTokenContract.connect(root).transfer(user2.address, 2 ** 32 / 4);
  await araTokenContract.connect(root).transfer(user3.address, 2 ** 32 / 4);
  await araTokenContract.connect(root).transfer(user4.address, 2 ** 32 / 16);
  const araTotalSupply = +(await araTokenContract.totalSupply());
  const rootBalance = +(await araTokenContract.balanceOf(root.address));
  const user1Balance = +(await araTokenContract.balanceOf(user1.address));
  const user2Balance = +(await araTokenContract.balanceOf(user2.address));
  const user3Balance = +(await araTokenContract.balanceOf(user3.address));
  const user4Balance = +(await araTokenContract.balanceOf(user4.address));

  console.log("Total ARA Supply: ", araTotalSupply);
  console.log("root: ", rootBalance);
  console.log("user1: ", user1Balance);
  console.log("user2: ", user2Balance);
  console.log("user3: ", user3Balance);
  console.log("user4: ", user4Balance);
};

export const testNoArbitrageMintAndWithdraw = async (
  araTokenContract: any,
  collateralTokenContract: any,
  user1: any
) => {
  console.log(
    "\n**** Test: No arbitrage opportunity to mint and withdraw instantly."
  );
  await collateralTokenContract
    .connect(user1)
    .approve(araTokenContract.address, 2 ** 52);

  const user1ARABalance0 = +(await araTokenContract.balanceOf(user1.address));
  const user1DAIBalance0 = +(await collateralTokenContract.balanceOf(
    user1.address
  ));
  console.log("Balance 0: (ARA, DAI)", user1ARABalance0, user1DAIBalance0);
  const fundCost = +(await araTokenContract
    .connect(user1)
    .calculateFundCost(1000));
  console.log("fundCost:", fundCost);

  await araTokenContract.connect(user1).mint(10000);
  const user1ARABalance1 = +(await araTokenContract.balanceOf(user1.address));
  const user1DAIBalance1 = +(await collateralTokenContract.balanceOf(
    user1.address
  ));

  await araTokenContract
    .connect(user1)
    .withdraw(user1ARABalance1 - user1ARABalance0);
  const user1ARABalance3 = +(await araTokenContract.balanceOf(user1.address));
  const user1DAIBalance3 = +(await collateralTokenContract.balanceOf(
    user1.address
  ));

  expect(user1DAIBalance3 - user1DAIBalance0 < 0).to.equal(true);
  expect(user1ARABalance3 - user1ARABalance0).to.equal(0);
  console.log("Test: after balance should less than before.");
};
