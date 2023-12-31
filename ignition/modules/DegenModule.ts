import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const MERKLE_ROOT =
  '0xb1cf927d4e1cbac2bf6de588d7604a88b3cc8c3db561b5cd568ccaf7c6d5c9fa';

export default buildModule('DegenModule', (m) => {
  const merkleRoot = m.getParameter('merkleRoot', MERKLE_ROOT);

  // Get the time for January 1, 2025 in seconds since the Unix Epoch
  const nextMintingDate = Math.round(new Date('2025-01-01').getTime() / 1000);

  const degenToken = m.contract('DegenToken', [nextMintingDate]);

  const degenAirdrop = m.contract('DegenAirdrop', [degenToken, merkleRoot]);

  return { degenToken, degenAirdrop };
});
