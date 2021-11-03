import { expect } from "chai";
import { ethers } from "hardhat";

describe("Hello", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Hello");
    const greeter = await Greeter.deploy("Hello, world Bin!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world Bin!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");

    const Token = await ethers.getContractFactory("ARAToken");
    const token = await Token.deploy(12345);
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
  });
});
