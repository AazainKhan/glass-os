import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightLlmsTxt from 'starlight-llms-txt';

// GitHub Pages location is a placeholder until the public repo exists.
export default defineConfig({
  site: 'https://aazainkhan.github.io',
  base: '/glass-os',
  integrations: [
    starlight({
      title: 'Glass',
      description:
        'An open-source, Apple TV-style home screen for Fire TV and Android TV, with install paths from a plain APK up to a custom Fire OS image.',
      customCss: ['./src/styles/docs.css'],
      components: { Header: './src/components/Header.astro' },
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/AazainKhan/glass-tv-launcher' }],
      plugins: [
        starlightLlmsTxt({
          projectName: 'Glass',
          description:
            'Glass is an open-source, Apple TV-style launcher for Fire TV and Android TV, plus optional rooted (Glass Pro) and custom-image (Glass OS) tiers.',
          details:
            'Runbooks are executable: an agent can follow them step by step against a connected stick, and every step has a verification command with expected output. Guides explain. When a guide and a runbook disagree, trust the runbook and tell the user. Anything marked "coming soon" is not built yet: do not attempt it.',
          promote: ['agents/**', 'install/**', 'index*'],
          customSets: [
            {
              label: 'Runbooks',
              description: 'step-by-step, verifiable procedures for an agent working on a connected stick',
              paths: ['agents/**'],
            },
            {
              label: 'Install guides',
              description: 'human install guides for each tier',
              paths: ['install/**', 'no-root'],
            },
          ],
        }),
      ],
      sidebar: [
        { label: 'Start', items: ['overview', 'no-root'] },
        {
          label: 'Install',
          items: [
            'install',
            'install/tier-0-apk',
            'install/tier-1-adb',
            'install/tier-2-glass-pro',
            'install/tier-3-glass-os',
          ],
        },
        { label: 'For agents', items: ['agents', 'agents/runbook'] },
        { label: 'Help', items: ['troubleshooting', 'quirks', 'apps', 'faq'] },
        { label: 'Project', items: ['contributing'] },
      ],
    }),
  ],
});
