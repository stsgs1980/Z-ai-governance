# Z.ai Hooks — Practical Cases, Best Practices & Project Structure

> Part of the Z.ai Hooks Complete Guide (see `sandbox-hooks-cookbook.md` for the index).

---

## Table of Contents

1. [Practical Cases](#practical-cases)
2. [Best Practices](#best-practices)
3. [Project Structure](#project-structure)
4. [Quick Reference](#quick-reference)
5. [Conclusion](#conclusion)

---

## Practical Cases

### Case 1: AI Assistant with History Persistence

```typescript
// app/chat/page.tsx
'use client';

import { useChat } from '@/hooks/useChat';
import { useAutoSave } from '@/hooks/useAutoSave';
import { useState, useEffect } from 'react';

interface ChatSession {
  id: string;
  messages: Array<{ role: 'user' | 'assistant'; content: string }>;
  createdAt: Date;
  updatedAt: Date;
}

export default function ChatPage() {
  const { messages, send, loading, error, clear } = useChat({
    systemPrompt: 'You are a helpful AI assistant. Answer concisely and to the point.'
  });

  const [input, setInput] = useState('');
  const [sessionId] = useState(() => crypto.randomUUID());

  // Auto-save session
  useAutoSave({
    data: { id: sessionId, messages, updatedAt: new Date() },
    saveFunction: async (data) => {
      await fetch(`/api/sessions/${data.id}`, {
        method: 'PUT',
        body: JSON.stringify(data)
      });
    },
    delay: 3000,
    onSave: () => console.log('Session saved'),
    onError: (err) => console.error('Save failed:', err)
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || loading) return;

    await send(input);
    setInput('');
  };

  return (
    <div className="max-w-2xl mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">AI Chat</h1>

      <div className="h-96 overflow-y-auto border rounded-lg p-4 mb-4">
        {messages.map((msg) => (
          <div
            key={msg.id}
            className={`mb-2 p-2 rounded ${
              msg.role === 'user'
                ? 'bg-blue-100 ml-auto max-w-xs'
                : 'bg-gray-100 max-w-xs'
            }`}
          >
            {msg.content}
          </div>
        ))}
        {loading && <div className="text-gray-500">Typing...</div>}
      </div>

      {error && (
        <div className="text-red-500 mb-2">Error: {error.message}</div>
      )}

      <form onSubmit={handleSubmit} className="flex gap-2">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          className="flex-1 border rounded-lg px-4 py-2"
          placeholder="Enter a message..."
          disabled={loading}
        />
        <button
          type="submit"
          disabled={loading || !input.trim()}
          className="bg-blue-500 text-white px-6 py-2 rounded-lg disabled:opacity-50"
        >
          Send
        </button>
      </form>

      <button
        onClick={clear}
        className="mt-4 text-sm text-gray-500 hover:text-gray-700"
      >
        Clear chat
      </button>
    </div>
  );
}
```

### Case 2: Content Generator

```typescript
// app/generator/page.tsx
'use client';

import { useState } from 'react';
import { useAI } from '@/hooks/useAI';
import { useImageGeneration } from '@/hooks/useImageGeneration';

type ContentType = 'post' | 'article' | 'ad' | 'story';

const PROMPTS: Record<ContentType, string> = {
  post: 'Write an engaging social media post about:',
  article: 'Write an article structure about:',
  ad: 'Create advertising copy for the product:',
  story: 'Create brand storytelling about:'
};

export default function GeneratorPage() {
  const [contentType, setContentType] = useState<ContentType>('post');
  const [topic, setTopic] = useState('');

  const { generate: generateText, loading: textLoading, response } = useAI();
  const { generateImage, generating: imageGenerating, imageUrl } = useImageGeneration();

  const handleGenerate = async () => {
    if (!topic.trim()) return;

    const fullPrompt = `${PROMPTS[contentType]} "${topic}"`;
    const text = await generateText(fullPrompt);

    if (text) {
      // Generate image based on text
      const imagePrompt = `Illustration for ${contentType}: ${text.substring(0, 100)}`;
      await generateImage(imagePrompt);
    }
  };

  return (
    <div className="max-w-3xl mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6">Content Generator</h1>

      <div className="grid grid-cols-4 gap-2 mb-4">
        {(['post', 'article', 'ad', 'story'] as ContentType[]).map((type) => (
          <button
            key={type}
            onClick={() => setContentType(type)}
            className={`p-2 rounded-lg border ${
              contentType === type
                ? 'bg-blue-500 text-white'
                : 'bg-white hover:bg-gray-50'
            }`}
          >
            {type === 'post' ? 'Post' :
             type === 'article' ? 'Article' :
             type === 'ad' ? 'Ad' : 'Storytelling'}
          </button>
        ))}
      </div>

      <textarea
        value={topic}
        onChange={(e) => setTopic(e.target.value)}
        className="w-full border rounded-lg p-4 mb-4 h-32"
        placeholder="Describe the topic or enter keywords..."
      />

      <button
        onClick={handleGenerate}
        disabled={textLoading || imageGenerating || !topic.trim()}
        className="w-full bg-blue-500 text-white py-3 rounded-lg disabled:opacity-50 mb-6"
      >
        {textLoading ? 'Generating text...' :
         imageGenerating ? 'Generating image...' :
         'Generate'}
      </button>

      {response && (
        <div className="bg-gray-50 rounded-lg p-6 mb-6">
          <h2 className="font-semibold mb-2">Generated text:</h2>
          <p className="whitespace-pre-wrap">{response}</p>
        </div>
      )}

      {imageUrl && (
        <div className="rounded-lg overflow-hidden">
          <img src={imageUrl} alt="Generated" className="w-full" />
        </div>
      )}
    </div>
  );
}
```

---

---

## Best Practices

### 1. Separation of Concerns

```text
[OK] Good: One hook - one responsibility
[FAIL] Bad: A huge hook with all the logic

// [OK] Good
const { data } = useFetch(url);
const { save } = useAutoSave(data);

// [FAIL] Bad
const { data, save, loading, error, ... } = useEverything();
```

### 2. Correct Dependencies in useCallback/useMemo

```typescript
// [OK] Good - all dependencies listed
const handleSubmit = useCallback(async (data: FormData) => {
  await submitForm(data);
  refreshList(); // depends on refreshList
}, [submitForm, refreshList]);

// [FAIL] Bad - missing dependencies
const handleSubmit = useCallback(async (data: FormData) => {
  await submitForm(data);
  refreshList(); // refreshList not in dependencies!
}, [submitForm]);
```

### 3. Error Handling

```typescript
// [OK] Good - full error handling
const { generate, error, loading } = useAI();

const handleGenerate = async () => {
  try {
    const result = await generate(prompt);
    // Handle success
  } catch (err) {
    // Error is already in error state
    console.error('Generation failed:', err);
  }
};

// [FAIL] Bad - no error handling
const handleGenerate = async () => {
  const result = await generate(prompt); // May throw
};
```

### 4. Request Cancellation

```typescript
// [OK] Good - AbortController support
const abortRef = useRef<AbortController | null>(null);

const fetch = async () => {
  abortRef.current = new AbortController();
  try {
    await fetch(url, { signal: abortRef.current.signal });
  } catch (err) {
    if (err.name !== 'AbortError') {
      // Handle actual error
    }
  }
};

const cancel = () => {
  abortRef.current?.abort();
};

// Cleanup on unmount
useEffect(() => {
  return () => {
    abortRef.current?.abort();
  };
}, []);
```

### 5. Typing

```typescript
// [OK] Good - full typing
interface User {
  id: string;
  name: string;
}

function useUser(id: string): {
  user: User | null;
  loading: boolean;
  error: Error | null;
} {
  // ...
}

// [FAIL] Bad - any types
function useUser(id: string): any {
  // ...
}
```

---

---

## Project Structure

```text
project/
|-- app/
|   |-- api/
|   |   +-- ai/
|   |       |-- chat/route.ts        # Chat API
|   |       |-- image/route.ts       # Image generation API
|   |       +-- search/route.ts      # Web search API
|   |-- chat/page.tsx                # Chat interface
|   |-- generator/page.tsx           # Content generator
|   +-- layout.tsx
|-- hooks/
|   |-- useAI.ts                     # Text generation hook
|   |-- useImageGeneration.ts        # Image generation hook
|   |-- useChat.ts                   # Chat with history hook
|   |-- useAutoSave.ts               # Auto-save hook
|   |-- useDebounce.ts               # Debounce utility hook
|   +-- useFetch.ts                  # Data fetching hook
|-- lib/
|   |-- ai-client.ts                 # AI client utilities
|   |-- rateLimiter.ts               # Rate limiting
|   +-- validators.ts                # Input validation
|-- types/
|   +-- ai.ts                        # AI-related types
+-- middleware.ts                    # Global middleware hooks
```

---

---

## Quick Reference

| Task | Hook | Example Usage |
|------|------|---------------|
| Text generation | `useAI` | `const { generate } = useAI()` |
| Image generation | `useImageGeneration` | `const { generateImage } = useImageGeneration()` |
| Chat with history | `useChat` | `const { messages, send } = useChat()` |
| Auto-save | `useAutoSave` | `useAutoSave({ data, saveFunction })` |
| Debounced value | `useDebounce` | `const debounced = useDebounce(value, 300)` |
| Request cancellation | `AbortController` | `controller.abort()` |

---

---

## Conclusion

Hooks in Z.ai are a powerful tool for creating AI-integrated applications. By following the patterns and practices presented here, you can write clean, maintainable, and performant code.

### Key Principles:

1. **Modularity** - each hook is responsible for one task
2. **Reusability** - extract common logic into custom hooks
3. **Typing** - use TypeScript for reliability
4. **Error Handling** - always provide fallback behavior
5. **Performance** - memoize functions and values

---


*(Part of the Z.ai Hooks Complete Guide — see `sandbox-hooks-cookbook.md` for the full index.)*
