import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

export default buildModule('DegenToken', (m) => {
  const degenToken = m.contract('DegenToken');

  return { degenToken };
});
