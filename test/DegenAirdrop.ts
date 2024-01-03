import {
  loadFixture,
  time,
} from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers, ignition } from 'hardhat';
import DegenModule from '../ignition/modules/DegenModule';
import BalanceTree from '../scripts/balance-tree';

const ZERO_BYTES32 =
  '0x0000000000000000000000000000000000000000000000000000000000000000';

describe('DegenAirdrop', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployDegenFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, addr1, addr2] = await ethers.getSigners();

    const merkleRoot = ZERO_BYTES32;

    const { degenAirdrop, degenToken } = await ignition.deploy(DegenModule, {
      parameters: {
        DegenModule: {
          merkleRoot,
        },
      },
    });

    return {
      owner,
      addr1,
      addr2,
      degenAirdrop,
      degenToken,
    };
  }

  async function deployDegenSmallTreeFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, addr1, addr2] = await ethers.getSigners();

    const merkleTree = new BalanceTree([
      { account: addr1.address, amount: 100n },
      { account: addr2.address, amount: 101n },
    ]);
    const merkleRoot = merkleTree.getHexRoot();

    const { degenAirdrop, degenToken } = await ignition.deploy(DegenModule, {
      parameters: {
        DegenModule: {
          merkleRoot,
        },
      },
    });

    const proof0 = merkleTree.getProof(0, addr1.address, 100n);
    const proof1 = merkleTree.getProof(1, addr2.address, 101n);

    return {
      owner,
      addr1,
      addr2,
      merkleTree,
      degenAirdrop,
      proof0,
      proof1,
      degenToken,
    };
  }

  describe('Airdrop', function () {
    describe('Claim', function () {
      it('Should return the zero merkle root', async function () {
        const { degenAirdrop } = await loadFixture(deployDegenFixture);

        expect(await degenAirdrop.MERKLE_ROOT()).to.eq(ZERO_BYTES32);
      });

      it('Should fail for empty proof', async function () {
        const { degenAirdrop, owner } = await loadFixture(deployDegenFixture);

        await expect(
          degenAirdrop.claim(0, owner.address, 10, [])
        ).to.be.revertedWithCustomError(degenAirdrop, 'InvalidProof');
      });

      describe('Two account Merkle tree', async function () {
        it('Should be successful claim', async () => {
          const { addr1, addr2, degenAirdrop, proof0, proof1, degenToken } =
            await loadFixture(deployDegenSmallTreeFixture);

          const airdropAddress = await degenAirdrop.getAddress();
          degenToken.transfer(airdropAddress, 201n);

          await expect(
            degenAirdrop.connect(addr1).claim(0, addr1.address, 100n, proof0)
          )
            .to.emit(degenAirdrop, 'Claimed')
            .withArgs(0, addr1.address, 100n);

          await expect(
            degenAirdrop.connect(addr2).claim(1, addr2.address, 101n, proof1)
          )
            .to.emit(degenAirdrop, 'Claimed')
            .withArgs(1, addr2.address, 101n);
        });

        it('Should fail to claim if the account is not the same as the sender', async () => {
          const { owner, addr1, degenAirdrop, proof0, degenToken } =
            await loadFixture(deployDegenSmallTreeFixture);

          const airdropAddress = await degenAirdrop.getAddress();
          degenToken.transfer(airdropAddress, 100n);

          await expect(
            degenAirdrop.connect(owner).claim(0, addr1.address, 100, proof0)
          ).to.be.revertedWithCustomError(degenAirdrop, 'NotClaimAccount');
        });

        it('Should change balance on token claim', async () => {
          const { addr1, degenAirdrop, proof0, degenToken } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          const airdropAddress = await degenAirdrop.getAddress();
          degenToken.transfer(airdropAddress, 100n);

          expect(await degenToken.balanceOf(addr1.address)).to.eq(0);

          await degenAirdrop
            .connect(addr1)
            .claim(0, addr1.address, 100n, proof0);

          expect(await degenToken.balanceOf(addr1.address)).to.eq(100n);
        });

        it('Should have sufficient tokens to claim the airdrop', async () => {
          const { addr1, degenAirdrop, proof0, degenToken } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          await expect(
            degenAirdrop.connect(addr1).claim(0, addr1.address, 100n, proof0)
          ).to.be.revertedWithCustomError(
            degenToken,
            'ERC20InsufficientBalance'
          );
        });

        it('Should set #isClaimed', async () => {
          const { addr1, degenAirdrop, proof0, degenToken } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          const airdropAddress = await degenAirdrop.getAddress();
          degenToken.transfer(airdropAddress, 100n);

          expect(await degenAirdrop.isClaimed(0)).to.eq(false);
          expect(await degenAirdrop.isClaimed(1)).to.eq(false);
          await degenAirdrop
            .connect(addr1)
            .claim(0, addr1.address, 100n, proof0);
          expect(await degenAirdrop.isClaimed(0)).to.eq(true);
          expect(await degenAirdrop.isClaimed(1)).to.eq(false);
        });

        it('Should not allow two claims', async () => {
          const { addr1, degenAirdrop, proof0, degenToken } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          const airdropAddress = await degenAirdrop.getAddress();
          degenToken.transfer(airdropAddress, 100n);

          await degenAirdrop
            .connect(addr1)
            .claim(0, addr1.address, 100n, proof0);

          await expect(
            degenAirdrop.connect(addr1).claim(0, addr1.address, 100, proof0)
          ).to.be.revertedWithCustomError(degenAirdrop, 'AlreadyClaimed');
        });

        it('Should not be able claim for address other than proof', async () => {
          const { addr1, degenAirdrop, proof0, degenToken } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          const airdropAddress = await degenAirdrop.getAddress();
          degenToken.transfer(airdropAddress, 100n);

          await expect(
            degenAirdrop.connect(addr1).claim(1, addr1.address, 101n, proof0)
          ).to.be.revertedWithCustomError(degenAirdrop, 'InvalidProof');
        });

        it('Should not be able to claim more than proof', async () => {
          const { addr1, degenAirdrop, proof0, degenToken } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          const airdropAddress = await degenAirdrop.getAddress();
          degenToken.transfer(airdropAddress, 201n);

          await expect(
            degenAirdrop.connect(addr1).claim(0, addr1.address, 101n, proof0)
          ).to.be.revertedWithCustomError(degenAirdrop, 'InvalidProof');
        });

        it('Should not be able to claim after airdrop deadline', async () => {
          const { addr1, degenAirdrop, proof0, degenToken } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          const airdropAddress = await degenAirdrop.getAddress();
          degenToken.transfer(airdropAddress, 100n);

          const endTimeTimestamp = await degenAirdrop.END_TIME();
          await time.increaseTo(endTimeTimestamp);

          await expect(
            degenAirdrop.connect(addr1).claim(0, addr1.address, 100n, proof0)
          ).to.be.revertedWithCustomError(degenAirdrop, 'ClaimWindowFinished');
        });

        it('Should be able to withdraw after airdrop deadline', async () => {
          const { owner, addr1, degenAirdrop, proof0, degenToken } =
            await loadFixture(deployDegenSmallTreeFixture);

          const transferAmount = 100n;
          const airdropAddress = await degenAirdrop.getAddress();
          degenToken.transfer(airdropAddress, transferAmount);

          const endTimeTimestamp = await degenAirdrop.END_TIME();
          await time.increaseTo(endTimeTimestamp);

          const totalSupply = await degenToken.totalSupply();

          expect(await degenToken.balanceOf(owner.address)).to.eq(
            totalSupply - transferAmount
          );

          await degenAirdrop.connect(owner).withdraw();

          expect(await degenToken.balanceOf(owner.address)).to.eq(totalSupply);
        });
      });
    });
  });
});
