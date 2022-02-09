#!/usr/bin/env node

const shell = require("../utils/shelljs");
shell.exec(`tsc -p ./test --pretty`);
