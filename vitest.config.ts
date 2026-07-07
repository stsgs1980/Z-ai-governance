import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // No setup file -- parent sandbox has vitest.setup.ts that does not
    // apply to this project. Keep tests self-contained.
  },
  css: {
    postcss: {
      // Prevent parent sandbox postcss.config.mjs bleed
      plugins: [],
    },
  },
});
