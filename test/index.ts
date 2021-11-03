import { expect } from "chai";
import { ethers } from "hardhat";

describe("Hello", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Token = await ethers.getContractFactory("ARAToken");
    const token = await Token.deploy(123);
    await token.deployed();

    console.log("Token", token.address);
    console.log("Token Total Supply", (await token.totalSupply()).toString());
    console.log(
      "Token BalanceOf",
      (await token.balanceOf(token.address)).toString()
    );
    await token.mintMinerReward();

    console.log("Token Total Supply", (await token.totalSupply()).toString());
    console.log(
      "Token BalanceOf",
      (await token.balanceOf(token.address)).toString()
    );

    const [owner, addr1, addr2] = await ethers.getSigners();

    await token.transfer(addr1.address, 37);
    console.log(
      "addr1 balance",
      (await token.balanceOf(addr1.address)).toString()
    );

    await token.connect(addr1).transfer(addr2.address, 12);
    console.log(
      "addr2 balance",
      (await token.balanceOf(addr2.address)).toString()
    );
    console.log("Token Symbol", await token.symbol());
    console.log("Token Decimals", await token.decimals());
    await token.connect(addr1).mint(1533);
    console.log("totalSupply", (await token.totalSupply()).toString());
    console.log(
      "addr1 balance",
      (await token.balanceOf(addr1.address)).toString()
    );

    await token.connect(addr2).mint(5677);
    console.log("totalSupply", (await token.totalSupply()).toString());
    console.log(
      "addr2 balance",
      (await token.balanceOf(addr2.address)).toString()
    );

    await token.connect(addr2).burn(2323);
    console.log("totalSupply", (await token.totalSupply()).toString());
    console.log(
      "addr2 balance",
      (await token.balanceOf(addr2.address)).toString()
    );
  });
});
