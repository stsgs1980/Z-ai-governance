# Z.ai Hooks — Introduction & Basic React Hooks

> Part of the Z.ai Hooks Complete Guide (see `sandbox-hooks-cookbook.md` for the index).

---

## Table of Contents

1. [Introduction to Hooks](#introduction-to-hooks)
2. [Basic React Hooks](#basic-react-hooks)

---

## Introduction to Hooks

**Hooks** are functions that let you "hook into" React state and lifecycle features from functional components. In the Z.ai context, hooks become a powerful tool for integrating AI capabilities into web applications.

### Advantages of Using Hooks in Z.ai

| Advantage | Description |
|-----------|-------------|
| Logic Reuse | Create custom hooks for common AI operations |
| Clean Code | Separation of logic and presentation |
| Testability | Hooks are easy to test in isolation |
| Performance | Memoization via `useCallback` and `useMemo` |
| State Management | Simple and predictable state management |

---

---

## Basic React Hooks

### useState

Manages local component state:

```typescript
const [value, setValue] = useState<T>(initialValue);
```

### useEffect

Manages side effects (API requests, subscriptions):

```typescript
useEffect(() => {
  // Runs on mount and dependency changes

  return () => {
    // Cleanup function (analogous to componentWillUnmount)
  };
}, [dependencies]);
```

### useCallback

Memoizes functions to prevent unnecessary re-renders:

```typescript
const memoizedCallback = useCallback(() => {
  doSomething(a, b);
}, [a, b]);
```

### useMemo

Memoizes computed values:

```typescript
const memoizedValue = useMemo(() => computeExpensive(a, b), [a, b]);
```

### useRef

Preserves mutable values without re-rendering:

```typescript
const containerRef = useRef<HTMLDivElement>(null);
const previousValue = useRef<T>(value);
```

---


*(Part of the Z.ai Hooks Complete Guide — see `sandbox-hooks-cookbook.md` for the full index.)*
