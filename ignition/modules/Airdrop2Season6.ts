import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2024-08-30').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0x8c603e4eb39778900476dc8733965affdbe8c2580ea919a6fe3255e9a7ae6881';

const Airdrop2Season6 = buildModule('Airdrop2Season6', (m) => {
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

export default Airdrop2Season6;
