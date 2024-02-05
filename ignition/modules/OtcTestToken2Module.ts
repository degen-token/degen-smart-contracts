import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const OtcTestToken2Module = buildModule('OtcTestToken2Module', (m) => {
  const otcTestToken2 = m.contract('OtcTestToken2');

  return { otcTestToken2 };
});

export default OtcTestToken2Module;
