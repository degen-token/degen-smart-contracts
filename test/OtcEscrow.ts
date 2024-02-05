import {
  loadFixture,
  time,
} from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers, ignition } from 'hardhat';
import OtcEscrowModule from '../ignition/modules/OtcEscrowModule';
import OtcTestToken1Module from '../ignition/modules/OtcTestToken1Module';
import OtcTestToken2Module from '../ignition/modules/OtcTestToken2Module';

describe('OtcEscrow', function () {
  async function deployDegenFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, buyAddr, sellAddr] = await ethers.getSigners();

    const buyer = buyAddr.address;
    const seller = sellAddr.address;

    const { otcTestToken1 } = await ignition.deploy(OtcTestToken1Module);
    const { otcTestToken2 } = await ignition.deploy(OtcTestToken2Module);
    const wethAddress = otcTestToken1.target;
    const degenAddress = otcTestToken2.target;

    const { otcEscrow } = await ignition.deploy(OtcEscrowModule, {
      parameters: {
        OtcEscrowModule: {
          buyer,
          seller,
          wethAddress,
          degenAddress,
        },
      },
    });

    return {
      owner,
      buyAddr,
      sellAddr,
      otcTestToken1,
      otcTestToken2,
      otcEscrow,
    };
  }

  describe('OTC Swap', function () {
    it('Should fail if the swap contract does not have enough degen tokens.', async function () {
      const { otcEscrow } = await loadFixture(deployDegenFixture);

      await expect(otcEscrow.swap()).to.be.revertedWithCustomError(
        otcEscrow,
        'InsufficientDegen'
      );
    });

    it('Should 2222', async function () {
      const { otcTestToken1, otcTestToken2, buyAddr, sellAddr, otcEscrow } =
        await loadFixture(deployDegenFixture);

      await otcTestToken1.transfer(buyAddr.address, 10000n * 10n ** 18n);
      await otcTestToken2.transfer(otcEscrow, 100n * 10n ** 18n);

      await expect(
        otcTestToken1
          .connect(buyAddr)
          .approve(otcEscrow.target, 10000n * 10n ** 18n)
      )
        .to.emit(otcTestToken1, 'Approval')
        .withArgs(buyAddr.address, otcEscrow.target, 10000n * 10n ** 18n);

      await otcEscrow.swap();

      expect(await otcTestToken1.balanceOf(sellAddr.address)).to.equal(
        1n * 10n ** 18n
      );
    });
  });
});
