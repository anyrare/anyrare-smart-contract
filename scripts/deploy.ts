// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  const [owner, collateral, wallet1] = await ethers.getSigners();

  const Token = await ethers.getContractFactory("ARAToken");
  const token = await Token.deploy(
    "Anyrare",
    "ARA",
    510000,
    collateral.address
  );
  console.log("Token", token.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
