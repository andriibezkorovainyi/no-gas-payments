import {ethers} from "hardhat";
import {Payments} from "../typechain-types";
import {AbstractSigner} from "ethers";
import {expect} from "chai";


describe("Payments", async () => {
    async function deploy() {
        const [owner, receiver] = await ethers.getSigners();
        const Payments = await ethers.getContractFactory("Payments");
        const payments: Payments = await Payments.deploy({
            value: ethers.parseUnits("100", "ether"),
        });
        await payments.waitForDeployment();
        return [payments, owner, receiver] as [Payments, AbstractSigner, AbstractSigner];
    }

    it("should receive payments", async () => {
        const [payments, owner, receiver] = await deploy();

        console.log("receiver", await receiver.getAddress());
        await payments.on(payments.getEvent("Claimed"), (claimer, amount, nonce, owner) => {
            console.log("Claimed", claimer, amount, nonce, owner); // Ensure that the claimer is the receiver
        });


        const amount = ethers.parseEther("1");
        const nonce = 1;
        const hash = ethers.solidityPackedKeccak256(
            ["address", "uint256", "uint256", "address"],
            [await receiver.getAddress(), amount, nonce, await payments.getAddress()]
        );

        const messageHashBin = ethers.toBeArray(hash);
        const signature = await owner.signMessage(messageHashBin);

        const tx = await payments.connect(receiver).claim(amount, nonce, signature);
        await tx.wait();

        await new Promise(resolve => setTimeout(resolve, 1000)); // wait for event to be emitted

        expect(tx).to.changeEtherBalance(receiver, amount);
    });
});