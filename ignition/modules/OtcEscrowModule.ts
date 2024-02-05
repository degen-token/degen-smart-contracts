import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const BUYER = '0xf1E7DBEDD9e06447e2F99B1310c09287b734addc';
const SELLER = '0xeE6fb338E75C43cc9153FF86600700459e9871Da';
const VESTING_START = Math.round(new Date('2024-02-06').getTime() / 1000);
const VESTING_CLIFF = Math.round(new Date('2024-03-06').getTime() / 1000);
const VESTING_END = Math.round(new Date('2025-02-06').getTime() / 1000);
const WETH_AMOUNT = 1n * 10n ** 18n;
const DEGEN_AMOUNT = 100n * 10n ** 18n;
const WETH_ADDRESS = '';
const DEGEN_ADDRESS = '0x48A6c824140A68E1892E6bc7A6A3066758116Eb3';

const OtcEscrowModule = buildModule('OtcEscrowModule', (m) => {
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
    VESTING_START,
    VESTING_CLIFF,
    VESTING_END,
    WETH_AMOUNT,
    DEGEN_AMOUNT,
    wethAddress,
    degenAddress,
  ]);

  return { otcEscrow };
});

export default OtcEscrowModule;
