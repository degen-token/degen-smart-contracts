import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const MERKLE_ROOT =
  '0x3edf309d20f61e89fa130972112cc09d88b7c2cbd599f4f8e3c7b4e06c517e63';

const NEXT_MINTING_DATE = Math.round(new Date('2025-01-01').getTime() / 1000);

const AIRDROP1_TRANSFER_AMOUNT = 1000000000n * 10n ** 18n;

const AIRDROP1_CLAIM_DEADLINE = Math.round(
  new Date('2024-05-01').getTime() / 1000
);

export default buildModule('DegenModule', (m) => {
  const merkleRoot = m.getParameter('merkleRoot', MERKLE_ROOT);
  const nextMintingDate = m.getParameter('nextMintingDate', NEXT_MINTING_DATE);
  const airdropClaimDeadline = m.getParameter(
    'airdropClaimDeadline',
    AIRDROP1_CLAIM_DEADLINE
  );

  const degenToken = m.contract('DegenToken', [nextMintingDate]);

  const degenAirdrop = m.contract('DegenAirdrop', [
    degenToken,
    merkleRoot,
    airdropClaimDeadline,
  ]);

  m.call(degenToken, 'transfer', [degenAirdrop, AIRDROP1_TRANSFER_AMOUNT]);

  return { degenToken, degenAirdrop };
});
