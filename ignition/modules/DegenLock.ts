import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Lock Constants
 */
const DEGEN_TOKEN = '0xfee293840D23B0B2De8C55e1Cf7A9F01C157767c';
const DEPOSIT_DEADLINE = Math.round(new Date('2024-07-01').getTime() / 1000);
const LOCK_DURATION = 60 * 60; // 1 hour
const NAME = 'Locked Degen';
const SYMBOL = 'LDEGEN';

const DegenLock = buildModule('DegenLock', (m: any) => {
  const degenToken = m.getParameter('degenToken', DEGEN_TOKEN);
  const depositDeadline = m.getParameter('depositDeadline', DEPOSIT_DEADLINE);
  const lockDuration = m.getParameter('lockDuration', LOCK_DURATION);
  const name = m.getParameter('name', NAME);
  const symbol = m.getParameter('symbol', SYMBOL);

  /**
   * Contracts
   */
  const degenLock = m.contract('DegenLock', [
    degenToken,
    depositDeadline,
    lockDuration,
    name,
    symbol,
  ]);

  /**
   * Transactions
   */

  return { degenLock };
});

export default DegenLock;
