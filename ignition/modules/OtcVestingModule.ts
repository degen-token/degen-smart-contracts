import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const BUYER = '0xf1E7DBEDD9e06447e2F99B1310c09287b734addc';
const VESTING_START = Math.round(new Date('2024-02-12').getTime() / 1000);
const VESTING_CLIFF = Math.round(new Date('2024-03-12').getTime() / 1000);
const VESTING_END = Math.round(new Date('2025-02-12').getTime() / 1000);
const VESTING_AMOUNT = 100n * 10n ** 18n;
const DEGEN_ADDRESS = '0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed';

const OtcVestingModule = buildModule('OtcVestingModule', (m) => {
  /**
   * Parameters
   */
  const buyer = m.getParameter('buyer', BUYER);
  const vestingStart = m.getParameter('vestingStart', VESTING_START);
  const vestingCliff = m.getParameter('vestingCliff', VESTING_CLIFF);
  const vestingEnd = m.getParameter('vestingEnd', VESTING_END);
  const degenAddress = m.getParameter('degenAddress', DEGEN_ADDRESS);

  const otcVesting = m.contract('OtcVesting', [
    degenAddress,
    buyer,
    VESTING_AMOUNT,
    vestingStart,
    vestingCliff,
    vestingEnd,
  ]);

  return { otcVesting };
});

export default OtcVestingModule;
