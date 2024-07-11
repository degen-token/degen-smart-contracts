import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2024-07-31').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0x05c6914c3be63311d70def6b7fb29b5262432ba93ba7d94e9f2d87e65406650d';

const Airdrop2Season5 = buildModule('Airdrop2Season5', (m) => {
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

export default Airdrop2Season5;
