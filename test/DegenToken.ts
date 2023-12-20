import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Degen token contract', function () {
  async function deployTokenFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const degenToken = await ethers.deployContract('DegenToken');

    // Fixtures can return anything you consider useful for your tests
    return { degenToken, owner, addr1, addr2 };
  }
  it('Should assign the total supply of tokens to the owner', async function () {
    const { degenToken, owner } = await loadFixture(deployTokenFixture);

    const ownerBalance = await degenToken.balanceOf(owner.address);
    expect(await degenToken.totalSupply()).to.equal(ownerBalance);
  });
});
