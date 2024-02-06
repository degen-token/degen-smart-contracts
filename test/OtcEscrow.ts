import {
  loadFixture,
  time,
} from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers, ignition } from 'hardhat';
import OtcEscrowModule from '../ignition/modules/otc/1conf/OtcEscrowModule';
import OtcTestToken1Module from '../ignition/modules/otc/OtcTestToken1Module';
import OtcTestToken2Module from '../ignition/modules/otc/OtcTestToken2Module';

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

  describe('Swap', function () {
    it('Should fail if the swap contract does not have enough degen tokens.', async function () {
      const { otcEscrow } = await loadFixture(deployDegenFixture);

      await expect(otcEscrow.swap()).to.be.revertedWithCustomError(
        otcEscrow,
        'InsufficientDegen'
      );
    });

    it('Should complete the swap successfully', async function () {
      const { otcTestToken1, otcTestToken2, buyAddr, sellAddr, otcEscrow } =
        await loadFixture(deployDegenFixture);

      const wethAmount = await otcEscrow.WETH_AMOUNT();
      const degenAmount = await otcEscrow.DEGEN_AMOUNT();
      await otcTestToken1.transfer(buyAddr.address, wethAmount);
      await otcTestToken2.transfer(otcEscrow, degenAmount);

      await expect(
        otcTestToken1.connect(buyAddr).approve(otcEscrow.target, wethAmount)
      )
        .to.emit(otcTestToken1, 'Approval')
        .withArgs(buyAddr.address, otcEscrow.target, wethAmount);

      await otcEscrow.swap();

      expect(await otcTestToken1.balanceOf(sellAddr.address)).to.equal(
        wethAmount
      );
    });

    it('Should fail if swap is executed twice', async function () {
      const { otcTestToken1, otcTestToken2, buyAddr, otcEscrow } =
        await loadFixture(deployDegenFixture);

      const wethAmount = await otcEscrow.WETH_AMOUNT();
      const degenAmount = await otcEscrow.DEGEN_AMOUNT();
      await otcTestToken1.transfer(buyAddr.address, wethAmount);
      await otcTestToken2.transfer(otcEscrow, degenAmount);

      await expect(
        otcTestToken1.connect(buyAddr).approve(otcEscrow.target, wethAmount)
      )
        .to.emit(otcTestToken1, 'Approval')
        .withArgs(buyAddr.address, otcEscrow.target, wethAmount);

      await otcEscrow.swap();

      await expect(otcEscrow.swap()).to.be.revertedWithCustomError(
        otcEscrow,
        'SwapAlreadyExecuted'
      );
    });
  });
});
