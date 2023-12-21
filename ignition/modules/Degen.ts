import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

export default buildModule('Degen', (m) => {
  const degenToken = m.contract('DegenToken');

  const degenAirdrop = m.contract('DegenAirdrop', [
    degenToken,
    '0xdefa96435aec82d201dbd2e5f050fb4e1fef5edac90ce1e03953f916a5e1132d',
  ]);

  return { degenToken, degenAirdrop };
});
