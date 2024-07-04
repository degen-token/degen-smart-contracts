import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

/**
 * Airdrop 1 Constants
 */
const AIRDROP1_CLAIM_DEADLINE = Math.round(
  new Date('2024-05-01').getTime() / 1000
);

const AIRDROP1_MERKLE_ROOT =
  '0x04395c7a299761c2cb47a74f8b15c4c829cba9cb793c22b1ed8e63eb89fadd3b';

// For readability and compatibility, using BigInt with BigInt constructor is clearer.
// const AIRDROP1_TRANSFER_AMOUNT = 5544890393n * 10n ** 18n;
const AIRDROP1_TRANSFER_AMOUNT = BigInt(5544890393) * BigInt(10) ** BigInt(18);

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
  // The contract method is deprecated. The deployContract method is the recommended way to deploy contracts using Hardhat Ignition.
  const degenToken = m.deployContract('DegenToken', [nextMintingDate]);

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
  // The contract method is deprecated. The deployContract method is the recommended way to deploy contracts using Hardhat Ignition.
  const degenAirdrop1 = m.deployContract('DegenAirdrop1', [
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
