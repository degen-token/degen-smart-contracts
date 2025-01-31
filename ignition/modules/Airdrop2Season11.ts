import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0xEb54dACB4C2ccb64F8074eceEa33b5eBb38E5387';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2025-01-31').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0x5fdc1b30e66f464c412fcbba585cb59e2ea5a5fd1017f4589555e0e1e2d7000e';

const Airdrop2Season11 = buildModule('Airdrop2Season11', (m) => {
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

export default Airdrop2Season11;
