import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const OtcTestToken1Module = buildModule('OtcTestToken1Module', (m) => {
  const otcTestToken1 = m.contract('OtcTestToken1');

  return { otcTestToken1 };
});

export default OtcTestToken1Module;
