import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const MERKLE_ROOT =
  '0x1fdc478967655266cc4278ce69763296279bead96d8b67e1a2e6652f41101213';

export default buildModule('DegenModule', (m) => {
  const merkleRoot = m.getParameter('merkleRoot', MERKLE_ROOT);

  const degenToken = m.contract('DegenToken');

  const degenAirdrop = m.contract('DegenAirdrop', [degenToken, merkleRoot]);

  return { degenToken, degenAirdrop };
});
