import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Degen token contract', function () {
  it('Deployment should assign the total supply of tokens to the owner', async function () {
    const [owner] = await ethers.getSigners();

    const degenToken = await ethers.deployContract('DegenToken');

    const ownerBalance = await degenToken.balanceOf(owner.address);
    expect(await degenToken.totalSupply()).to.equal(ownerBalance);
  });
});
