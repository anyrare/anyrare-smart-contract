import { expect } from "chai";

const collectionTokenABI = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_governanceContract",
        type: "address",
      },
      {
        internalType: "address",
        name: "_collector",
        type: "address",
      },
      {
        internalType: "string",
        name: "_name",
        type: "string",
      },
      {
        internalType: "string",
        name: "_symbol",
        type: "string",
      },
      {
        internalType: "uint256",
        name: "_initialValue",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_maxWeight",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_collateralWeight",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_collectorFeeWeight",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
    ],
    name: "allowance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "auction",
    outputs: [
      {
        internalType: "uint256",
        name: "openAuctionTimestamp",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "closeAuctionTimestamp",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "bidder",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "startingPrice",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "maxWeight",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "nextBidWeight",
        type: "uint256",
      },
      {
        internalType: "uint32",
        name: "totalBid",
        type: "uint32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "bidValue",
        type: "uint256",
      },
    ],
    name: "bidAuction",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "burn",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "buy",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
      {
        internalType: "string",
        name: "policyName",
        type: "string",
      },
    ],
    name: "calculateFeeFromPolicy",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "calculateFundCost",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "calculateLiquidateCost",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "calculatePurchaseReturn",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "calculateSaleReturn",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "collateralWeight",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "collector",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "collectorFeeWeight",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "currentCollateral",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "currentValue",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "decimals",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "subtractedValue",
        type: "uint256",
      },
    ],
    name: "decreaseAllowance",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "dummyCollateralValue",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "addedValue",
        type: "uint256",
      },
    ],
    name: "increaseAllowance",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "x",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "y",
        type: "uint256",
      },
    ],
    name: "max",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "maxWeight",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "x",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "y",
        type: "uint256",
      },
    ],
    name: "min",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_collector",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_initialAmount",
        type: "uint256",
      },
      {
        internalType: "uint32",
        name: "_totalNft",
        type: "uint32",
      },
      {
        internalType: "uint256[]",
        name: "_nfts",
        type: "uint256[]",
      },
    ],
    name: "mint",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "openAuction",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "processAuction",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "sell",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "price",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "vote",
        type: "bool",
      },
    ],
    name: "setTargetPrice",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "targetPrice",
    outputs: [
      {
        internalType: "uint256",
        name: "price",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "totalSum",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "totalVoteToken",
        type: "uint256",
      },
      {
        internalType: "uint32",
        name: "totalVoter",
        type: "uint32",
      },
      {
        internalType: "uint32",
        name: "totalVoterIndex",
        type: "uint32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalNft",
    outputs: [
      {
        internalType: "uint32",
        name: "",
        type: "uint32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "transfer",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "sender",
        type: "address",
      },
      {
        internalType: "address",
        name: "recipient",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export const testCreateCollection = async (
  ethers: any,
  nftFactoryContract: any,
  collectionFactoryContract: any,
  araTokenContract: any,
  memberContract: any,
  governanceContract: any,
  user1: any,
  user2: any,
  user3: any,
  user4: any,
  auditor: any,
  custodian: any
) => {
  console.log("\n*** Collection");

  const nfts = [];

  for (let i = 0; i < 4; i++) {
    await nftFactoryContract
      .connect(auditor)
      .mint(
        user1.address,
        custodian.address,
        "https://example/metadata.json",
        1000000,
        100000,
        300000,
        3500,
        1000
      );

    const tokenId = +(await nftFactoryContract
      .connect(user1)
      .getCurrentTokenId());
    nfts.push(tokenId);
    await nftFactoryContract
      .connect(custodian)
      .custodianSign(tokenId, 25000, 130430, 25000);

    await nftFactoryContract.connect(user1).payFeeAndClaimToken(tokenId);
  }

  console.log("Mint: 4 nfts", nfts);

  await nftFactoryContract
    .connect(user1)
    .setApprovalForAll(collectionFactoryContract.address, true);

  // const bnBase10 = ethers.BigNumber.from(10);
  const collateralWeight = 600000;
  const initialValue = 100000;
  await collectionFactoryContract.connect(user1).mint(
    "LP Collection 001",
    "cARA1",
    initialValue,
    // bnBase10.pow(ethers.BigNumber.from(25)),
    ethers.BigNumber.from(1000000),
    ethers.BigNumber.from(collateralWeight),
    ethers.BigNumber.from(1000),
    4,
    nfts
  );
  console.log("Mint: Collection0");

  const collection0 = await collectionFactoryContract.collections(0);
  expect(await nftFactoryContract.ownerOf(nfts[0])).to.equal(collection0);
  expect(await nftFactoryContract.ownerOf(nfts[1])).to.equal(collection0);
  expect(await nftFactoryContract.ownerOf(nfts[2])).to.equal(collection0);
  expect(await nftFactoryContract.ownerOf(nfts[3])).to.equal(collection0);
  console.log("Test: owner of 4 nfts is collection0");
  console.log("Address: collection0", collection0);

  const collection0Contract = new ethers.Contract(
    collection0,
    collectionTokenABI,
    ethers.provider
  );
  const user1TokenBalance0 = +(await collection0Contract.balanceOf(
    user1.address
  ));
  console.log("Token Balance: user1", user1TokenBalance0);
  const collateralBalance0 = +(await araTokenContract.balanceOf(collection0));
  const collectionTotalSupply0 = +(await collection0Contract.totalSupply());
  console.log("Total Supply:", collectionTotalSupply0);
  const collectionCollateral0 =
    +(await collection0Contract.currentCollateral());
  const collectionCurrentPrice0 =
    collectionCollateral0 / collectionTotalSupply0;
  const collectionCurrentValue0 = +(await collection0Contract.currentValue());
  expect(collateralBalance0).to.equal(0);
  expect(collectionTotalSupply0).to.equal(
    (initialValue * collateralWeight) / 1000000
  );
  expect(+(await collection0Contract.balanceOf(user1.address))).to.equal(
    (initialValue * collateralWeight) / 1000000
  );
  expect(+(await collection0Contract.collateralWeight())).to.equal(
    collateralWeight
  );
  expect(collectionCollateral0).to.equal(
    (initialValue * collateralWeight) / 1000000
  );
  console.log("Price: 1 collection share = ARA", collectionCurrentPrice0);
  console.log("Info: total supply, balanceOf");
  console.log("\n**** Test buy collection");

  console.log("Current Value:", collectionCurrentValue0);
  console.log(
    "Value: (user1)",
    (collectionCurrentValue0 * user1TokenBalance0) / collectionTotalSupply0
  );

  console.log("Buy: user2 buy 15000 ARA");
  await araTokenContract
    .connect(user2)
    .approve(collection0Contract.address, 2 ** 52);
  await collection0Contract.connect(user2).buy(15000);
  const collectionTotalSupply1 = +(await collection0Contract.totalSupply());
  console.log("Total Supply: after user 2 buy", collectionTotalSupply1);
  const user2TokenBalance0 = +(await collection0Contract.balanceOf(
    user2.address
  ));
  console.log("Token Balance: user2", user2TokenBalance0);
  const collectionTotalValue1 = +(await collection0Contract.currentValue());
  console.log("Current Value:", collectionTotalValue1);
  console.log(
    "Value: (user1, user2)",
    (collectionTotalValue1 * user1TokenBalance0) / collectionTotalSupply1,
    (collectionTotalValue1 * user2TokenBalance0) / collectionTotalSupply1
  );

  console.log("Buy: user3 buy 15000 ARA");
  await araTokenContract
    .connect(user3)
    .approve(collection0Contract.address, 2 ** 52);
  await collection0Contract.connect(user3).buy(15000);
  const collectionTotalSupply2 = +(await collection0Contract.totalSupply());
  console.log("Total Supply: after user 3 buy", collectionTotalSupply2);
  const user3TokenBalance0 = +(await collection0Contract.balanceOf(
    user3.address
  ));
  console.log("Token Balance: user3", user3TokenBalance0);
  const collectionTotalValue2 = +(await collection0Contract.currentValue());
  console.log("Current Value:", collectionTotalValue2);
  console.log(
    "Value: (user1, user2, user3)",
    (collectionTotalValue2 * user1TokenBalance0) / collectionTotalSupply2,
    (collectionTotalValue2 * user2TokenBalance0) / collectionTotalSupply2,
    (collectionTotalValue2 * user3TokenBalance0) / collectionTotalSupply2
  );

  console.log("Buy: user4 buy 15000 ARA");
  await araTokenContract
    .connect(user4)
    .approve(collection0Contract.address, 2 ** 52);
  await collection0Contract.connect(user4).buy(15000);
  const collectionTotalSupply3 = +(await collection0Contract.totalSupply());
  console.log("Total Supply: after user 4 buy", collectionTotalSupply3);
  const user4TokenBalance0 = +(await collection0Contract.balanceOf(
    user4.address
  ));
  console.log("Token Balance: user4", user4TokenBalance0);
  console.log(
    "Collateral Balance: (ara, ara + dummy)",
    +(await araTokenContract.balanceOf(collection0)),
    +(await collection0Contract.currentCollateral())
  );
  const collectionTotalValue3 = +(await collection0Contract.currentValue());
  console.log("Current Value:", collectionTotalValue3);
  console.log(
    "Value: (user1, user2, user3, user4)",
    (collectionTotalValue3 * user1TokenBalance0) / collectionTotalSupply3,
    (collectionTotalValue3 * user2TokenBalance0) / collectionTotalSupply3,
    (collectionTotalValue3 * user3TokenBalance0) / collectionTotalSupply3,
    (collectionTotalValue3 * user4TokenBalance0) / collectionTotalSupply3
  );

  console.log("\n**** Test sell collection");
  const user2TokenBalance2 = +(await collection0Contract.balanceOf(
    user2.address
  ));
  const user2SellAmount4 = +(await collection0Contract.calculateLiquidateCost(
    15000
  ));
  console.log(
    "Calculate: inputCollectionToken -> 15000 ARA output,",
    user2SellAmount4
  );
  const user2CollateralBalance4 = +(await araTokenContract.balanceOf(
    user2.address
  ));
  await collection0Contract
    .connect(user2)
    .approve(collection0Contract.address, 2 ** 52);
  await collection0Contract.connect(user2).sell(user2SellAmount4);
  console.log("Sell: user2 sell", user2SellAmount4);
  const user2CollateralBalance5 = +(await araTokenContract.balanceOf(
    user2.address
  ));
  const user2TokenBalance3 = +(await collection0Contract.balanceOf(
    user2.address
  ));
  console.log(
    "Balance ARA: user2 receive",
    user2CollateralBalance5 - user2CollateralBalance4
  );
  console.log(
    "Remain Token: (before, after, sell)",
    user2TokenBalance2,
    user2TokenBalance3,
    user2TokenBalance3 - user2TokenBalance2
  );

  console.log("Check value after user2 sell");

  const collectionTotalSupply4 = +(await collection0Contract.totalSupply());
  const collectionTotalValue4 = +(await collection0Contract.currentValue());

  const user1TokenBalance4 = +(await collection0Contract.balanceOf(
    user1.address
  ));
  const user2TokenBalance4 = +(await collection0Contract.balanceOf(
    user2.address
  ));
  const user3TokenBalance4 = +(await collection0Contract.balanceOf(
    user3.address
  ));
  const user4TokenBalance4 = +(await collection0Contract.balanceOf(
    user4.address
  ));
  console.log(
    "Current: (value, supply)",
    collectionTotalValue4,
    collectionTotalSupply4
  );
  console.log(
    "Value: (user1, user2, user3, user4)",
    (collectionTotalValue4 * user1TokenBalance4) / collectionTotalSupply4,
    (collectionTotalValue4 * user2TokenBalance4) / collectionTotalSupply4,
    (collectionTotalValue4 * user3TokenBalance4) / collectionTotalSupply4,
    (collectionTotalValue4 * user4TokenBalance4) / collectionTotalSupply4
  );

  const fundCost0 = +(await collection0Contract.calculateFundCost(7420));
  console.log("Test: fundCost for 7420 token is", fundCost0, "ARA");

  await collection0Contract.connect(user2).buy(15002);
  const user2TokenBalance5 = +(await collection0Contract.balanceOf(
    user2.address
  ));
  console.log(
    "Balance: (before, after, diff)",
    user2TokenBalance4,
    user2TokenBalance5,
    user2TokenBalance5 - user2TokenBalance4
  );

  console.log("\n**** Burn");
  const collectionTotalSupply6 = +(await collection0Contract.totalSupply());
  const collectionTotalValue6 = +(await collection0Contract.currentValue());
  const collateralBalance6 = +(await araTokenContract.balanceOf(collection0));
  const amountBuy6 = +(await collection0Contract.calculatePurchaseReturn(
    10000
  ));
  await collection0Contract.connect(user2).burn(1000);
  console.log("Burn: user2 burn 1000 token");
  const collectionTotalSupply7 = +(await collection0Contract.totalSupply());
  const collectionTotalValue7 = +(await collection0Contract.currentValue());
  const collateralBalance7 = +(await araTokenContract.balanceOf(collection0));
  const amountBuy7 = +(await collection0Contract.calculatePurchaseReturn(
    10000
  ));
  console.log(
    "Total Supply: (before, after, diff)",
    collectionTotalSupply6,
    collectionTotalSupply7,
    collectionTotalSupply7 - collectionTotalSupply6
  );
  console.log(
    "Value: (before, after, diff)",
    collectionTotalValue6,
    collectionTotalValue7,
    collectionTotalValue7 - collectionTotalValue6
  );
  console.log(
    "Collateral: (befor, after, diff)",
    collateralBalance6,
    collateralBalance7,
    collateralBalance7 - collateralBalance6
  );
  console.log(
    "Amount Buy: (before, after, diff)",
    amountBuy6,
    amountBuy7,
    amountBuy7 - amountBuy6
  );

  console.log("\n**** User1 dump price");
};
