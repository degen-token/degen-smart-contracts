import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop 1 Constants
 */
const AIRDROP1_CLAIM_DEADLINE = Math.round(
  new Date('2024-05-01').getTime() / 1000
);

const AIRDROP1_MERKLE_ROOT =
  '0xf8f388bcafbbb8fd391550b4df59d79dfa1aecc525a473ef329d023574113fd2';

const AIRDROP1_TRANSFER_AMOUNT = 1000000000n * 10n ** 18n;

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
