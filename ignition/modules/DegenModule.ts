import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop 1 Constants
 */
const AIRDROP1_CLAIM_DEADLINE = Math.round(
  new Date('2024-05-01').getTime() / 1000
);

const AIRDROP1_MERKLE_ROOT =
  '0x04395c7a299761c2cb47a74f8b15c4c829cba9cb793c22b1ed8e63eb89fadd3b';

const AIRDROP1_TRANSFER_AMOUNT = 5544890393n * 10n ** 18n;

/**
 * Degen Token Constants
 */
const TOKEN_NEXT_MINTING_DATE = Math.round(
  new Date('2028-01-01').getTime() / 1000
);

const TokenModule = buildModule('TokenModule', (m) => {
  /**
   * Parameters
   */
  const nextMintingDate = m.getParameter(
    'nextMintingDate',
    TOKEN_NEXT_MINTING_DATE
  );

  /**
   * Contracts
   */
  const degenToken = m.contract('DegenToken', [nextMintingDate]);

  return { degenToken };
});

const DegenModule = buildModule('DegenModule', (m) => {
  const { degenToken } = m.useModule(TokenModule);

  /**
   * Parameters
   */
  const airdrop1MerkleRoot = m.getParameter(
    'airdrop1MerkleRoot',
    AIRDROP1_MERKLE_ROOT
  );
  const airdrop1ClaimDeadline = m.getParameter(
    'airdrop1ClaimDeadline',
    AIRDROP1_CLAIM_DEADLINE
  );

  /**
   * Contracts
   */
  const degenAirdrop1 = m.contract('DegenAirdrop1', [
    degenToken,
    airdrop1MerkleRoot,
    airdrop1ClaimDeadline,
  ]);

  /**
   * Transactions
   */
  m.call(degenToken, 'transfer', [degenAirdrop1, AIRDROP1_TRANSFER_AMOUNT]);

  return { degenToken, degenAirdrop1 };
});

export default DegenModule;
