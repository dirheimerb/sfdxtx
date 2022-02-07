#!/usr/bin/env node

const shell = require("../dev-scripts-main/utils/shelljs");

shell.exec("yarn clean");
shell.exec("yarn compile");
shell.exec("yarn lint");
