import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Config Vite - en dev local, on redirige /api vers le backend sur localhost:3000
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': 'http://localhost:3000',
    },
  },
});
