import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  root: 'enterprise/app/javascript/captain_booking_app',
  build: {
    outDir: path.resolve(__dirname, 'public/captain/booking'),
    emptyOutDir: true,
    manifest: true,
    rollupOptions: {
      input: path.resolve(__dirname, 'enterprise/app/javascript/captain_booking_app/index.html'),
      output: {
        entryFileNames: `assets/[name].js`,
        chunkFileNames: `assets/[name].js`,
        assetFileNames: `assets/[name].[ext]`
      }
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'enterprise/app/javascript/captain_booking_app'),
    },
  },
});
