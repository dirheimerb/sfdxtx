
module.exports = (map) => {
  const ordered = {};
  Object.keys(map)
    .sort()
    .forEach((key) => {
      ordered[key] = map[key];
    });
  return ordered;
};
