# Z.ai Hooks Complete Guide

> Practical guide to using React Hooks and hook patterns in the Z.ai environment for developing AI-integrated applications.

---

## How to Use This Guide

This guide is split into 4 thematic sub-files. Each sub-file is loaded on demand — **do NOT load all 4 into context at once**. Use the table below to pick the file you need, then open it.

---

## File Index

| File | Theme | Sections | When to load |
|------|-------|----------|--------------|
| [`hooks-basic.md`](hooks-basic.md) | Introduction & Basic React Hooks | §1-2 | First read — useState/useEffect/useCallback/useMemo/useRef basics |
| [`hooks-ai.md`](hooks-ai.md) | Custom AI Hooks | §3 | useAI/useImageGeneration/useChat/useAutoSave/useDebounce |
| [`hooks-routes.md`](hooks-routes.md) | API Routes & Middleware | §4-5 | Next.js /api/ai/* route handlers + middleware.ts |
| [`hooks-patterns.md`](hooks-patterns.md) | Practical Cases, Best Practices & Project Structure | §6-8 + Quick Ref + Conclusion | Full chat-app example, content generator, do/don't patterns, project tree |

---

## Quick Hook Lookup

| Need | Hook | Sub-file |
|------|------|----------|
| Local component state | `useState` | `hooks-basic.md` |
| Side effects / API calls | `useEffect` | `hooks-basic.md` |
| Memoize function | `useCallback` | `hooks-basic.md` |
| Memoize value | `useMemo` | `hooks-basic.md` |
| Mutable ref | `useRef` | `hooks-basic.md` |
| Text generation | `useAI` | `hooks-ai.md` |
| Image generation | `useImageGeneration` | `hooks-ai.md` |
| Chat with history | `useChat` | `hooks-ai.md` |
| Auto-save | `useAutoSave` | `hooks-ai.md` |
| Debounced value | `useDebounce` | `hooks-ai.md` |
| /api/ai/chat route | POST handler | `hooks-routes.md` |
| /api/ai/image route | POST handler | `hooks-routes.md` |
| /api/ai/search route | POST handler | `hooks-routes.md` |
| Logging middleware | `middleware.ts` | `hooks-routes.md` |
| Rate limiting | `checkRateLimit` | `hooks-routes.md` |
| Full chat-app example | `app/chat/page.tsx` | `hooks-patterns.md` |
| Content generator example | `app/generator/page.tsx` | `hooks-patterns.md` |
| Do/don't patterns | Best Practices §1-5 | `hooks-patterns.md` |
| Project tree | Project Structure | `hooks-patterns.md` |

---

## Related Files

- [`sandbox-guide.md`](sandbox-guide.md) — high-level sandbox usage guide
- [`sandbox-commands-cheatsheet.md`](sandbox-commands-cheatsheet.md) — Linux command reference (split into 4 sub-files)
- [`sandbox-subagents-architecture.md`](sandbox-subagents-architecture.md) — subagent orchestration

---

*Part of the Z.ai Sandbox documentation. Original 1011-line guide split into 4 thematic sub-files for on-demand loading.*
