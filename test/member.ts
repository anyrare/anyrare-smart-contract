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
  await memberContract.setMember(referralUser1.address, root.address);
  await memberContract.setMember(referralUser4.address, root.address);
  await memberContract.setMember(referralUser2.address, referralUser4.address);
  await expect(memberContract.setMember(user3.address, referralUser3.address))
    .to.be.reverted;
  console.log("Test: Should be revert if referral is self referrence.");

  await expect(
    memberContract.setMember(referralUser1.address, referralUser4.address)
  ).to.be.reverted;
  console.log("Test: cannot re assign referral");

  expect(await memberContract.members(root.address)).to.equal(root.address);
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

  expect(+(await memberContract.members(referralUser3.address))).to.equal(0x0);
  expect(await memberContract.isMember(referralUser2.address)).to.equal(true);
  expect(await memberContract.isMember(referralUser3.address)).to.equal(false);
  console.log("Test: user2 is member");
  console.log("Test: user3 is not member");

  await memberContract.setMember(referralUser3.address, root.address);
  await memberContract.setMember(referralAuditor.address, root.address);
  await memberContract.setMember(referralCustodian.address, root.address);
  await memberContract.setMember(user1.address, referralUser1.address);
  await memberContract.setMember(user2.address, referralUser2.address);
  await memberContract.setMember(user3.address, referralUser3.address);
  await memberContract.setMember(user4.address, referralUser4.address);
  await memberContract.setMember(user5.address, root.address);
  await memberContract.setMember(auditor0.address, referralAuditor.address);
  await memberContract.setMember(auditor1.address, referralAuditor.address);
  await memberContract.setMember(custodian0.address, referralCustodian.address);
  await memberContract.setMember(custodian1.address, referralCustodian.address);
  await memberContract.setMember(manager0.address, root.address);
  await memberContract.setMember(manager1.address, root.address);
  await memberContract.setMember(operation0.address, root.address);
  await memberContract.setMember(operation1.address, root.address);
  console.log(
    "Set: user3, user4, auditor, custodian, manager, operation to be member"
  );
};
