import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ganache";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "solidity-coverage";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 50,
      },
    },
  },
  networks: {
    anyrare: {
      url: process.env.ANYRARE_NETWORK || "https://testnet.anyrare.network",
      accounts:
        process.env.ACCOUNT0_PRIVATE_KEY === undefined
          ? []
          : [
            process.env.ACCOUNT0_PRIVATE_KEY!,
            process.env.ACCOUNT1_PRIVATE_KEY!,
            process.env.ACCOUNT2_PRIVATE_KEY!,
            process.env.ACCOUNT3_PRIVATE_KEY!,
            process.env.ACCOUNT4_PRIVATE_KEY!,
            process.env.ACCOUNT5_PRIVATE_KEY!,
            process.env.ACCOUNT6_PRIVATE_KEY!,
            process.env.ACCOUNT7_PRIVATE_KEY!,
            process.env.ACCOUNT8_PRIVATE_KEY!,
            process.env.ACCOUNT9_PRIVATE_KEY!,
          ],
      gas: 21000000000,
      gasPrice: 1
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  mocha: {
    timeout: 180000,
  },
};

export default config;
