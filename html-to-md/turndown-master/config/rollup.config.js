import commonjs from '@rollup/plugin-commonjs'
import replace from '@rollup/plugin-replace'
import resolve from '@rollup/plugin-node-resolve'

export default function (config) {
  return {
    input: 'src/turndown.js',
    output: config.output,
    external: false,
    preserveSymlinks: true,
    plugins: [
      json(),
      commonjs({
        transformMixedEsModules: true,
        sourceMap: true
      }),
      replace({ 'process.browser': JSON.stringify(!!config.browser), preventAssignment: true }),
      resolve()
    ]
  }
}
