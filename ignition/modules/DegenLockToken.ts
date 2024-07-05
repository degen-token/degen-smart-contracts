import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Lock Constants
 */

const DegenLockToken = buildModule('DegenLockToken', (m: any) => {
  /**
   * Contracts
   */
  const degenLockToken = m.contract('DegenLockToken');

  /**
   * Transactions
   */
  return { degenLockToken };
});

export default DegenLockToken;
