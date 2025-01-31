import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0xEb54dACB4C2ccb64F8074eceEa33b5eBb38E5387';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2025-02-28').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0x48450652488c74edf5f3eaea8f9ee79706ff0a5ec53b1953438ac342ca9e5637';

const Airdrop2Season12 = buildModule('Airdrop2Season12', (m) => {
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

export default Airdrop2Season12;
