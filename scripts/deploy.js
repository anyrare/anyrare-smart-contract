const { ethers } = require("hardhat");
const { getSelectors, FacetCutAction } = require("./libraries/diamond.js");
const { policies } = require("./initialPolicy.js");

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
      LibBancorFormula: libBancorFormula.address,
    },
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

  const LibData = await ethers.getContractFactory("LibData");
  const libData = await LibData.deploy();

  const MemberFacet = await ethers.getContractFactory("MemberFacet");
  const AssetFactoryFacet = await ethers.getContractFactory(
    "AssetFactoryFacet"
  );
  const GovernanceFacet = await ethers.getContractFactory("GovernanceFacet");
  const DataFacet = await ethers.getContractFactory("DataFacet", {
    libraries: {
      LibData: libData.address
    }
  });
  const memberFacet = await MemberFacet.deploy();
  const assetFactoryFacet = await AssetFactoryFacet.deploy();
  const governanceFacet = await GovernanceFacet.deploy();
  const dataFacet = await DataFacet.deploy();

  const facets = [
    diamondLoupeFacet,
    ownershipFacet,
    memberFacet,
    assetFactoryFacet,
    governanceFacet,
    dataFacet
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
  const thumbnail =
    "https://img.wallpapersafari.com/desktop/1536/864/75/56/Y8VwT1.jpg";

  await memberFacet.initMember();
  await memberFacet
    .connect(founder)
    .createMember(founder.address, root.address, "founder", thumbnail);
  await memberFacet
    .connect(user1)
    .createMember(user1.address, founder.address, "user1", thumbnail);
  await memberFacet
    .connect(user2)
    .createMember(user2.address, user1.address, "user2", thumbnail);
  await memberFacet
    .connect(manager)
    .createMember(manager.address, founder.address, "manager", thumbnail);
  await memberFacet
    .connect(operation)
    .createMember(operation.address, founder.address, "operation", thumbnail);
  await memberFacet
    .connect(auditor)
    .createMember(auditor.address, founder.address, "auditor", thumbnail);
  await memberFacet
    .connect(custodian)
    .createMember(custodian.address, founder.address, "custodian", thumbnail);
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
  const dataFacet = await ethers.getContractAt(
    "DataFacet",
    anyrareDiamond.address
  );

  await araFacet.connect(root).init(10 ** 6);
  await araFacet.connect(root).setOwner(root.address, anyrareDiamond.address);
  await assetFacet.init(anyrareDiamond.address, "ARANFT", "ARANFT");
  await assetFactoryFacet.initAssetFactory(assetDiamond.address);
  await initMember(
    memberFacet,
    root,
    user1,
    user2,
    manager,
    operation,
    auditor,
    custodian,
    founder
  );
  await governanceFacet.initContractAddress(
    araDiamond.address,
    assetDiamond.address
  );
  await governanceFacet.connect(root).initPolicy(
    1,
    [{ addr: founder.address, controlWeight: 10 ** 6 }],
    manager.address,
    operation.address,
    auditor.address,
    custodian.address,
    policies.length,
    policies
  );

  return {
    araDiamond,
    anyrareDiamond,
    assetDiamond,
    araFacet,
    assetFacet,
    assetFactoryFacet,
    memberFacet,
    governanceFacet,
    dataFacet,
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
