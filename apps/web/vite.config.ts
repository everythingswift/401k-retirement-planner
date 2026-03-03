import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  // Required for GitHub Pages: assets are served from the repo sub-path.
  base: process.env.NODE_ENV === "production" ? "/401k-retirement-planner/" : "/",
  resolve: {
    alias: {
      // Allows Vite to resolve the workspace package from source during dev,
      // avoiding the need to rebuild @retirement/core on every change.
      "@retirement/core": new URL(
        "../../packages/core/src/index.ts",
        import.meta.url
      ).pathname,
    },
  },
});
