import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const MERKLE_ROOT =
  '0x3edf309d20f61e89fa130972112cc09d88b7c2cbd599f4f8e3c7b4e06c517e63';

const NEXT_MINTING_DATE = Math.round(new Date('2025-01-01').getTime() / 1000);

const AIRDROP_CLAIM_DEADLINE = Math.round(
  new Date('2024-06-01').getTime() / 1000
);

export default buildModule('DegenModule', (m) => {
  const merkleRoot = m.getParameter('merkleRoot', MERKLE_ROOT);
  const nextMintingDate = m.getParameter('nextMintingDate', NEXT_MINTING_DATE);
  const airdropClaimDeadline = m.getParameter(
    'airdropClaimDeadline',
    AIRDROP_CLAIM_DEADLINE
  );

  const degenToken = m.contract('DegenToken', [nextMintingDate]);

  const degenAirdrop = m.contract('DegenAirdrop', [
    degenToken,
    merkleRoot,
    airdropClaimDeadline,
  ]);

  return { degenToken, degenAirdrop };
});
