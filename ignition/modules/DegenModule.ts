import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import { ethers, defender } from 'hardhat';

const MERKLE_ROOT =
  '0xb1cf927d4e1cbac2bf6de588d7604a88b3cc8c3db561b5cd568ccaf7c6d5c9fa';

const NEXT_MINTING_DATE = Math.round(new Date('2025-01-01').getTime() / 1000);

export default buildModule('DegenModule', async (m) => {
  const merkleRoot = m.getParameter('merkleRoot', MERKLE_ROOT);
  const nextMintingDate = m.getParameter('nextMintingDate', NEXT_MINTING_DATE);

  const DegenToken = await ethers.getContractFactory('DegenToken');
  const degenToken = await defender.deployContract(DegenToken, [
    nextMintingDate,
  ]);

  const DegenAirdrop = await ethers.getContractFactory('DegenAirdrop');
  const degenAirdrop = await defender.deployContract(DegenAirdrop, [
    degenToken.address,
    merkleRoot,
  ]);

  return { DegenToken: degenToken.address, DegenAirdrop: degenAirdrop.address };
});
