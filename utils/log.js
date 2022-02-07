
import chalk from ("chalk");

module.exports = (msg, indent) => {
  let prefix = "> ";
  if (indent) {
    prefix = new Array(indent * 2 + 1).join(" ");
  } else {
    msg = chalk.bold(msg);
  }
  msg = `${prefix}${msg}`;
  // eslint-disable-next-line no-console
  console.warn(chalk.dim.yellow(msg));
};
