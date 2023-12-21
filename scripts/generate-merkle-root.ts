/**
 * Slightly modified version of: https://github.com/Uniswap/merkle-distributor/blob/master/scripts/generate-merkle-root.ts
 * Changes include:
 * - Migrating from commander v6 to v11
 */
import { program } from 'commander';
import fs from 'fs';
import { parseBalanceMap } from './parse-balance-map';

var json;

program
  .version('0.0.0')
  .requiredOption(
    '-i, --input <path>',
    'input JSON file location containing a map of account addresses to string balances'
  );

program.parse();

json = JSON.parse(fs.readFileSync(program.opts().input, { encoding: 'utf8' }));

if (typeof json !== 'object') throw new Error('Invalid JSON');

const result = JSON.stringify(parseBalanceMap(json));
fs.writeFileSync('./airdrop/airdrop_merkle_root.json', result);

console.log(
  'Merkle root generated successfully: ./airdrop/airdrop_merkle_root.json'
);
