import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers';
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

    return {
      owner,
      addr1,
      addr2,
      merkleTree,
      degenAirdrop,
      degenToken,
    };
  }

  describe('Airdrop', function () {
    describe('Claim', function () {
      it('Should return the zero merkle root', async function () {
        const { degenAirdrop } = await loadFixture(deployDegenFixture);

        expect(await degenAirdrop.merkleRoot()).to.eq(ZERO_BYTES32);
      });

      it('Should fail for empty proof', async function () {
        const { degenAirdrop, owner } = await loadFixture(deployDegenFixture);

        await expect(
          degenAirdrop.claim(0, owner.address, 10, [])
        ).to.be.revertedWithCustomError(degenAirdrop, 'InvalidProof');
      });

      describe('Two account Merkle tree', async function () {
        it('Should be successful claim', async () => {
          const { owner, addr1, addr2, merkleTree, degenAirdrop, degenToken } =
            await loadFixture(deployDegenSmallTreeFixture);

          const proof0 = merkleTree.getProof(0, addr1.address, 100n);

          const airdropAddress = await degenAirdrop.getAddress();
          degenToken.transfer(airdropAddress, 201);

          await expect(degenAirdrop.claim(0, addr1.address, 100, proof0))
            .to.emit(degenAirdrop, 'Claimed')
            .withArgs(0, addr1.address, 100);

          const proof1 = merkleTree.getProof(1, addr2.address, 101n);

          await expect(degenAirdrop.claim(1, addr2.address, 101, proof1))
            .to.emit(degenAirdrop, 'Claimed')
            .withArgs(1, addr2.address, 101);
        });
      });
    });
  });
});
