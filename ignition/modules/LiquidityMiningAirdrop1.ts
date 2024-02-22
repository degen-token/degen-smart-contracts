import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0xfee293840D23B0B2De8C55e1Cf7A9F01C157767c';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2024-04-07').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0x3a685a3bfe9f6f49f91a42878d2e85c1dfca0658e1210be045ea0ffb5471e4a1';

const LiquidityMiningAirdrop1 = buildModule('LiquidityMiningAirdrop1', (m) => {
  /**
   * Parameters
   */
  const airdropMerkleRoot = m.getParameter(
    'airdropMerkleRoot',
    AIRDROP_MERKLE_ROOT
  );
  const airdropClaimDeadline = m.getParameter(
    'airdropClaimDeadline',
    AIRDROP_CLAIM_DEADLINE
  );

  /**
   * Contracts
   */
  const degenAirdrop = m.contract('DegenAirdrop1', [
    DEGEN_TOKEN,
    airdropMerkleRoot,
    airdropClaimDeadline,
  ]);

  /**
   * Transactions
   */

  return { degenAirdrop };
});

export default LiquidityMiningAirdrop1;
