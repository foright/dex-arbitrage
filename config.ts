
import fs from 'fs';
import path from 'path';
import { Config } from './arb';

const pairsFile = path.join(__dirname, `/.config.json`);
let config: Config  =JSON.parse(fs.readFileSync(pairsFile, 'utf-8'));
 
export default config;
