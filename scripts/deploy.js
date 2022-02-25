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
};

const deployARADiamond = async (root) => {
  console.log("\nDeploy ARADiamond");

  const { diamond, diamondInit, diamondLoupeFacet, ownershipFacet } =
    await deployDiamond(root, "contracts/ARA/DiamondInit.sol:DiamondInit");

  const LibBancorFormula = await ethers.getContractFactory("LibBancorFormula");
  const libBancorFormula = await LibBancorFormula.deploy();

  const ARAFacet = await ethers.getContractFactory("ARAFacet", {
    libraries: {
      LibBancorFormula: libBancorFormula.address
    }
  });
  const araFacet = await ARAFacet.deploy();

  const facets = [diamondLoupeFacet, ownershipFacet, araFacet];
  await deployFacet(diamond, diamondInit, facets);

  console.log("Diamond Address: ", diamond.address);

  return diamond;
};

const deployAnyrareDiamond = async (root) => {
  console.log("\nDeploy AnyrareDiamond");

  const { diamond, diamondInit, diamondLoupeFacet, ownershipFacet } =
    await deployDiamond(root, "contracts/Anyrare/DiamondInit.sol:DiamondInit");

  const MemberFacet = await ethers.getContractFactory("MemberFacet");
  const AssetFactoryFacet = await ethers.getContractFactory(
    "AssetFactoryFacet"
  );
  const GovernanceFacet = await ethers.getContractFactory(
    "GovernanceFacet"
  );
  const memberFacet = await MemberFacet.deploy();
  const assetFactoryFacet = await AssetFactoryFacet.deploy();
  const governanceFacet = await GovernanceFacet.deploy();

  const facets = [
    diamondLoupeFacet,
    ownershipFacet,
    memberFacet,
    assetFactoryFacet,
    governanceFacet,
  ];
  await deployFacet(diamond, diamondInit, facets);

  console.log("Diamond Address: ", diamond.address);

  return diamond;
};

const deployAssetDiamond = async (root) => {
  console.log("\nDeploy AssetDiamond");

  const { diamond, diamondInit, diamondLoupeFacet, ownershipFacet } =
    await deployDiamond(root, "contracts/Asset/DiamondInit.sol:DiamondInit");

  const AssetFacet = await ethers.getContractFactory("AssetFacet");
  const assetFacet = await AssetFacet.deploy();

  const facets = [diamondLoupeFacet, ownershipFacet, assetFacet];
  await deployFacet(diamond, diamondInit, facets);

  console.log("Diamond Address: ", diamond.address);

  return diamond;
};

const initMember = async (
  memberFacet,
  root,
  user1,
  user2,
  manager,
  operation,
  auditor,
  custodian,
  founder
) => {
  const thumbnail = "https://img.wallpapersafari.com/desktop/1536/864/75/56/Y8VwT1.jpg";


};

const deployContract = async () => {
  const [root, user1, user2, manager, operation, auditor, custodian, founder] =
    await ethers.getSigners();

  const araDiamond = await deployARADiamond(root);
  const anyrareDiamond = await deployAnyrareDiamond(root);
  const assetDiamond = await deployAssetDiamond(root);

  const araFacet = await ethers.getContractAt("ARAFacet", araDiamond.address);
  const assetFacet = await ethers.getContractAt(
    "AssetFacet",
    assetDiamond.address
  );
  const assetFactoryFacet = await ethers.getContractAt(
    "AssetFactoryFacet",
    anyrareDiamond.address
  );
  const memberFacet = await ethers.getContractAt(
    "MemberFacet",
    anyrareDiamond.address
  );
  const governanceFacet = await ethers.getContractAt(
    "GovernanceFacet",
    anyrareDiamond.address
  );

  await assetFacet.init(anyrareDiamond.address, "ARANFT", "ARANFT");
  await assetFactoryFacet.initAssetFactory(assetDiamond.address);

  return {
    araDiamond,
    anyrareDiamond,
    assetDiamond,
    araFacet,
    assetFacet,
    assetFactoryFacet,
    memberFacet,
    governanceFacet,
  };
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
