import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Degen token contract', function () {
  async function deployTokenFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const degenToken = await ethers.deployContract('DegenToken');

    // Fixtures can return anything you consider useful for your tests
    return { degenToken, owner, addr1, addr2 };
  }

  describe('Deployment', function () {
    it('Should set the right owner', async function () {
      // We use loadFixture to setup our environment, and then assert that
      // things went well
      const { degenToken, owner } = await loadFixture(deployTokenFixture);

      expect(await degenToken.owner()).to.equal(owner.address);
    });

    it('Should assign the total supply of tokens to the owner', async function () {
      const { degenToken, owner } = await loadFixture(deployTokenFixture);
      const ownerBalance = await degenToken.balanceOf(owner.address);
      expect(await degenToken.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe('Transactions', function () {
    it('Should transfer tokens between accounts', async function () {
      const { degenToken, owner, addr1, addr2 } = await loadFixture(
        deployTokenFixture
      );
      // Transfer 50 tokens from owner to addr1
      await expect(
        degenToken.transfer(addr1.address, 50)
      ).to.changeTokenBalances(degenToken, [owner, addr1], [-50, 50]);

      // Transfer 50 tokens from addr1 to addr2
      // We use .connect(signer) to send a transaction from another account
      await expect(
        degenToken.connect(addr1).transfer(addr2.address, 50)
      ).to.changeTokenBalances(degenToken, [addr1, addr2], [-50, 50]);
    });

    it('Should emit Transfer events', async function () {
      const { degenToken, owner, addr1, addr2 } = await loadFixture(
        deployTokenFixture
      );

      // Transfer 50 tokens from owner to addr1
      await expect(degenToken.transfer(addr1.address, 50))
        .to.emit(degenToken, 'Transfer')
        .withArgs(owner.address, addr1.address, 50);

      // Transfer 50 tokens from addr1 to addr2
      // We use .connect(signer) to send a transaction from another account
      await expect(degenToken.connect(addr1).transfer(addr2.address, 50))
        .to.emit(degenToken, 'Transfer')
        .withArgs(addr1.address, addr2.address, 50);
    });

    it("Should fail if sender doesn't have enough tokens", async function () {
      const { degenToken, owner, addr1 } = await loadFixture(
        deployTokenFixture
      );
      const initialOwnerBalance = await degenToken.balanceOf(owner.address);

      // Try to send 1 token from addr1 (0 tokens) to owner.
      // `require` will evaluate false and revert the transaction.

      await expect(
        degenToken.connect(addr1).transfer(owner.address, 1)
      ).to.be.revertedWithCustomError(degenToken, 'ERC20InsufficientBalance');

      // Owner balance shouldn't have changed.
      expect(await degenToken.balanceOf(owner.address)).to.equal(
        initialOwnerBalance
      );
    });
  });
});
