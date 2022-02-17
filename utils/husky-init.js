const fs = require("fs");
const path = require("path");
const chalk = require("chalk");
const packagePath = require("../utils/package-path");
const shell = require("./shelljs");

// This should be in each package's `prepare` script but we already use it to run `sf-install`.
shell.exec("yarn husky install");

function initializeHusky() {
  try {
    const localGitHooks = fs
      .readdirSync(path.normalize(`${packagePath}${path.sep}.husky`))
      .filter((hook) => hook !== "_");

    if (localGitHooks.length === 0) {
      shell.exec("yarn husky add .husky/commit-msg 'yarn commitlint --edit'");
      shell.exec(
        "yarn husky add .husky/pre-commit 'yarn lint && yarn pretty-quick --staged'"
      );
      shell.exec(
        "yarn husky add .husky/pre-push 'yarn build && yarn test --forbid-only'"
      );
    }
  } catch (err) {
    if (err.code === "ENOENT") {
      const errorHeader = chalk.red("ERROR: ");
      const errorMsg =
        ".husky folder wasn't found, try running `yarn husky install` to finish the install";
      // eslint-disable-next-line no-console
      console.error(chalk.bold(`\n${errorHeader}${errorMsg}\n`));
      process.exit(1);
    }
    throw err;
  }
}

module.exports = initializeHusky;
