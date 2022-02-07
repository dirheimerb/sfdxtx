#!/usr/bin/env node


const shell = require("../utils/shelljs");
const packageRoot = require("../utils/package-path");
const { resolveConfig } = require("../utils/sf-config");

const nyc = require.resolve("nyc/bin/nyc");
const mocha = require.resolve("mocha/bin/mocha");

const config = resolveConfig(packageRoot);
const testConfig = config.test || {};
const includes = testConfig.testsPath || "test/**/*.test.ts";

const command = `node ${nyc} ${mocha} "${includes}"`;

try {
  shell.exec(command, {
    cwd: packageRoot,
    passthrough: true,
  });
} catch (err) {
  process.exitCode = 1;
}
