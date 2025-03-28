import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2025-04-25').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0xeded530d3797db06ed479bd979e98bef3a664cd870a39cc349d6a790019fa89e';

const Airdrop2Season14 = buildModule('Airdrop2Season14', (m) => {
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

export default Airdrop2Season14;
