import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Lock Constants
 */
const DEGEN_TOKEN = '0xfee293840D23B0B2De8C55e1Cf7A9F01C157767c';

const DegenLockToken = buildModule('DegenLockToken', (m: any) => {
  const degenToken = m.getParameter('degenToken', DEGEN_TOKEN);

  /**
   * Contracts
   */
  const degenLockToken = m.contract('DegenLockToken', [degenToken]);

  /**
   * Transactions
   */
  return { degenLockToken };
});

export default DegenLockToken;
