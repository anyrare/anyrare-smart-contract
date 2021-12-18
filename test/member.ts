import { expect } from "chai";
import { ethers } from "hardhat";

describe("Member", async () => {
    it("Member", async () => {
        const [root, user1, user2, user3] = await ethers.getSigners();

        const Member = await ethers.getContractFactory("Member");
        const member = await Member.deploy(root.address);

        await member.setMember(user1.address, root.address);
        await member.setMember(user2.address, user1.address);
        await member.setMember(user3.address, user3.address);

        expect(await member.members(root.address)).to.equal(root.address);
        expect(await member.members(user1.address)).to.equal(root.address);
        expect(await member.members(user2.address)).to.equal(user1.address);
        expect(+await member.members(user3.address)).to.equal(0x0);

        expect(await member.isValidMember(user2.address)).to.equal(true);
        expect(await member.isValidMember(user3.address)).to.equal(false);

        const ARA = await ethers.getContractFactory("ARA");
        const ARAToken = await ARA.deploy(member.address);


        console.log(await ARAToken.getMember(user3.address));
    });
});
