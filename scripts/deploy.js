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

const deployAnyrareDiamond = async (root) => {
  console.log("\nDeploy AnyrareDiamond");

  const { diamond, diamondInit, diamondLoupeFacet, ownershipFacet } =
    await deployDiamond(root, "contracts/Anyrare/DiamondInit.sol:DiamondInit");

  const LibData = await ethers.getContractFactory("LibData");
  const libData = await LibData.deploy();

  const MemberFacet = await ethers.getContractFactory("MemberFacet");
  const DataFacet = await ethers.getContractFactory("DataFacet", {
    libraries: {
      LibData: libData.address,
    },
  });

  const memberFacet = await MemberFacet.deploy();
  const dataFacet = await DataFacet.deploy();

  const facets = [diamondLoupeFacet, ownershipFacet, memberFacet, dataFacet];
  await deployFacet(diamond, diamondInit, facets);

  console.log("Diamond Address: ", diamond.address);

  return diamond;
};

const initMember = async ({
  memberFacet,
  root,
  user1,
  user2,
  manager1,
  manager2,
  custodian1,
  custodian2,
  auditor1,
  auditor2,
}) => {
  const thumbnail =
    "https://img.wallpapersafari.com/desktop/1536/864/75/56/Y8VwT1.jpg";

  await memberFacet.initMember();
  await memberFacet
    .connect(user1)
    .createMember(user1.address, root.address, "user1", thumbnail);
  await memberFacet
    .connect(user2)
    .createMember(user2.address, user1.address, "user2", thumbnail);
  await memberFacet
    .connect(manager1)
    .createMember(manager1.address, user1.address, "manager1", thumbnail);
  await memberFacet
    .connect(manager2)
    .createMember(manager2.address, user2.address, "manager2", thumbnail);
  await memberFacet
    .connect(custodian1)
    .createMember(
      custodian1.address,
      manager1.address,
      "custodian1",
      thumbnail
    );
  await memberFacet
    .connect(custodian2)
    .createMember(
      custodian2.address,
      manager2.address,
      "custodian2",
      thumbnail
    );
  await memberFacet
    .connect(auditor1)
    .createMember(auditor1.address, manager1.address, "auditor1", thumbnail);
  await memberFacet
    .connect(auditor2)
    .createMember(auditor2.address, manager2.address, "auditor22", thumbnail);
};

const deployContract = async () => {
  const [
    root,
    user1,
    user2,
    manager1,
    manager2,
    custodian1,
    custodian2,
    auditor1,
    auditor2,
  ] = await ethers.getSigners();

  const anyrareDiamond = await deployAnyrareDiamond(root);

  const memberFacet = await ethers.getContractAt(
    "MemberFacet",
    anyrareDiamond.address
  );

  const dataFacet = await ethers.getContractAt(
    "DataFacet",
    anyrareDiamond.address
  );

  await initMember({
    memberFacet,
    root,
    user1,
    user2,
    manager1,
    manager2,
    custodian1,
    custodian2,
    auditor1,
    auditor2,
  });

  return {
    anyrareDiamond,
    memberFacet,
    dataFacet
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
