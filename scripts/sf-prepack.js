#!/usr/bin/env node


const chalk = require("chalk");
const shell = require("../dev-scripts-main/utils/shelljs");
const { isPlugin } = require("../dev-scripts-main/utils/project-type");
const packageRoot = require("../dev-scripts-main/utils/package-path");

shell.exec("yarn build");

if (isPlugin(packageRoot)) {
  if (shell.which("oclif")) {
    shell.exec("oclif manifest .");
  } else if (shell.which("oclif-dev")) {
    shell.exec("oclif-dev manifest");
  } else {
    // eslint-disable-next-line no-console
    console.log(
      chalk.red("Failed:"),
      "Cannot generate oclif.manifest.json because oclif is not installed."
    );
    process.exitCode = 1;
  }
}
