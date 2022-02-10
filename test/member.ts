import { expect } from "chai";

export const initMember = async (
  memberContract: any,
  root: any,
  user1: any,
  user2: any,
  user3: any,
  user4: any,
  user5: any,
  referralUser1: any,
  referralUser2: any,
  referralUser3: any,
  referralUser4: any,
  auditor0: any,
  auditor1: any,
  referralAuditor: any,
  custodian0: any,
  custodian1: any,
  referralCustodian: any,
  manager0: any,
  manager1: any,
  operation0: any,
  operation1: any
) => {
  console.log("\n*** Member Contract");
  const thumbnail = "https://cdn5.vectorstock.com/i/1000x1000/56/09/online-chat-icon-simple-style-vector-8445609.jpg";

  await memberContract
    .connect(referralUser1)
    .setMember(referralUser1.address, root.address, 'referralUser1', thumbnail);
  console.log("referralUser1");
  await memberContract
    .connect(referralUser4)
    .setMember(referralUser4.address, root.address, 'referralUser4', thumbnail);
  await memberContract
    .connect(referralUser2)
    .setMember(referralUser2.address, referralUser4.address, 'referralUser2', thumbnail);
  await expect(
    memberContract
      .connect(user3)
      .setMember(user3.address, referralUser3.address, 'user3', thumbnail)
  ).to.be.reverted;
  console.log("Test: Should be revert if referral is self referrence.");

  await expect(
    memberContract
      .connect(referralUser1)
      .setMember(referralUser1.address, referralUser4.address, 'referarlUser1', thumbnail)
  ).to.be.reverted;
  console.log("Test: cannot re assign referral");

  expect((await memberContract.members(root.address)).referral).to.equal(root.address);
  console.log("Test: test referral root");

  expect(await memberContract.getReferral(referralUser1.address)).to.equal(
    root.address
  );
  console.log("Test: refer of refUser1");

  expect(await memberContract.getReferral(referralUser4.address)).to.equal(
    root.address
  );
  console.log("Test: refer of refUser4");

  expect(await memberContract.getReferral(referralUser2.address)).to.equal(
    referralUser4.address
  );
  console.log("Test: refer of refUser2");

  console.log(+(await memberContract.members(referralUser3.address)).referral);
  expect(+(await memberContract.members(referralUser3.address)).referral).to.equal(0);
  expect(await memberContract.isMember(referralUser2.address)).to.equal(true);
  expect(await memberContract.isMember(referralUser3.address)).to.equal(false);
  console.log("Test: user2 is member");
  console.log("Test: user3 is not member");

  await memberContract
    .connect(referralUser3)
    .setMember(referralUser3.address, root.address, 'referralUser3', thumbnail);
  await memberContract
    .connect(referralAuditor)
    .setMember(referralAuditor.address, root.address, 'auditor', thumbnail);
  await memberContract
    .connect(referralCustodian)
    .setMember(referralCustodian.address, root.address, 'custodian', thumbnail);
  await memberContract
    .connect(user1)
    .setMember(user1.address, referralUser1.address, 'user1', thumbnail);
  await memberContract
    .connect(user2)
    .setMember(user2.address, referralUser2.address, 'user2', thumbnail),
    await memberContract
      .connect(user3)
      .setMember(user3.address, referralUser3.address, 'user3', thumbnail);
  await memberContract
    .connect(user4)
    .setMember(user4.address, referralUser4.address, 'user4', thumbnail);
  await memberContract.connect(user5).setMember(user5.address, root.address, 'user5', thumbnail);
  await memberContract
    .connect(auditor0)
    .setMember(auditor0.address, referralAuditor.address, 'auditor0', thumbnail);
  await memberContract
    .connect(auditor1)
    .setMember(auditor1.address, referralAuditor.address, 'auditor1', thumbnail);
  await memberContract
    .connect(custodian0)
    .setMember(custodian0.address, referralCustodian.address, 'custodian0', thumbnail);
  await memberContract
    .connect(custodian1)
    .setMember(custodian1.address, referralCustodian.address, 'custodian1', thumbnail);
  await memberContract
    .connect(manager0)
    .setMember(manager0.address, root.address, 'manager0', thumbnail);
  await memberContract
    .connect(manager1)
    .setMember(manager1.address, root.address, 'manager1', thumbnail);
  await memberContract
    .connect(operation0)
    .setMember(operation0.address, root.address, 'operation0', thumbnail);
  await memberContract
    .connect(operation1)
    .setMember(operation1.address, root.address, 'operation1', thumbnail);
  console.log(
    "Set: user3, user4, auditor, custodian, manager, operation to be member"
  );
};

const memberABI = [
  {
    inputs: [
      {
        internalType: "address",
        name: "root",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "addr",
        type: "address",
      },
    ],
    name: "getReferral",
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
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "isMember",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "members",
    outputs: [
      {
        internalType: "address",
        name: "referral",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "addr",
        type: "address",
      },
      {
        internalType: "address",
        name: "referral",
        type: "address",
      },
    ],
    name: "setMember",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export const testDeployMemberContractFromABI = async (
  ethers: any,
  user: any
) => {
  console.log("\n**** Test connect member abi contract");
  const contractAddress = "0x51ca5465CE9F3825CB0FBFE25503A48ecaD2f3BC";
  const provider = new ethers.providers.JsonRpcProvider(
    { url: "https://testnet.anyrare.network" }
  );


  const memberContract = new ethers.Contract(
    contractAddress,
    memberABI,
    provider
  );

  const user0 = "0x1E6C09C1D3Ac114752dbBD3E4e91b0b167ddee84";
  const user1 = "0xb30Ec3b60A5d5ca4822E950942B75eb03D8BBF15";
  expect(
    await memberContract
      .connect(provider)
      .isMember(user0)
  ).to.equal(true);
  expect(
    await memberContract
      .connect(provider)
      .isMember(
        user1
      )
  ).to.equal(true);

  const referral0 = await memberContract
    .connect(provider)
    .getReferral(user0);

  console.log("ref user0:", referral0);

  const referral1 = await memberContract.connect(provider).getReferral(user1)
  console.log("ref user1:", referral1);
};
