#!/usr/bin/env node


const chalk = require("chalk");
const changed = require("../dev-scripts-main/utils/write-dependencies")();
const exists = require("../dev-scripts-main/utils/exists");

if (changed) {
  const errorHeader = chalk.red("ERROR: ");
  const errorMsg =
    "Dependencies have changed and saved to package.json. Rerun 'yarn install' to finish the install";
  // eslint-disable-next-line no-console
  console.error(chalk.bold(`\n${errorHeader}${errorMsg}\n`));
  process.exit(1);
} else {
  require("../dev-scripts-main/utils/standardize-pjson")();
  require("../dev-scripts-main/utils/standardize-files")();
  if (exists(".git")) {
    require("../dev-scripts-main/utils/husky-init")();
  }
}
