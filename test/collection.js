const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");

describe("Test Asset Contract", async () => {
  let contract, root, user1, user2, user3, user4, auditor, custodian, collection0;

  before(async () => {
    [root, user1, user2, user3, user4, auditor, custodian] = await ethers.getSigners();
    contract = await deployContract();

    await contract.araFacet
      .connect(root)
      .transfer(user1.address, "5".repeat("24"));
    await contract.araFacet
      .connect(root)
      .transfer(user2.address, "5".repeat("24"));
    await contract.araFacet
      .connect(root)
      .transfer(user3.address, "5".repeat("24"));
    await contract.araFacet
      .connect(root)
      .transfer(user4.address, "5".repeat("24"));
  });

  it("should test function mintAssets", async () => {
    const tx0 = await contract.assetFactoryFacet.connect(auditor).mintAsset({
      founder: user1.address,
      custodian: custodian.address,
      tokenURI: "ipfs://metadata/123",
      maxWeight: 1000000,
      founderWeight: 100000,
      founderRedeemWeight: 300000,
      founderGeneralFee: 10000000,
      auditFee: 10000,
      custodianWeight: 10000,
      custodianRedeemWeight: 30000,
      custodianGeneralFee: 30000000,
    });
    await tx0.wait();

    const tx1 = await contract.assetFactoryFacet.connect(auditor).mintAsset({
      founder: user1.address,
      custodian: custodian.address,
      tokenURI: "ipfs://metadata/123",
      maxWeight: 1000000,
      founderWeight: 100000,
      founderRedeemWeight: 300000,
      founderGeneralFee: 10000000,
      auditFee: 10000,
      custodianWeight: 10000,
      custodianRedeemWeight: 30000,
      custodianGeneralFee: 30000000,
    });
    await tx1.wait();

    const tx2 = await contract.assetFactoryFacet.connect(auditor).mintAsset({
      founder: user1.address,
      custodian: custodian.address,
      tokenURI: "ipfs://metadata/123",
      maxWeight: 1000000,
      founderWeight: 100000,
      founderRedeemWeight: 300000,
      founderGeneralFee: 10000000,
      auditFee: 10000,
      custodianWeight: 10000,
      custodianRedeemWeight: 30000,
      custodianGeneralFee: 30000000,
    });
    await tx2.wait();

    await contract.assetFactoryFacet.connect(custodian).custodianSign(0);
    await contract.assetFactoryFacet.connect(custodian).custodianSign(1);
    await contract.assetFactoryFacet.connect(custodian).custodianSign(2);

    await contract.araFacet
      .connect(user1)
      .approve(contract.anyrareDiamond.address, 2 ** 52);
    await contract.assetFactoryFacet.connect(user1).payFeeAndClaimToken(0);
    await contract.assetFactoryFacet.connect(user1).payFeeAndClaimToken(1);
    await contract.assetFactoryFacet.connect(user1).payFeeAndClaimToken(2);

    const totalAsset = await contract.assetFacet.totalAsset();
    expect(totalAsset).equal(3);

    expect(await contract.assetFacet.ownerOf(0)).equal(user1.address);
    expect(await contract.assetFacet.ownerOf(1)).equal(user1.address);
    expect(await contract.assetFacet.ownerOf(2)).equal(user1.address);
  });

  it("should test function mint collection", async () => {
    await contract.collectionFactoryFacet.connect(user1).mintCollection({
      name: "Collection1",
      symbol: "CL1",
      tokenURI: "https://ipfs/demo.json",
      decimal: 5,
      precision: 3,
      totalSupply: 10000,
      maxWeight: 100000,
      collectorFeeWeight: 2500,
      totalAsset: 3,
      assets: [0, 1, 2],
    });

    collection0 = await contract.dataFacet.getCollectionByIndex(0);
    expect(collection0.symbol).equal("CL1");

    const result1 = await contract.dataFacet.getBalanceOfERC20(
      collection0.addr,
      collection0.collector
    );
    expect(result1).equal(collection0.totalSupply);
  });

  it("should test function buyLimit", async () => {
    const orderbooks = [
      {
        price: 13400,
        volume: 100,
      },
      {
        price: 13500,
        volume: 100,
      },
      {
        price: 14000,
        volume: 100,
      },
      {
        price: 21000,
        volume: 100,
      },
      {
        price: 49000,
        volume: 100,
      },
      {
        price: 3910000,
        volume: 100,
      },
      {
        price: 4520000,
        volume: 100,
      },
    ];
    await contract.araFacet
      .connect(user2)
      .approve(contract.anyrareDiamond.address, "1".repeat("30"));
    await Promise.all(
      orderbooks.map((r) =>
        contract.collectionFactoryLimitOrderFacet.connect(user2).buyLimit({
          collectionAddr: collection0.addr,
          collectionId: 0,
          price: r.price,
          volume: r.volume,
        })
      )
    );

    // const result0 = await contract.dataFacet.getCollectionBidsPrice(0);
    const result1 = await contract.dataFacet.getCollectionBidsVolume(0, 8, 86);
    expect(result1).equal(100);

    const balanceUser30 = await contract.araFacet.balanceOf(user3.address);
    await contract.araFacet
      .connect(user3)
      .approve(contract.anyrareDiamond.address, "1".repeat("30"));
    await contract.collectionFactoryLimitOrderFacet.connect(user3).buyLimit({
      collectionAddr: collection0.addr,
      collectionId: 0,
      price: 13400,
      volume: 20,
    });
    const balanceUser31 = await contract.araFacet.balanceOf(user3.address);
    const result2 = await contract.dataFacet.getCollectionBidsVolume(0, 8, 86);
    expect(result2).equal(120);
  });

  // it("should test function buyMarketByVolume", async () => {
  //   await contract.araFacet
  //     .connect(user4)
  //     .approve(contract.anyrareDiamond.address, "1".repeat("30"));
  //   await contract.collectionFactoryFacet.connect(user4).buyMarketTargetVolume({
  //     collectionAddr: collection0.addr,
  //     collectionId: 0,
  //     volume: 350,
  //     slippage: 0,
  //   });

  //   const balance1 = await contract.dataFacet.getCollectionBalanceById(0, user4.address);
  //   console.log(balance1);
  // });
});
