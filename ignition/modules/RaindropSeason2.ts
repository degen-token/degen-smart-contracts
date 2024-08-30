import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0xEb54dACB4C2ccb64F8074eceEa33b5eBb38E5387';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2024-09-27').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0xfdca6d6c6fe0b8163827b8472e29b53685c237de9124d113059f9aff6512d403';

const RaindropSeason2 = buildModule('RaindropSeason2', (m) => {
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

export default RaindropSeason2;
