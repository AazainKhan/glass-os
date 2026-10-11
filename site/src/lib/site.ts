export const SITE = 'https://aazainkhan.github.io/glass-os';
export const REPO = 'https://github.com/AazainKhan/glass-os';
export const LAUNCHER_REPO = 'https://github.com/AazainKhan/glass-tv-launcher';

// Section label for breadcrumbs, matching the sidebar groups.
export const SECTIONS: Record<string, string> = {
  overview: 'Start', 'no-root': 'Start', install: 'Install', agents: 'For agents',
  troubleshooting: 'Help', quirks: 'Help', apps: 'Help', faq: 'Help', contributing: 'Project',
};

// Entry id (e.g. "install/app", "install", "overview") to a clean path without trailing slash.
export const pathFor = (id: string) => '/' + id.replace(/\/index$/, '').replace(/^index$/, '');
