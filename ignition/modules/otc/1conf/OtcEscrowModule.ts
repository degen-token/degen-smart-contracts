import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const BUYER = '0xD049b3064990869C9F73bD7896271d83325D2067';
const SELLER = '0x704Ec5C12Ca20a293C2C0B72B22619A4231f3c0d';
const VESTING_START = Math.round(new Date('2024-02-12').getTime() / 1000);
const VESTING_CLIFF = Math.round(new Date('2024-08-12').getTime() / 1000);
const VESTING_END = Math.round(new Date('2026-02-12').getTime() / 1000);
const WETH_AMOUNT = 435n * 10n ** 18n; // 435 WETH
const DEGEN_AMOUNT = 1848296798n * 10n ** 18n; // 1,848,296,798 DEGEN
const WETH_ADDRESS = '0x4200000000000000000000000000000000000006';
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
    DEGEN_AMOUNT,
    vestingStart,
    vestingCliff,
    vestingEnd,
  ]);

  return { otcVesting };
});

const OtcEscrowModule = buildModule('OtcEscrowModule', (m) => {
  const { otcVesting } = m.useModule(OtcVestingModule);

  /**
   * Parameters
   */
  const buyer = m.getParameter('buyer', BUYER);
  const seller = m.getParameter('seller', SELLER);
  const wethAddress = m.getParameter('wethAddress', WETH_ADDRESS);
  const degenAddress = m.getParameter('degenAddress', DEGEN_ADDRESS);

  const otcEscrow = m.contract('OtcEscrow', [
    buyer,
    seller,
    otcVesting,
    WETH_AMOUNT,
    DEGEN_AMOUNT,
    wethAddress,
    degenAddress,
  ]);

  return { otcEscrow };
});

export default OtcEscrowModule;
export { OtcVestingModule };
