import {
  loadFixture,
  time,
} from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers, ignition } from 'hardhat';
import { OtcVestingModule } from '../ignition/modules/otc/1conf/OtcEscrowModule';
import OtcTestToken2Module from '../ignition/modules/otc/OtcTestToken2Module';

describe('OtcVesting', function () {
  async function deployDegenFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, buyAddr] = await ethers.getSigners();

    const buyer = buyAddr.address;

    const { otcTestToken2 } = await ignition.deploy(OtcTestToken2Module);
    const degenAddress = otcTestToken2.target;

    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const vestingStart = (await time.latest()) + 3600;
    const vestingCliff = vestingStart + 3600;
    const vestingEnd = vestingStart + ONE_YEAR_IN_SECS;

    const { otcVesting } = await ignition.deploy(OtcVestingModule, {
      parameters: {
        OtcVestingModule: {
          degenAddress,
          buyer,
          vestingStart,
          vestingCliff,
          vestingEnd,
        },
      },
    });

    return {
      owner,
      buyAddr,
      otcTestToken2,
      otcVesting,
    };
  }

  describe('Vesting', function () {
    it('Should fail if cliff date has not been reached', async function () {
      const { buyAddr, otcVesting } = await loadFixture(deployDegenFixture);

      await expect(
        otcVesting.connect(buyAddr).claim()
      ).to.be.revertedWithCustomError(otcVesting, 'VestingCliffDateNotReached');
    });

    it('Should claim successfully', async function () {
      const { otcTestToken2, owner, buyAddr, otcVesting } = await loadFixture(
        deployDegenFixture
      );

      const ONE_MONTH_IN_SECS = 30n * 24n * 60n * 60n;
      const vestingBeginTimestamp = await otcVesting.VESTING_BEGIN();

      await time.increaseTo(vestingBeginTimestamp + ONE_MONTH_IN_SECS);

      const vestingAmount = await otcVesting.VESTING_AMOUNT();
      await otcTestToken2
        .connect(owner)
        .transfer(otcVesting.target, vestingAmount);

      await otcVesting.connect(buyAddr).claim();

      expect(await otcTestToken2.balanceOf(buyAddr.address)).to.equal(
        151914922533282470826991374n
      );
    });
  });
});
