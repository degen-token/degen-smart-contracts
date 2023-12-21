import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const MERKLE_ROOT =
  '0xdefa96435aec82d201dbd2e5f050fb4e1fef5edac90ce1e03953f916a5e1132d';

export default buildModule('DegenModule', (m) => {
  const merkleRoot = m.getParameter('merkleRoot', MERKLE_ROOT);

  const degenToken = m.contract('DegenToken');

  const degenAirdrop = m.contract('DegenAirdrop', [degenToken, merkleRoot]);

  return { degenToken, degenAirdrop };
});
