import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const AIRDROP1_CLAIM_DEADLINE = Math.round(
  new Date('2024-05-01').getTime() / 1000
);

const AIRDROP1_MERKLE_ROOT =
  '0x3edf309d20f61e89fa130972112cc09d88b7c2cbd599f4f8e3c7b4e06c517e63';

const AIRDROP1_TRANSFER_AMOUNT = 1000000000n * 10n ** 18n;

const TOKEN_NEXT_MINTING_DATE = Math.round(
  new Date('2025-01-01').getTime() / 1000
);

export default buildModule('DegenModule', (m) => {
  const airdrop1MerkleRoot = m.getParameter(
    'airdrop1MerkleRoot',
    AIRDROP1_MERKLE_ROOT
  );
  const nextMintingDate = m.getParameter(
    'nextMintingDate',
    TOKEN_NEXT_MINTING_DATE
  );
  const airdrop1ClaimDeadline = m.getParameter(
    'airdrop1ClaimDeadline',
    AIRDROP1_CLAIM_DEADLINE
  );

  const degenToken = m.contract('DegenToken', [nextMintingDate]);

  const degenAirdrop1 = m.contract('DegenAirdrop1', [
    degenToken,
    airdrop1MerkleRoot,
    airdrop1ClaimDeadline,
  ]);

  m.call(degenToken, 'transfer', [degenAirdrop1, AIRDROP1_TRANSFER_AMOUNT]);

  return { degenToken, degenAirdrop1 };
});
