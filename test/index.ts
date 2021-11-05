import { expect } from "chai";
import { ethers } from "hardhat";

describe("PolynomailCurvedToken", async () => {
  it("Initialize", async () => {
    const [owner, collateral, wallet1] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("BondingCurvedToken");
    const token = await Token.deploy(
      "Anyrare",
      "ARA",
      18,
      51,
      collateral.address
    );

    await owner.sendTransaction({
      to: token.address,
      value: 123,
    });

    console.log("tokenAddress", token.address);
    console.log("ownerAddress", owner.address);
    console.log(
      "tokenBalance",
      (await ethers.provider.getBalance(token.address)).toString()
    );
    console.log(
      "ownerBalance",
      (await token.balanceOf(owner.address)).toString()
    );
    console.log(
      "collateralBalance",
      (await token.balanceOf(collateral.address)).toString()
    );

    await token.mint(3);
    console.log(
      "ownerBalance",
      (await token.balanceOf(owner.address)).toString()
    );
    console.log(
      "collateralBalance",
      (await token.balanceOf(collateral.address)).toString()
    );

    await token.mint(3, {
      value: 300,
    });
    console.log(
      "ownerBalance",
      (await token.balanceOf(owner.address)).toString()
    );
    console.log(
      "collateralBalance",
      (await token.balanceOf(collateral.address)).toString()
    );
    console.log(
      "tokenBalance",
      (await ethers.provider.getBalance(token.address)).toString()
    );
  });
});
