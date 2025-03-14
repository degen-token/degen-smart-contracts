import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0xEb54dACB4C2ccb64F8074eceEa33b5eBb38E5387';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2025-04-18').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0x0bc58f7e2e7d370ed9332c2317c81fded0542c86a8812f5178b04718a10f2a51';

const LiquidityMiningAirdrop7 = buildModule('LiquidityMiningAirdrop7', (m) => {
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

export default LiquidityMiningAirdrop7;
