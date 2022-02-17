

const { join } = require("path");
const { accessSync, readFileSync } = require("fs");

exports.isMultiPackageProject = function (packageRoot) {
  let isMulti = false;
  try {
    accessSync(join(packageRoot, "lerna.json"));
    isMulti = true;
  } catch (err) {
    /* do nothing */
  }
  return isMulti;
};

exports.isPlugin = function (packageRoot) {
  let isPlugin = false;
  try {
    const contents = JSON.parse(
      readFileSync(join(packageRoot, "package.json"), "utf-8")
    );
    isPlugin = contents && !!contents.oclif;
  } catch (err) {
    /* do nothing */
  }
  return isPlugin;
};
