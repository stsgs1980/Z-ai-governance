# Z.ai Hooks — API Routes & Middleware

> Part of the Z.ai Hooks Complete Guide (see `sandbox-hooks-cookbook.md` for the index).

---

## Table of Contents

1. [API Routes for AI Integration](#api-routes-for-ai-integration)
2. [Middleware Hooks](#middleware-hooks)

---

## API Routes for AI Integration

### Chat API Route

```typescript
// app/api/ai/chat/route.ts
import { NextRequest, NextResponse } from 'next/server';
import ZAI from 'z-ai-web-dev-sdk';

interface ChatRequest {
  prompt: string;
  history?: Array<{ role: 'user' | 'assistant'; content: string }>;
  systemPrompt?: string;
  temperature?: number;
  maxTokens?: number;
}

export async function POST(request: NextRequest) {
  try {
    const body: ChatRequest = await request.json();
    const { prompt, history = [], systemPrompt, temperature = 0.7, maxTokens } = body;

    const zai = await ZAI.create();

    const messages = [
      { role: 'system' as const, content: systemPrompt || 'You are a helpful assistant.' },
      ...history.map(m => ({ role: m.role as 'user' | 'assistant', content: m.content })),
      { role: 'user' as const, content: prompt }
    ];

    const completion = await zai.chat.completions.create({
      messages,
      temperature,
      max_tokens: maxTokens
    });

    const content = completion.choices[0]?.message?.content || '';

    return NextResponse.json({ content });
  } catch (error: any) {
    console.error('Chat API Error:', error);

    return NextResponse.json(
      { error: error.message || 'Internal Server Error' },
      { status: 500 }
    );
  }
}
```None

### Image Generation API Route

```typescript
// app/api/ai/image/route.ts
import { NextRequest, NextResponse } from 'next/server';
import ZAI from 'z-ai-web-dev-sdk';

type ImageSize = '1024x1024' | '768x1344' | '864x1152' | '1344x768' | '1152x864' | '1440x720' | '720x1440';

interface ImageRequest {
  prompt: string;
  size?: ImageSize;
}

export async function POST(request: NextRequest) {
  try {
    const body: ImageRequest = await request.json();
    const { prompt, size = '1024x1024' } = body;

    if (!prompt || prompt.trim().length === 0) {
      return NextResponse.json(
        { error: 'Prompt is required' },
        { status: 400 }
      );
    }

    const zai = await ZAI.create();

    const response = await zai.images.generations.create({
      prompt,
      size
    });

    const imageBase64 = response.data[0]?.base64;

    if (!imageBase64) {
      throw new Error('No image generated');
    }

    return NextResponse.json({ imageBase64 });
  } catch (error: any) {
    console.error('Image API Error:', error);

    return NextResponse.json(
      { error: error.message || 'Internal Server Error' },
      { status: 500 }
    );
  }
}
```

### Web Search API Route

```typescript
// app/api/ai/search/route.ts
import { NextRequest, NextResponse } from 'next/server';
import ZAI from 'z-ai-web-dev-sdk';

interface SearchRequest {
  query: string;
  num?: number;
}

export async function POST(request: NextRequest) {
  try {
    const body: SearchRequest = await request.json();
    const { query, num = 10 } = body;

    if (!query || query.trim().length === 0) {
      return NextResponse.json(
        { error: 'Query is required' },
        { status: 400 }
      );
    }

    const zai = await ZAI.create();

    const searchResult = await zai.functions.invoke('web_search', {
      query,
      num
    });

    return NextResponse.json({ results: searchResult });
  } catch (error: any) {
    console.error('Search API Error:', error);

    return NextResponse.json(
      { error: error.message || 'Internal Server Error' },
      { status: 500 }
    );
  }
}
```text

---

---

## Middleware Hooks

### Logging and Monitoring

```typescript
// middleware.ts
import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  const start = Date.now();
  const requestId = crypto.randomUUID();

  // Pre-hook: log incoming request
  console.log(`[${requestId}] -> ${request.method} ${request.url}`);

  // Add requestId for tracing
  const response = NextResponse.next();
  response.headers.set('x-request-id', requestId);

  // Post-hook: log processing time
  const duration = Date.now() - start;
  response.headers.set('x-response-time', `${duration}ms`);

  console.log(`[${requestId}] <- ${response.status} (${duration}ms)`);

  return response;
}

export const config = {
  matcher: '/api/:path*'
};
```

### Rate Limiting Hook

```typescript
// lib/rateLimiter.ts
const rateLimitMap = new Map<string, { count: number; resetTime: number }>();

export function checkRateLimit(
  identifier: string,
  limit: number = 100,
  windowMs: number = 60000
): { allowed: boolean; remaining: number; resetTime: number } {
  const now = Date.now();
  const record = rateLimitMap.get(identifier);

  if (!record || now > record.resetTime) {
    rateLimitMap.set(identifier, { count: 1, resetTime: now + windowMs });
    return { allowed: true, remaining: limit - 1, resetTime: now + windowMs };
  }

  if (record.count >= limit) {
    return { allowed: false, remaining: 0, resetTime: record.resetTime };
  }

  record.count++;
  return { allowed: true, remaining: limit - record.count, resetTime: record.resetTime };
}
```text

---


*(Part of the Z.ai Hooks Complete Guide — see `sandbox-hooks-cookbook.md` for the full index.)*
