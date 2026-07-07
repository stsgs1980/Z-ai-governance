import { describe, it, expect } from "vitest";
import { readFileSync, existsSync, readdirSync } from "fs";
import { join } from "path";

const pkg = JSON.parse(readFileSync("package.json", "utf-8"));
const root = ".";

describe("z-ai-platform infrastructure", () => {
  // --- package.json ---
  describe("package.json", () => {
    it("has correct name z-ai-platform", () => {
      expect(pkg.name).toBe("z-ai-platform");
    });

    it("is private (not publishable)", () => {
      expect(pkg.private).toBe(true);
    });

    it("requires Node.js 20+", () => {
      expect(pkg.engines.node).toMatch(/^>=20/);
    });

    it("declares expected devDependencies", () => {
      const deps = pkg.devDependencies;
      expect(deps).toHaveProperty("typescript");
      expect(deps).toHaveProperty("eslint");
      expect(deps).toHaveProperty("prettier");
      expect(deps).toHaveProperty("vitest");
      expect(deps).toHaveProperty("husky");
    });

    it("declares lint and test scripts", () => {
      expect(pkg.scripts).toHaveProperty("lint");
      expect(pkg.scripts).toHaveProperty("test");
      expect(pkg.scripts).toHaveProperty("typecheck");
    });
  });

  // --- tsconfig.json ---
  describe("tsconfig.json", () => {
    const tsconfig = JSON.parse(readFileSync("tsconfig.json", "utf-8"));

    it("has strict mode enabled", () => {
      expect(tsconfig.compilerOptions.strict).toBe(true);
    });

    it("targets ES2022+", () => {
      expect(tsconfig.compilerOptions.target).toMatch(/ES202[2-9]/);
    });

    it("uses ESNext modules", () => {
      expect(tsconfig.compilerOptions.module).toBe("ESNext");
    });
  });

  // --- .gitignore ---
  describe(".gitignore", () => {
    const gitignore = readFileSync(".gitignore", "utf-8");

    it("excludes .env files", () => {
      expect(gitignore).toContain(".env");
      expect(gitignore).toContain(".env.local");
    });

    it("excludes node_modules/", () => {
      expect(gitignore).toContain("node_modules/");
    });

    it("excludes build artifacts", () => {
      expect(gitignore).toContain("dist/");
      expect(gitignore).toContain("build/");
    });

    it("excludes .zscripts/", () => {
      expect(gitignore).toContain(".zscripts/");
    });
  });

  // --- .env is not tracked ---
  it(".env is not tracked by git", () => {
    const { execSync } = require("child_process");
    const tracked = execSync("git ls-files .env", { encoding: "utf-8" }).trim();
    expect(tracked).toBe("");
  });

  // --- prettier config ---
  describe("prettier config", () => {
    const prettierrc = JSON.parse(readFileSync(".prettierrc", "utf-8"));

    it("exists with expected properties", () => {
      expect(prettierrc).toHaveProperty("semi");
      expect(prettierrc).toHaveProperty("printWidth");
      expect(prettierrc).toHaveProperty("tabWidth");
    });

    it("uses LF line endings", () => {
      expect(prettierrc.endOfLine).toBe("lf");
    });
  });

  // --- AGENT_RULES.md (single entry point) ---
  describe("AGENT_RULES.md", () => {
    it("exists and is non-empty", () => {
      expect(existsSync("AGENT_RULES.md")).toBe(true);
      const content = readFileSync("AGENT_RULES.md", "utf-8");
      expect(content.length).toBeGreaterThan(100);
    });

    it("references correct skill catalog path (skills/INDEX.md)", () => {
      const content = readFileSync("AGENT_RULES.md", "utf-8");
      expect(content).toContain("skills/INDEX.md");
      // Must NOT contain the old double-nested path
      expect(content).not.toContain("skills/skills/INDEX.md");
    });
  });

  // --- Flat repo directories exist ---
  describe("core directories", () => {
    it("standards/ directory exists", () => {
      expect(existsSync("standards")).toBe(true);
    });

    it("guard/ directory exists", () => {
      expect(existsSync("guard")).toBe(true);
    });

    it("skills/ directory exists with SKILL.md files", () => {
      expect(existsSync("skills")).toBe(true);
      const entries = readdirSync("skills", { withFileTypes: true })
        .filter((d) => d.isDirectory());
      expect(entries.length).toBeGreaterThan(0);
    });

    it("standards/ has verify-standards.js", () => {
      expect(existsSync("standards/scripts/verify-standards.js")).toBe(true);
    });

    it("standards/ has verify-id-graph.js", () => {
      expect(existsSync("standards/scripts/verify-id-graph.js")).toBe(true);
    });
  });

  // --- guard/registry.json references real files ---
  describe("guard/registry.json", () => {
    const registry = JSON.parse(readFileSync("guard/registry.json", "utf-8"));

    it("is valid JSON with ids array", () => {
      expect(Array.isArray(registry.ids)).toBe(true);
      expect(registry.ids.length).toBeGreaterThan(0);
    });

    it("every ACTIVE entry with a real file path points to an existing file", () => {
      const missing: string[] = [];
      for (const entry of registry.ids) {
        if (entry.status === "RETIRED") continue;
        if (entry.file.startsWith("(")) continue; // marked as removed
        if (!existsSync(entry.file)) {
          missing.push(`${entry.id} -> ${entry.file}`);
        }
      }
      expect(missing).toEqual([]);
    });
  });

  // --- .husky hooks (consolidated under Husky in 01e4e97) ---
  describe(".husky", () => {
    it("has pre-commit hook", () => {
      expect(existsSync(".husky/pre-commit")).toBe(true);
    });

    it("has commit-msg hook", () => {
      expect(existsSync(".husky/commit-msg")).toBe(true);
    });
  });

  // --- CI workflows ---
  describe(".github/workflows", () => {
    it("has verify-id-graph.yml", () => {
      expect(existsSync(".github/workflows/verify-id-graph.yml")).toBe(true);
    });

    it("has e2e-verifiers.yml", () => {
      expect(existsSync(".github/workflows/e2e-verifiers.yml")).toBe(true);
    });

    it("verify-id-graph.yml triggers on push to main", () => {
      const content = readFileSync(".github/workflows/verify-id-graph.yml", "utf-8");
      expect(content).toContain("branches: [main]");
    });
  });
});
