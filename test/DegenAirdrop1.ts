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

describe('DegenAirdrop1', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployDegenFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, addr1, addr2] = await ethers.getSigners();

    const airdrop1MerkleRoot = ZERO_BYTES32;

    const { degenAirdrop1, degenToken } = await ignition.deploy(DegenModule, {
      parameters: {
        DegenModule: {
          airdrop1MerkleRoot,
        },
      },
    });

    return {
      owner,
      addr1,
      addr2,
      degenAirdrop1,
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
    const airdrop1MerkleRoot = merkleTree.getHexRoot();

    const { degenAirdrop1, degenToken } = await ignition.deploy(DegenModule, {
      parameters: {
        DegenModule: {
          airdrop1MerkleRoot,
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
      degenAirdrop1,
      proof0,
      proof1,
      degenToken,
    };
  }

  describe('Airdrop', function () {
    describe('Claim', function () {
      it('Should return the zero merkle root', async function () {
        const { degenAirdrop1 } = await loadFixture(deployDegenFixture);

        expect(await degenAirdrop1.MERKLE_ROOT()).to.eq(ZERO_BYTES32);
      });

      it('Should fail for empty proof', async function () {
        const { degenAirdrop1, owner } = await loadFixture(deployDegenFixture);

        await expect(
          degenAirdrop1.claim(0, owner.address, 10, [])
        ).to.be.revertedWithCustomError(degenAirdrop1, 'InvalidProof');
      });

      describe('Two account Merkle tree', async function () {
        it('Should be successful claim', async () => {
          const { addr1, addr2, degenAirdrop1, proof0, proof1 } =
            await loadFixture(deployDegenSmallTreeFixture);

          await expect(
            degenAirdrop1.connect(addr1).claim(0, addr1.address, 100n, proof0)
          )
            .to.emit(degenAirdrop1, 'Claimed')
            .withArgs(0, addr1.address, 100n);

          await expect(
            degenAirdrop1.connect(addr2).claim(1, addr2.address, 101n, proof1)
          )
            .to.emit(degenAirdrop1, 'Claimed')
            .withArgs(1, addr2.address, 101n);
        });

        it('Should change balance on token claim', async () => {
          const { addr1, degenAirdrop1, proof0, degenToken } =
            await loadFixture(deployDegenSmallTreeFixture);

          expect(await degenToken.balanceOf(addr1.address)).to.eq(0);

          await degenAirdrop1
            .connect(addr1)
            .claim(0, addr1.address, 100n, proof0);

          expect(await degenToken.balanceOf(addr1.address)).to.eq(100n);
        });

        it('Should set #isClaimed', async () => {
          const { addr1, degenAirdrop1, proof0 } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          expect(await degenAirdrop1.isClaimed(0)).to.eq(false);
          expect(await degenAirdrop1.isClaimed(1)).to.eq(false);
          await degenAirdrop1
            .connect(addr1)
            .claim(0, addr1.address, 100n, proof0);
          expect(await degenAirdrop1.isClaimed(0)).to.eq(true);
          expect(await degenAirdrop1.isClaimed(1)).to.eq(false);
        });

        it('Should not allow two claims', async () => {
          const { addr1, degenAirdrop1, proof0 } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          await degenAirdrop1
            .connect(addr1)
            .claim(0, addr1.address, 100n, proof0);

          await expect(
            degenAirdrop1.connect(addr1).claim(0, addr1.address, 100, proof0)
          ).to.be.revertedWithCustomError(degenAirdrop1, 'AlreadyClaimed');
        });

        it('Should not be able claim for address other than proof', async () => {
          const { addr1, degenAirdrop1, proof0 } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          await expect(
            degenAirdrop1.connect(addr1).claim(1, addr1.address, 101n, proof0)
          ).to.be.revertedWithCustomError(degenAirdrop1, 'InvalidProof');
        });

        it('Should not be able to claim more than proof', async () => {
          const { addr1, degenAirdrop1, proof0 } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          await expect(
            degenAirdrop1.connect(addr1).claim(0, addr1.address, 101n, proof0)
          ).to.be.revertedWithCustomError(degenAirdrop1, 'InvalidProof');
        });

        it('Should not be able to claim after airdrop deadline', async () => {
          const { addr1, degenAirdrop1, proof0 } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          const endTimeTimestamp = await degenAirdrop1.END_TIME();
          await time.increaseTo(endTimeTimestamp);

          await expect(
            degenAirdrop1.connect(addr1).claim(0, addr1.address, 100n, proof0)
          ).to.be.revertedWithCustomError(degenAirdrop1, 'ClaimWindowFinished');
        });

        it('Should be able to withdraw after airdrop deadline', async () => {
          const { owner, degenAirdrop1, degenToken } = await loadFixture(
            deployDegenSmallTreeFixture
          );

          const endTimeTimestamp = await degenAirdrop1.END_TIME();
          await time.increaseTo(endTimeTimestamp);

          const initialOwnerBalance = await degenToken.balanceOf(owner.address);
          const initialAirdrop1Balance = await degenToken.balanceOf(
            degenAirdrop1
          );

          await degenAirdrop1.connect(owner).withdraw();

          expect(await degenToken.balanceOf(owner.address)).to.eq(
            initialOwnerBalance + initialAirdrop1Balance
          );
        });
      });
    });
  });
});
