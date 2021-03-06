/** @type {import("../../../").Configuration} */
module.exports = {
	mode: "production",
	entry: "./index.js",
	module: {
		rules: [
			{
				test: /\.(png|jpg|svg)$/,
				type: "asset"
			},
			{
				test: /\.html$/,
				type: "asset/resource",
				generator: {
					filename: "static/[name][ext]"
				}
			},
			{
				mimetype: "text/plain",
				type: "asset"
			}
		]
	},
	output: {
		filename: "bundle.js"
	}
};
