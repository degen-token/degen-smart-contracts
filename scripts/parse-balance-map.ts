/**
 * Slightly modified version of: https://github.com/Uniswap/merkle-distributor/blob/master/src/parse-balance-map.ts
 * Changes include:
 * - Migrating from ethers v5 to v6
 * - Migrating from es5 to es2022
 */
import { getAddress, isAddress, toBeHex } from 'ethers';
import BalanceTree from './balance-tree';

// This is the blob that gets distributed and pinned to IPFS.
// It is completely sufficient for recreating the entire merkle tree.
// Anyone can verify that all air drops are included in the tree,
// and the tree has no additional distributions.
interface MerkleDistributorInfo {
  merkleRoot: string;
  tokenTotal: string;
  claims: {
    [account: string]: {
      index: number;
      amount: string;
      proof: string[];
      flags?: {
        [flag: string]: boolean;
      };
    };
  };
}

type OldFormat = { [account: string]: number | string };
type NewFormat = { address: string; earnings: string; reasons: string };

export function parseBalanceMap(
  balances: OldFormat | NewFormat[]
): MerkleDistributorInfo {
  // if balances are in an old format, process them
  const balancesInNewFormat: NewFormat[] = Array.isArray(balances)
    ? balances
    : Object.keys(balances).map(
        (account): NewFormat => ({
          address: account,
          earnings: `0x${balances[account].toString(16)}`,
          reasons: '',
        })
      );

  const dataByAddress = balancesInNewFormat.reduce<{
    [address: string]: {
      amount: bigint;
      flags?: { [flag: string]: boolean };
    };
  }>((memo, { address: account, earnings, reasons }) => {
    if (!isAddress(account)) {
      throw new Error(`Found invalid address: ${account}`);
    }
    const parsed = getAddress(account);
    if (memo[parsed]) throw new Error(`Duplicate address: ${parsed}`);
    console.log(`Processing ${earnings} for ${account}`);
    const parsedNum = BigInt(earnings);
    if (parsedNum <= 0)
      throw new Error(`Invalid amount for account: ${account}`);

    const flags = {
      isSOCKS: reasons.includes('socks'),
      isLP: reasons.includes('lp'),
      isUser: reasons.includes('user'),
    };

    memo[parsed] = { amount: parsedNum, ...(reasons === '' ? {} : { flags }) };
    return memo;
  }, {});

  const sortedAddresses = Object.keys(dataByAddress).sort();

  // construct a tree
  const tree = new BalanceTree(
    sortedAddresses.map((address) => ({
      account: address,
      amount: dataByAddress[address].amount,
    }))
  );

  // generate claims
  const claims = sortedAddresses.reduce<{
    [address: string]: {
      amount: string;
      index: number;
      proof: string[];
      flags?: { [flag: string]: boolean };
    };
  }>((memo, address, index) => {
    const { amount, flags } = dataByAddress[address];
    memo[address] = {
      index,
      amount: toBeHex(amount),
      proof: tree.getProof(index, address, amount),
      ...(flags ? { flags } : {}),
    };
    return memo;
  }, {});

  const tokenTotal: bigint = sortedAddresses.reduce<bigint>(
    (memo, key) => memo + dataByAddress[key].amount,
    0n
  );

  return {
    merkleRoot: tree.getHexRoot(),
    tokenTotal: toBeHex(tokenTotal),
    claims,
  };
}
