import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2025-04-25').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0x46263acbace0bfee3c8ecebe4de478f0c48221495f39e602cbb88e652b10c0f9';

const RaindropSeason5 = buildModule('RaindropSeason5', (m) => {
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

export default RaindropSeason5;
