import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2024-04-30').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0x12f4a3a18409b4bdd22f1f927a0dabbfe75afc67e33a263330272a1e9d0ba221';

const Airdrop2Season2 = buildModule('Airdrop2Season2', (m) => {
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

export default Airdrop2Season2;
