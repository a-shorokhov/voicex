import { defineConfig } from 'vite';

export default defineConfig({
  base: '/voicex/',
  build: {
    rollupOptions: {
      input: {
        main: 'index.html',
        install: 'install.html',
        privacy: 'privacy.html',
      },
    },
  },
});
