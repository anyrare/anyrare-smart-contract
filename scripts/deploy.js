const { ethers } = require("hardhat");
const { getSelectors, FacetCutAction } = require("./libraries/diamond.js");

const deployDiamond = async (root, contractPath) => {
  const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
  const diamondCutFacet = await DiamondCutFacet.deploy();
  await diamondCutFacet.deployed();

  const Diamond = await ethers.getContractFactory("Diamond");
  const diamond = await Diamond.deploy(root.address, diamondCutFacet.address);
  await diamond.deployed();

  const DiamondInit = await ethers.getContractFactory(contractPath);
  const diamondInit = await DiamondInit.deploy();
  await diamondInit.deployed();

  const DiamondLoupeFacet = await ethers.getContractFactory(
    "DiamondLoupeFacet"
  );
  const OwnershipFacet = await ethers.getContractFactory("OwnershipFacet");

  const diamondLoupeFacet = await DiamondLoupeFacet.deploy();
  const ownershipFacet = await OwnershipFacet.deploy();

  return {
    diamond,
    diamondInit,
    diamondLoupeFacet,
    ownershipFacet,
  };
};

const deployFacet = async (diamond, diamondInit, facets) => {
  const cuts = facets.map((r) => ({
    facetAddress: r.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(r),
  }));

  const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.address);
  const functionCall = diamondInit.interface.encodeFunctionData("init");

  const tx = await diamondCut.diamondCut(
    cuts,
    diamondInit.address,
    functionCall
  );
  await tx.wait();
}

const deployARADiamond = async (root) => {
  console.log("\nDeploy ARADiamond");

  const { diamond, diamondInit, diamondLoupeFacet, ownershipFacet } = await deployDiamond(root,
    "contracts/ARA/DiamondInit.sol:DiamondInit"
  );

  const ARAFacet = await ethers.getContractFactory("ARAFacet");
  const araFacet = await ARAFacet.deploy();

  const facets = [diamondLoupeFacet, ownershipFacet, araFacet];
  await deployFacet(diamond, diamondInit, facets);

  console.log("Diamond Address: ", diamond.address);

  return diamond;
};

const deployAnyrareDiamond = async (root) => {
  console.log("\nDeploy AnyrareDiamond");

  const { diamond, diamondInit, diamondLoupeFacet, ownershipFacet } = await deployDiamond(root,
    "contracts/Anyrare/DiamondInit.sol:DiamondInit"
  );

  const MemberFacet = await ethers.getContractFactory("MemberFacet");
  const memberFacet = await MemberFacet.deploy();

  const facets = [diamondLoupeFacet, ownershipFacet, memberFacet];
  await deployFacet(diamond, diamondInit, facets);

  console.log("Diamond Address: ", diamond.address);

  return diamond;
};


const deployAssetDiamond = async (root) => {
  console.log("\nDeploy AssetDiamond");

  const { diamond, diamondInit, diamondLoupeFacet, ownershipFacet } = await deployDiamond(root,
    "contracts/Asset/DiamondInit.sol:DiamondInit"
  );

  const AssetFacet = await ethers.getContractFactory("AssetFacet");
  const assetFacet = await AssetFacet.deploy();

  const facets = [...new Set([diamondLoupeFacet, ownershipFacet,
    assetFacet
  ])];
  await deployFacet(diamond, diamondInit, facets);

  console.log("Diamond Address: ", diamond.address);

  return diamond;
};

const deployContract = async () => {
  const [root] = await ethers.getSigners();

  const araDiamond = await deployARADiamond(root);
  const anyrareDiamond = await deployAnyrareDiamond(root);
  const assetDiamond = await deployAssetDiamond(root);

  // const araFacet = await ethers.getContractAt("ARAFacet", araDiamond.address);
  // const assetFacet = await ethers.getContractAt("AssetFacet", assetDiamond.address);

  // await assetFacet.init(anyrareDiamond.address, "nftARA", "nftARA");




  // const memberFacet = await ethers.getContractAt("MemberFacet", anyrareDiamond.address);
  // await memberFacet.t1(araDiamond.address);
  // await memberFacet.mintT(17);
  // await memberFacet.mintT(19);
  // const r2 = await memberFacet.getMintAddress(0);
  // const r3 = await memberFacet.getMintAddress(1);
  // console.log(r2, r3);

  // const d1 = await ethers.getContractAt("CollectionERC20", r2);
  // const r4 = await d1.getTemp();
  // const d2 = await ethers.getContractAt("CollectionERC20", r3);
  // const r5 = await d2.getTemp();
  // console.log(r4, r5);
};

if (require.main === module) {
  deployContract()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

exports.deployContract = deployContract;
