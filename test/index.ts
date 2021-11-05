import { expect } from "chai";
import { ethers } from "hardhat";

describe("PolynomailCurvedToken", async () => {
  it("Initialize", async () => {
    const [owner, collateral] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("BondingCurvedToken");
    const token = await Token.deploy("Anyrare", "ARA", 18, collateral.address);

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

    await token.mint(3);
    console.log(
      "ownerBalance",
      (await token.balanceOf(owner.address)).toString()
    );
    console.log(
      "collateralBalance",
      (await token.balanceOf(collateral.address)).toString()
    );
  });
});
