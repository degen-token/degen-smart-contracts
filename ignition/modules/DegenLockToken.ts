import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Lock Constants
 */
const DEGEN_TOKEN = '0xfee293840D23B0B2De8C55e1Cf7A9F01C157767c';
const DEPOSIT_DEADLINE = Math.round(new Date('2024-07-02').getTime() / 1000);
const LOCK_DURATION = 60 * 60; // 1 hour

const DegenLockToken = buildModule('DegenLockToken', (m: any) => {
  const degenToken = m.getParameter('degenToken', DEGEN_TOKEN);
  const depositDeadline = m.getParameter('depositDeadline', DEPOSIT_DEADLINE);
  const lockDuration = m.getParameter('lockDuration', LOCK_DURATION);

  /**
   * Contracts
   */
  const degenLockToken = m.contract('DegenLockToken', [
    degenToken,
    depositDeadline,
    lockDuration,
  ]);

  /**
   * Transactions
   */
  return { degenLockToken };
});

export default DegenLockToken;
