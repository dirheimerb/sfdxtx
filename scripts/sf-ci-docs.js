#!/usr/bin/env node


const path = require("path");
const shell = require("../dev-scripts-main/utils/shelljs");
const packageRoot = require("../dev-scripts-main/utils/package-path");
const {
  isMultiPackageProject,
} = require("../dev-scripts-main/utils/project-type");

shell.set("-e");

shell.cd(packageRoot);

shell.rm("-rf", "docs");
shell.exec("git worktree prune");

shell.exec("git fetch origin gh-pages:gh-pages");
shell.exec("git worktree add docs gh-pages");
shell.exec("yarn docs");

if (isMultiPackageProject(packageRoot)) {
  shell.exec("cp README.md docs");
}

shell.set("+e");

shell.cd(path.join(packageRoot, "docs"));

shell.exec("git add .");
shell.exec('git commit -m "docs: publishing gh-pages [skip ci]"');
shell.exec("git push origin gh-pages");

shell.set("-e");
