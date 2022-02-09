import { applyPlugins } from 'plugins-manager';
import { rocketLaunch } from '@rocket/launch';
import { rocketBlog } from '@rocket/blog';
import { rocketSearch } from '@rocket/search';

/** @type {import('@rocket/cli').RocketCliOptions} */
export default ({
    setupEleventyComputedConfig: [
        addPlugin({ name: 'greeting', plugin: data => `Welcome to the ${data.title} page.` }),
    presets: [rocketLaunch(), rocketBlog(), rocketSearch(), codeTabs({
        collections: {
          packageManagers: {
            npm: { label: 'NPM', iconHref: '/_merged_assets/brand-logos/npm.svg' },
            yarn: { label: 'Yarn', iconHref: '/_merged_assets/brand-logos/yarn.svg' },
            pnpm: { label: 'PNPM', iconHref: '/_merged_assets/brand-logos/pnpm.svg' },
        ],
  });