
const { accessSync } = require("fs");
const { dirname, join } = require("path");

module.exports = (fileName, cwd) => {
  let currentPath = cwd;
  if (!currentPath) {
    currentPath = process.cwd();
  }

  let projectRootPath;
  while (!projectRootPath) {
    try {
      const path = join(currentPath, fileName);
      accessSync(path);
      projectRootPath = currentPath;
    } catch (err) {
      // Pop one off
      currentPath = dirname(currentPath);
      if (currentPath === "/") {
        throw new Error(`${fileName} root not found`);
      }
    }
  }
  return projectRootPath;
};
