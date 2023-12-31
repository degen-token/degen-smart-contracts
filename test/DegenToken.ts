import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers, ignition } from 'hardhat';
import DegenModule from '../ignition/modules/DegenModule';

describe('DegenToken', function () {
  async function deployDegenFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, addr1, addr2] = await ethers.getSigners();

    const { degenToken } = await ignition.deploy(DegenModule);

    return {
      owner,
      addr1,
      addr2,
      degenToken,
    };
  }

  describe('Deployment', function () {
    it('Should assign the total supply of tokens to the owner', async function () {
      const { degenToken, owner } = await loadFixture(deployDegenFixture);

      const ownerBalance = await degenToken.balanceOf(owner.address);

      expect(await degenToken.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe('Transactions', function () {
    it('Should transfer tokens between accounts', async function () {
      const { degenToken, owner, addr1, addr2 } = await loadFixture(
        deployDegenFixture
      );

      // Transfer 50 tokens from owner to addr1
      await expect(
        degenToken.transfer(addr1.address, 50)
      ).to.changeTokenBalances(degenToken, [owner, addr1], [-50, 50]);

      // Transfer 50 tokens from addr1 to addr2
      await expect(
        degenToken.connect(addr1).transfer(addr2.address, 50)
      ).to.changeTokenBalances(degenToken, [addr1, addr2], [-50, 50]);
    });

    it('Should emit Transfer events', async function () {
      const { degenToken, owner, addr1, addr2 } = await loadFixture(
        deployDegenFixture
      );

      // Transfer 50 tokens from owner to addr1
      await expect(degenToken.transfer(addr1.address, 50))
        .to.emit(degenToken, 'Transfer')
        .withArgs(owner.address, addr1.address, 50);

      // Transfer 50 tokens from addr1 to addr2
      await expect(degenToken.connect(addr1).transfer(addr2.address, 50))
        .to.emit(degenToken, 'Transfer')
        .withArgs(addr1.address, addr2.address, 50);
    });

    it("Should fail if sender doesn't have enough tokens", async function () {
      const { degenToken, owner, addr1 } = await loadFixture(
        deployDegenFixture
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

  describe('Burn', function () {
    it('Should burn tokens', async function () {
      const { degenToken, owner, addr1 } = await loadFixture(
        deployDegenFixture
      );
      const initialTotalSupply = await degenToken.totalSupply();

      // Transfer 50 tokens from owner to addr1
      degenToken.transfer(addr1.address, 50);

      // Burn 25 tokens from addr1
      await expect(degenToken.connect(addr1).burn(25)).to.changeTokenBalances(
        degenToken,
        [addr1],
        [-25]
      );

      // Total supply should be reduced by 25
      expect(await degenToken.totalSupply()).to.equal(
        initialTotalSupply - BigInt(25)
      );
    });
  });
});