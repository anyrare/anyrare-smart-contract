import { expect } from "chai";

export const testGenericBancorFormula = async (bancorFormulaContract: any) => {
  console.log("\n*** Bancor Formula Generic Function");

  const amount = 250 * 10 ** 8;
  const pAmount = +(await bancorFormulaContract.purchaseTargetAmount(
    1000 * 10 ** 8,
    1000 * 10 ** 8,
    300000,
    amount
  ));
  expect(pAmount).to.equal(6923459999);
  console.log("PurchaseTargetAmount: ", amount, pAmount);

  const sAmount = +(await bancorFormulaContract.saleTargetAmount(
    1000 * 10 ** 8 + pAmount,
    1000 * 10 ** 8 + amount,
    300000,
    pAmount
  ));
  expect(sAmount - amount <= 0).to.equal(true);
  console.log("SaleTargetAmount: ", pAmount, sAmount);

  const fAmount = +(await bancorFormulaContract.fundCost(
    1000 * 10 ** 8,
    1000 * 10 ** 8,
    300000,
    pAmount
  ));
  expect(fAmount).to.equal(amount);
  console.log("FundCost: ", pAmount, fAmount);

  const lAmount = +(await bancorFormulaContract.liquidateCost(
    1000 * 10 ** 8 + pAmount,
    1000 * 10 ** 8 + amount,
    300000,
    amount
  ));
  expect(lAmount).to.equal(pAmount);
  console.log("LiquidateCost: ", amount, pAmount);
};

export const testBancorFormulaForARA = async (
  araTokenContract: any,
  bancorFormulaContract: any,
  collateralTokenContract: any,
  root: any,
  user1: any,
  user2: any
) => {
  console.log("\n*** Bancor Formula");
  expect(
    +(await bancorFormulaContract.purchaseTargetAmount(200, 100, 400000, 500))
  ).to.equal(209);
  expect(
    +(await bancorFormulaContract.purchaseTargetAmount(409, 600, 400000, 500))
  ).to.equal(112);
  expect(
    +(await bancorFormulaContract.purchaseTargetAmount(
      10033333,
      104442323322300,
      10333,
      3283333332444444
    ))
  ).to.equal(367276);
  expect(
    +(await bancorFormulaContract.purchaseTargetAmount(
      2 ** 32,
      100,
      400000,
      100
    ))
  ).to.equal(1372276027);
  expect(
    +(await bancorFormulaContract.saleTargetAmount(200, 100, 400000, 50))
  ).to.equal(51);
  console.log("Test: PurchaseTargetAmount");
  console.log("Test: SaleTargetAmount");

  console.log("\n*** Collateral Token");
  await collateralTokenContract.mint(300000);
  expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
    1300000
  );
  console.log(
    "Mint: 300,000 wDAI to root, now root wallet have 1,300,000 wDAI"
  );
  await collateralTokenContract.mint(500000);
  expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
    1800000
  );
  console.log("Mint: 500,000 wDAI to root, now root wallet have 800,100 wDAI");
  expect(+(await collateralTokenContract.totalSupply())).to.equal(1800000);
  console.log("Total Supply for wDAI is 1,800,000");
  await collateralTokenContract.transfer(user1.address, 15000);
  console.log("Transfer: 15,000 wDAI from root to user1");
  await collateralTokenContract.transfer(araTokenContract.address, 100);
  console.log(
    "Transfer: 100 wDAI from root to ARATokenContract as a seed collateral"
  );
  expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
    1784900
  );
  console.log("Balance: root wallet is 785,000 wDAI");
  await collateralTokenContract.connect(user1).transfer(user2.address, 500);
  console.log("Transfer: 500 wDai from user1 to user2");
  expect(+(await collateralTokenContract.balanceOf(user1.address))).to.equal(
    14500
  );
  console.log("Balance: wDAI for user1 has remain 14,500 from 15,000");
  expect(+(await collateralTokenContract.balanceOf(user2.address))).to.equal(
    500
  );
  console.log("Balance: user2 has 500 wDAI");
  await expect(collateralTokenContract.connect(user1).mint(1000)).to.be
    .reverted;
  console.log(
    "User1 try to mint new wDAI but failed because of has no permission. Only root wallet can allow to mint new wDAI."
  );
};
