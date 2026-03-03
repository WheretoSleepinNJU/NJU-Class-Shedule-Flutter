#!/usr/bin/env node
/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');
const vm = require('vm');

function read(file) {
  return fs.readFileSync(path.resolve(process.cwd(), file), 'utf8');
}

function main() {
  const parserPath = process.argv[2];
  const providerDataPath = process.argv[3];
  if (!parserPath || !providerDataPath) {
    console.error('Usage: node test_parser.js <parser.js> <provider_result.txt>');
    process.exit(1);
  }

  const parserCode = read(parserPath);
  const providerResult = read(providerDataPath);
  const context = {
    console,
    JSON,
    scheduleHtmlParser: undefined,
  };
  vm.createContext(context);
  vm.runInContext(parserCode, context, { timeout: 2000 });

  if (typeof context.scheduleHtmlParser !== 'function') {
    throw new Error('scheduleHtmlParser is not defined.');
  }

  const result = context.scheduleHtmlParser(providerResult);
  const text = JSON.stringify(result, null, 2);
  console.log(text);
}

main();
