import { expect } from "chai";

export const initMember = async (
  memberContract: any,
  root: any,
  user1: any,
  user2: any,
  user3: any,
  user4: any,
  user5: any,
  auditor0: any,
  auditor1: any,
  custodian0: any,
  custodian1: any,
  manager0: any,
  manager1: any,
  operation0: any,
  operation1: any
) => {
  console.log("\n*** Member Contract");
  await memberContract.setMember(user1.address, root.address);
  await memberContract.setMember(user5.address, root.address);
  await memberContract.setMember(user2.address, user5.address);
  await expect(memberContract.setMember(user3.address, user3.address)).to.be
    .reverted;
  console.log("Test: Should be revert if referral is self referrence.");

  expect(await memberContract.members(root.address)).to.equal(root.address);
  expect(await memberContract.getReferral(user1.address)).to.equal(
    root.address
  );
  expect(await memberContract.members(user1.address)).to.equal(root.address);
  expect(await memberContract.members(user5.address)).to.equal(root.address);
  expect(await memberContract.members(user2.address)).to.equal(user5.address);
  expect(+(await memberContract.members(user3.address))).to.equal(0x0);
  expect(await memberContract.isMember(user2.address)).to.equal(true);
  expect(await memberContract.isMember(user3.address)).to.equal(false);
  console.log("Test: referral for root is root");
  console.log("Test: referral for user1 is root");
  console.log("Test: referral for user2 is user1");
  console.log("Test: referral for user3 is null");
  console.log("Test: user2 is member");
  console.log("Test: user3 is not member");

  await memberContract.setMember(user3.address, user2.address);
  await memberContract.setMember(user4.address, user3.address);
  await memberContract.setMember(auditor0.address, user4.address);
  await memberContract.setMember(auditor1.address, user4.address);
  await memberContract.setMember(custodian0.address, user4.address);
  await memberContract.setMember(custodian1.address, user4.address);
  await memberContract.setMember(manager0.address, user4.address);
  await memberContract.setMember(manager1.address, user4.address);
  await memberContract.setMember(operation0.address, user4.address);
  await memberContract.setMember(operation1.address, user4.address);
  console.log(
    "Set: user3, user4, auditor, custodian, manager, operation to be member"
  );
};
