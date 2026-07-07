# Z.ai Hooks — Custom AI Hooks

> Part of the Z.ai Hooks Complete Guide (see `sandbox-hooks-cookbook.md` for the index).

---

## Table of Contents

1. [Custom AI Hooks](#custom-ai-hooks)

---

## Custom AI Hooks

### useAI - Text Generation Hook

```typescript
// hooks/useAI.ts
import { useState, useCallback } from 'react';

interface UseAIOptions {
  systemPrompt?: string;
  temperature?: number;
  maxTokens?: number;
}

interface UseAIReturn {
  generate: (prompt: string) => Promise<string>;
  loading: boolean;
  error: Error | null;
  response: string;
  reset: () => void;
}

export function useAI(options: UseAIOptions = {}): UseAIReturn {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [response, setResponse] = useState<string>('');

  const generate = useCallback(async (prompt: string): Promise<string> => {
    setLoading(true);
    setError(null);

    try {
      const res = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          prompt,
          systemPrompt: options.systemPrompt,
          temperature: options.temperature,
          maxTokens: options.maxTokens
        })
      });

      if (!res.ok) {
        throw new Error(`API Error: ${res.status}`);
      }

      const data = await res.json();
      setResponse(data.content);
      return data.content;
    } catch (err) {
      const error = err as Error;
      setError(error);
      throw error;
    } finally {
      setLoading(false);
    }
  }, [options.systemPrompt, options.temperature, options.maxTokens]);

  const reset = useCallback(() => {
    setResponse('');
    setError(null);
    setLoading(false);
  }, []);

  return { generate, loading, error, response, reset };
}
```

### useImageGeneration - Image Generation Hook

```typescript
// hooks/useImageGeneration.ts
import { useState, useCallback } from 'react';

type ImageSize = '1024x1024' | '768x1344' | '864x1152' | '1344x768' | '1152x864' | '1440x720' | '720x1440';

interface UseImageGenerationReturn {
  generateImage: (prompt: string, size?: ImageSize) => Promise<string>;
  generating: boolean;
  imageUrl: string | null;
  error: Error | null;
  clear: () => void;
}

export function useImageGeneration(): UseImageGenerationReturn {
  const [generating, setGenerating] = useState(false);
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [error, setError] = useState<Error | null>(null);

  const generateImage = useCallback(async (
    prompt: string,
    size: ImageSize = '1024x1024'
  ): Promise<string> => {
    setGenerating(true);
    setError(null);

    try {
      const res = await fetch('/api/ai/image', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt, size })
      });

      if (!res.ok) {
        throw new Error(`Image API Error: ${res.status}`);
      }

      const data = await res.json();
      const url = `data:image/png;base64,${data.imageBase64}`;
      setImageUrl(url);
      return url;
    } catch (err) {
      const error = err as Error;
      setError(error);
      throw error;
    } finally {
      setGenerating(false);
    }
  }, []);

  const clear = useCallback(() => {
    setImageUrl(null);
    setError(null);
  }, []);

  return { generateImage, generating, imageUrl, error, clear };
}
```

### useChat - Chat with History Hook

```typescript
// hooks/useChat.ts
import { useState, useCallback, useRef } from 'react';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

interface UseChatOptions {
  systemPrompt?: string;
  maxHistory?: number;
}

interface UseChatReturn {
  messages: Message[];
  send: (content: string) => Promise<string>;
  loading: boolean;
  error: Error | null;
  cancel: () => void;
  clear: () => void;
  regenerate: () => Promise<string>;
}

export function useChat(options: UseChatOptions = {}): UseChatReturn {
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const abortControllerRef = useRef<AbortController | null>(null);

  const generateId = () => Math.random().toString(36).substring(2, 15);

  const send = useCallback(async (content: string): Promise<string> => {
    const userMessage: Message = {
      id: generateId(),
      role: 'user',
      content,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setLoading(true);
    setError(null);

    abortControllerRef.current = new AbortController();

    try {
      const res = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          prompt: content,
          history: messages.map(m => ({ role: m.role, content: m.content })),
          systemPrompt: options.systemPrompt
        }),
        signal: abortControllerRef.current.signal
      });

      const data = await res.json();

      const assistantMessage: Message = {
        id: generateId(),
        role: 'assistant',
        content: data.content,
        timestamp: new Date()
      };

      setMessages(prev => [...prev, assistantMessage]);
      return data.content;
    } catch (err: any) {
      if (err.name !== 'AbortError') {
        setError(err);
      }
      throw err;
    } finally {
      setLoading(false);
    }
  }, [messages, options.systemPrompt]);

  const cancel = useCallback(() => {
    abortControllerRef.current?.abort();
    setLoading(false);
  }, []);

  const clear = useCallback(() => {
    setMessages([]);
    setError(null);
  }, []);

  const regenerate = useCallback(async (): Promise<string> => {
    const lastUserMessage = [...messages].reverse().find(m => m.role === 'user');
    if (!lastUserMessage) {
      throw new Error('No user message to regenerate');
    }

    // Remove the last assistant response
    setMessages(prev => prev.slice(0, -1));

    // Resend
    return send(lastUserMessage.content);
  }, [messages, send]);

  return { messages, send, loading, error, cancel, clear, regenerate };
}
```

### useAutoSave - Auto-Save Hook

```typescript
// hooks/useAutoSave.ts
import { useEffect, useRef, useCallback } from 'react';

interface UseAutoSaveOptions<T> {
  data: T;
  saveFunction: (data: T) => Promise<void>;
  delay?: number;
  onSave?: () => void;
  onError?: (error: Error) => void;
}

export function useAutoSave<T>({
  data,
  saveFunction,
  delay = 2000,
  onSave,
  onError
}: UseAutoSaveOptions<T>): {
  saveNow: () => Promise<void>;
  isSaving: boolean;
} {
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);
  const prevDataRef = useRef<string>(JSON.stringify(data));
  const isSavingRef = useRef(false);

  const performSave = useCallback(async () => {
    if (isSavingRef.current) return;

    isSavingRef.current = true;

    try {
      await saveFunction(data);
      prevDataRef.current = JSON.stringify(data);
      onSave?.();
    } catch (err) {
      onError?.(err as Error);
    } finally {
      isSavingRef.current = false;
    }
  }, [data, saveFunction, onSave, onError]);

  useEffect(() => {
    const currentData = JSON.stringify(data);

    if (currentData === prevDataRef.current) {
      return;
    }

    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    timeoutRef.current = setTimeout(performSave, delay);

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, [data, delay, performSave]);

  return {
    saveNow: performSave,
    get isSaving() {
      return isSavingRef.current;
    }
  };
}
```

### useDebounce - Debounced Value Hook

```typescript
// hooks/useDebounce.ts
import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay: number = 500): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// Usage
// const [searchTerm, setSearchTerm] = useState('');
// const debouncedSearch = useDebounce(searchTerm, 300);
//
// useEffect(() => {
//   if (debouncedSearch) {
//     searchAPI(debouncedSearch);
//   }
// }, [debouncedSearch]);
```

---


*(Part of the Z.ai Hooks Complete Guide — see `sandbox-hooks-cookbook.md` for the full index.)*
