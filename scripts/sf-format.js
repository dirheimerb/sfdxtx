#!/usr/bin/env node


const shell = require("../dev-scripts-main/utils/shelljs");

// Simple one line command. If it needs to be customized, override script in sfdevrc file.
shell.exec('prettier --write "+(src|test)/**/*.+(ts|js|json)"');
