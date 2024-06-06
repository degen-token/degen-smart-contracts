import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop Constants
 */
const DEGEN_TOKEN = '0xEb54dACB4C2ccb64F8074eceEa33b5eBb38E5387';

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2024-08-09').getTime() / 1000
);

const AIRDROP_MERKLE_ROOT =
  '0xca8fd77360cdd4d9ec257bd1e0045d74fb8e5290b38a3b2b00dd5ccf6c92b3d7';

const LiquidityMiningAirdrop3 = buildModule('LiquidityMiningAirdrop3', (m) => {
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

export default LiquidityMiningAirdrop3;
