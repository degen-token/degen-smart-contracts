/**
 * Slightly modified version of: https://github.com/Uniswap/merkle-distributor/blob/master/scripts/generate-merkle-root.ts
 * Changes include:
 * - Migrating from commander v6 to v11
 */
import { program } from 'commander';
import fs from 'fs';
import path from 'path';
import { parseBalanceMap } from './parse-balance-map';

var json;

program
  .version('0.0.0')
  .requiredOption(
    '-i, --input <path>',
    'input JSON file location containing a map of account addresses to string balances'
  );

program.parse();

const filePath = program.opts().input;
json = JSON.parse(fs.readFileSync(filePath, { encoding: 'utf8' }));

if (typeof json !== 'object') throw new Error('Invalid JSON');

const result = JSON.stringify(parseBalanceMap(json));
const fileName = path.basename(filePath, path.extname(filePath));
fs.writeFileSync(`./airdrop/${fileName}_merkle_root.json`, result);

console.log(
  `Merkle root generated successfully: ./airdrop/${fileName}_merkle_root.json`
);
