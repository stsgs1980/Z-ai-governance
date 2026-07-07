# Standard: Error Handling Core v2.1 (EN)

> ID: STD-ERR-001
> Version: 2.1
> Level: **[C] Critical**
> Last Updated: 2026-06
> Related: STD-FE-001 (frontend), STD-DOC-002 (markdown), STD-META-001 (ID system)

---

## 1. Error Classification

### 1.1 Error Types Hierarchy

```text
Error
+-- ApplicationError (Base for all app errors)
|   +-- ValidationError
|   |   +-- SchemaValidationError
|   |   +-- BusinessRuleViolationError
|   +-- AuthenticationError
|   |   +-- InvalidCredentialsError
|   |   +-- TokenExpiredError
|   |   +-- SessionExpiredError
|   +-- AuthorizationError
|   |   +-- PermissionDeniedError
|   |   +-- RoleNotFoundError
|   +-- NotFoundError
|   |   +-- ResourceNotFoundError
|   |   +-- RouteNotFoundError
|   +-- ConflictError
|   |   +-- DuplicateEntryError
|   |   +-- VersionMismatchError
|   +-- RateLimitError
|   +-- ExternalServiceError
|   |   +-- DatabaseError
|   |   +-- CacheError
|   |   +-- ThirdPartyAPIError
|   +-- InternalError
+-- SystemError (Unexpected, non-recoverable)
```None

### 1.2 Error Categories

| Category            | HTTP Status | Recoverable | User Message               |
| ------------------- | ----------- | ----------- | -------------------------- |
| Validation          | 400         | Yes         | Show specific field errors |
| Authentication      | 401         | Yes         | Prompt login               |
| Authorization       | 403         | No          | Show permission message    |
| Not Found           | 404         | No          | Show not found message     |
| Conflict            | 409         | Yes         | Prompt resolution          |
| Rate Limit          | 429         | Yes         | Show retry time            |
| Server Error        | 500         | No          | Generic error, log details |
| Service Unavailable | 503         | Yes         | Show retry option          |

---

## 2. Error Object Structure

### 2.1 Standard Error Interface

```typescript
// types/errors.ts
interface ApplicationError {
  // Identity
  id: string; // Unique error ID for tracking
  code: string; // Machine-readable code (e.g., 'USER_NOT_FOUND')
  name: string; // Error class name

  // Context
  message: string; // User-friendly message
  details?: unknown; // Additional context

  // Debugging
  stack?: string; // Stack trace (dev only)
  cause?: Error; // Original error (for wrapping)

  // HTTP
  statusCode: number; // HTTP status code

  // Metadata
  timestamp: string; // ISO 8601
  path?: string; // Request path
  requestId?: string; // Request correlation ID

  // Recovery
  recoverable: boolean;
  retryAfter?: number; // Seconds until retry
  helpUrl?: string; // Documentation link
}
```

### 2.2 Error Implementation

```typescript
// lib/errors/base.ts
export class ApplicationError extends Error {
  public readonly id: string;
  public readonly code: string;
  public readonly statusCode: number;
  public readonly timestamp: string;
  public readonly recoverable: boolean;
  public readonly details?: unknown;
  public readonly cause?: Error;

  constructor({
    code,
    message,
    statusCode = 500,
    recoverable = false,
    details,
    cause,
  }: ErrorConfig) {
    super(message);
    this.name = this.constructor.name;
    this.id = generateErrorId();
    this.code = code;
    this.statusCode = statusCode;
    this.timestamp = new Date().toISOString();
    this.recoverable = recoverable;
    this.details = details;
    this.cause = cause;

    // Maintain proper stack trace
    Error.captureStackTrace(this, this.constructor);
  }

  toJSON(): ApplicationErrorJSON {
    return {
      id: this.id,
      code: this.code,
      name: this.name,
      message: this.message,
      statusCode: this.statusCode,
      timestamp: this.timestamp,
      recoverable: this.recoverable,
      ...(process.env.NODE_ENV === "development" && {
        stack: this.stack,
        cause: this.cause?.message,
      }),
    };
  }
}
```None

### 2.3 Specific Error Classes

```typescript
// lib/errors/index.ts
export class ValidationError extends ApplicationError {
  constructor(message: string, details?: FieldError[]) {
    super({
      code: "VALIDATION_ERROR",
      message,
      statusCode: 400,
      recoverable: true,
      details,
    });
  }
}

export class NotFoundError extends ApplicationError {
  constructor(resource: string, identifier?: string | number) {
    super({
      code: "NOT_FOUND",
      message: `${resource} not found`,
      statusCode: 404,
      recoverable: false,
      details: { resource, identifier },
    });
  }
}

export class AuthenticationError extends ApplicationError {
  constructor(message = "Authentication required") {
    super({
      code: "AUTHENTICATION_ERROR",
      message,
      statusCode: 401,
      recoverable: true,
    });
  }
}

export class RateLimitError extends ApplicationError {
  constructor(retryAfter: number) {
    super({
      code: "RATE_LIMIT_EXCEEDED",
      message: "Too many requests. Please try again later.",
      statusCode: 429,
      recoverable: true,
      retryAfter,
    });
  }
}

export class ExternalServiceError extends ApplicationError {
  constructor(service: string, cause?: Error) {
    super({
      code: "EXTERNAL_SERVICE_ERROR",
      message: `Service ${service} is temporarily unavailable`,
      statusCode: 503,
      recoverable: true,
      details: { service },
      cause,
    });
  }
}
```

---

## 3. Try-Catch Patterns

### 3.1 Basic Pattern

```typescript
// [OK] Good: Specific error handling
async function getUser(id: string): Promise<User> {
  try {
    const user = await db.users.find(id);
    if (!user) {
      throw new NotFoundError("User", id);
    }
    return user;
  } catch (error) {
    if (error instanceof NotFoundError) {
      throw error; // Re-throw known errors
    }
    if (error instanceof DatabaseError) {
      throw new ExternalServiceError("Database", error);
    }
    throw new InternalError("Failed to get user", error);
  }
}

// [FAIL] Bad: Swallowing errors
async function getUser(id: string) {
  try {
    return await db.users.find(id);
  } catch (e) {
    console.error(e);
    return null; // Information loss!
  }
}
```None

### 3.2 Error Wrapping

```typescript
// Wrap external errors with context
async function processPayment(order: Order): Promise<PaymentResult> {
  try {
    return await stripe.charges.create({
      amount: order.total,
      currency: "usd",
    });
  } catch (error) {
    if (error instanceof StripeCardError) {
      throw new ValidationError("Payment failed", {
        field: "card",
        message: error.message,
      });
    }

    if (error instanceof StripeAPIError) {
      throw new ExternalServiceError("Stripe", error);
    }

    throw new InternalError("Payment processing failed", {
      orderId: order.id,
      cause: error,
    });
  }
}
```

### 3.3 Result Pattern (Alternative)

```typescript
// For operations where failure is expected
type Result<T, E = Error> = Success<T> | Failure<E>;

interface Success<T> {
  ok: true;
  value: T;
}

interface Failure<E> {
  ok: false;
  error: E;
}

function success<T>(value: T): Success<T> {
  return { ok: true, value };
}

function failure<E>(error: E): Failure<E> {
  return { ok: false, error };
}

// Usage
function divide(a: number, b: number): Result<number, string> {
  if (b === 0) {
    return failure("Division by zero");
  }
  return success(a / b);
}

// Handling
const result = divide(10, 2);
if (result.ok) {
  console.log(result.value); // 5
} else {
  console.error(result.error);
}
```text

---

## 4. Logging Standards

### 4.1 Log Levels

| Level | When to Use                  | Contains                       |
| ----- | ---------------------------- | ------------------------------ |
| DEBUG | Development details          | Stack traces, variables        |
| INFO  | Business events              | User actions, state changes    |
| WARN  | Recoverable issues           | Degraded service, fallbacks    |
| ERROR | Failures requiring attention | Full error context             |
| FATAL | Unrecoverable                | System state, immediate action |

### 4.2 Structured Logging

```typescript
// lib/logger.ts
import pino from "pino";

export const logger = pino({
  level: process.env.LOG_LEVEL || "info",
  formatters: {
    level: (label) => ({ level: label }),
  },
  redact: ["req.headers.authorization", "req.body.password"],
});

// Usage
logger.info(
  {
    event: "user_created",
    userId: user.id,
    email: user.email,
    source: "registration",
  },
  "User account created",
);

logger.error(
  {
    event: "payment_failed",
    orderId: order.id,
    error: {
      code: error.code,
      message: error.message,
      stack: error.stack,
    },
  },
  "Payment processing failed",
);
```

### 4.3 Error Context Enrichment

```typescript
// middleware/error-logger.ts
export function errorLogger(error: Error, req: Request, res: Response, next: NextFunction) {
  const errorLog = {
    timestamp: new Date().toISOString(),
    error: {
      id: error instanceof ApplicationError ? error.id : generateErrorId(),
      code: error instanceof ApplicationError ? error.code : "UNKNOWN_ERROR",
      name: error.name,
      message: error.message,
      stack: error.stack,
    },
    request: {
      method: req.method,
      path: req.path,
      query: req.query,
      headers: sanitizeHeaders(req.headers),
      ip: req.ip,
      userAgent: req.get("user-agent"),
    },
    user: req.user ? { id: req.user.id, role: req.user.role } : null,
    environment: process.env.NODE_ENV,
  };

  logger.error(errorLog, "Request error");

  next(error);
}
```text

---

## 5. API Error Responses

### 5.1 Standard Response Format

```typescript
// Success Response
{
  "success": true,
  "data": { ... }
}

// Error Response
{
  "success": false,
  "error": {
    "id": "err_abc123",
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "password",
        "message": "Password must be at least 8 characters"
      }
    ],
    "recoverable": true,
    "retryAfter": null,
    "helpUrl": "https://docs.example.com/errors/validation"
  }
}
```

### 5.2 Error Handler Middleware

```typescript
// middleware/error-handler.ts
export function errorHandler(error: Error, req: Request, res: Response, next: NextFunction) {
  // Handle known application errors
  if (error instanceof ApplicationError) {
    return res.status(error.statusCode).json({
      success: false,
      error: error.toJSON(),
    });
  }

  // Handle known external errors
  if (error instanceof ZodError) {
    const validationError = new ValidationError(
      "Invalid input data",
      error.errors.map((e) => ({
        field: e.path.join("."),
        message: e.message,
      })),
    );
    return res.status(400).json({
      success: false,
      error: validationError.toJSON(),
    });
  }

  // Handle unexpected errors
  logger.fatal(
    {
      error: {
        name: error.name,
        message: error.message,
        stack: error.stack,
      },
      request: {
        method: req.method,
        path: req.path,
      },
    },
    "Unhandled error",
  );

  // Don't leak internal details
  return res.status(500).json({
    success: false,
    error: {
      id: generateErrorId(),
      code: "INTERNAL_ERROR",
      message: "An unexpected error occurred",
      recoverable: false,
    },
  });
}
```text

---

## 6. Frontend Error Handling

### 6.1 Error Boundaries (React)

```tsx
// components/ErrorBoundary.tsx
interface Props {
  fallback: React.ReactNode;
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void;
  children: React.ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends React.Component<Props, State> {
  state: State = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    logger.error(
      {
        error: error.message,
        stack: errorInfo.componentStack,
      },
      "React error boundary caught",
    );

    this.props.onError?.(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}

// Usage
<ErrorBoundary fallback={<ErrorPage onRetry={() => window.location.reload()} />}>
  <App />
</ErrorBoundary>;
```

### 6.2 API Error Handling

```typescript
// lib/api/client.ts
class APIClient {
  async request<T>(config: RequestConfig): Promise<T> {
    try {
      const response = await fetch(config.url, {
        method: config.method,
        headers: {
          "Content-Type": "application/json",
          ...config.headers,
        },
        body: config.body ? JSON.stringify(config.body) : undefined,
      });

      const data = await response.json();

      if (!response.ok) {
        throw new APIError(data.error);
      }

      return data.data;
    } catch (error) {
      if (error instanceof APIError) {
        throw error;
      }

      if (error instanceof TypeError) {
        // Network error
        throw new NetworkError("Unable to connect to server");
      }

      throw new UnknownError("An unexpected error occurred");
    }
  }
}

// Usage with React Query
const { data, error, isError } = useQuery({
  queryKey: ["user", userId],
  queryFn: () => apiClient.request({ url: `/users/${userId}` }),
  retry: (failureCount, error) => {
    if (error instanceof AuthenticationError) return false;
    if (error instanceof NotFoundError) return false;
    return failureCount < 3;
  },
});
```None

### 6.3 User-Facing Messages

```typescript
// lib/errors/messages.ts
const errorMessages: Record<string, string> = {
  VALIDATION_ERROR: "Please check your input and try again.",
  AUTHENTICATION_ERROR: "Please log in to continue.",
  PERMISSION_DENIED: "You do not have permission to perform this action.",
  NOT_FOUND: "The requested resource was not found.",
  RATE_LIMIT_EXCEEDED: "Too many requests. Please wait a moment.",
  EXTERNAL_SERVICE_ERROR: "Service temporarily unavailable. Please try again.",
  INTERNAL_ERROR: "Something went wrong. Our team has been notified.",
};

export function getUserMessage(error: ApplicationError): string {
  return errorMessages[error.code] ?? errorMessages.INTERNAL_ERROR;
}
```

---

## 7. Checklist

### Before Deployment

- [ ] All async functions have try-catch
- [ ] Errors are properly classified
- [ ] Sensitive data is not in error messages
- [ ] Logging is configured correctly
- [ ] Error responses are consistent
- [ ] Frontend has error boundaries
- [ ] Retry logic is in place for external calls
- [ ] Circuit breakers configured for critical services
- [ ] Alerts are set up
- [ ] Error documentation is up to date

### Code Review

- [ ] No swallowed errors
- [ ] No console.log in production code
- [ ] Error context is sufficient for debugging
- [ ] User messages are helpful
- [ ] Recovery strategies are appropriate

---

## 8. Version History

| Version | Date       | Changes                                                                                                                                                                                                                                                         |
| ------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | 2025-01    | Initial version: error classification, structure, patterns, logging, API responses, frontend handling, recovery strategies, monitoring                                                                                                                          |
| 2.0     | 2026-05    | Major restructuring: recovery strategies (retry, circuit breaker, fallback) and monitoring/alerting extracted to STD-ERR-002. Core retains error classification, structure, patterns, logging, API responses, frontend handling.                                |
| 2.1     | 2026-06    | Added §8A Known Issues documenting ERR-001 through ERR-003 (validation message inconsistency, logger redact path-fragility, error boundary getDerivedStateFromError limitation). Added STD-META-001 to Related and Cross-References. No normative rule changes. |
| 2.2     | 2026-07-06 | Folded recovery strategies (retry, circuit breaker, fallback) and monitoring/alerting back into ERR-001 (from deleted STD-ERR-002). ERR-002-001 finding marked RESOLVED-via-deletion. Cross-References updated.                                                 |

---

## 8A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### ERR-001 `[OPEN]` — §2.3 `ValidationError` accepts `FieldError[]` but §5.1 response example uses a different `details` shape

**Problem:** §2.3 defines:

```typescript
export class ValidationError extends ApplicationError {
  constructor(message: string, details?: FieldError[]) {
    super({ code: "VALIDATION_ERROR", message, statusCode: 400, recoverable: true, details });
  }
}
```text

§5.1 (Standard Response Format) shows the error response with `details` as an array of `{ field, message }` objects. The `FieldError` type is not defined anywhere in this standard — the reader has to infer its shape from the §5.1 example. A reader implementing this standard has to guess whether `FieldError` is `{ field: string; message: string }` or includes additional fields (e.g., `code`, `value`).

**Proposed solution:** Add a §2.4 "Supporting Types" subsection that defines `FieldError` explicitly:

```typescript
interface FieldError {
  field: string; // Dot-notation path, e.g., "user.address.zipCode"
  message: string; // Human-readable error message
  code?: string; // Optional machine-readable code, e.g., "REQUIRED", "INVALID_FORMAT"
  value?: unknown; // Optional: the rejected value (omit for sensitive fields)
}
```

Reference this type from §2.3 and §5.1.

### ERR-002 `[RESOLVED-via-deletion 2026-07-06]` — §4.2 Pino `redact` config (was in extracted STD-ERR-002, now deleted)

**Note:** This finding originally referenced §4.2 in STD-ERR-002, which was extracted from ERR-001 v2.0 and deleted on 2026-07-06 as part of dead-standard cleanup. The redact concern is now addressed by ERR-001 §4.2 itself (Pino redaction has been folded back into ERR-001 core). If the redact list needs expansion, it should be filed as a new finding against ERR-001 §4.2.

**Original problem (historical):** §4.2 (Structured Logging) configured Pino with `redact: ['req.headers.authorization', 'req.body.password']`, which redacts only one field. Sensitive fields like `req.body.newPassword`, `req.body.confirmPassword`, `req.body.token`, `req.body.apiKey` were NOT redacted.

**Historical proposed solution:** Expand the redact list to cover all common sensitive field names, or use a recursive censor function.

### ERR-003 `[OPEN]` — §6.1 React Error Boundary uses `getDerivedStateFromError` but does not handle async errors or errors in event handlers

**Problem:** §6.1 (Error Boundaries) shows a React Error Boundary using `getDerivedStateFromError` and `componentDidCatch`. This pattern catches errors in rendering, lifecycle methods, and constructors — but it does NOT catch:

- Errors in event handlers (e.g., `onClick` async errors)
- Errors in `setTimeout` / `setInterval` callbacks
- Errors in async/await code (unhandled promise rejections)

A team relying solely on §6.1's Error Boundary will miss these error classes. The standard does not mention this limitation or provide the recommended workaround (window-level `unhandledrejection` listener).

**Proposed solution:** Add a §6.1.1 "Error Boundary Limitations" note: "React Error Boundaries catch errors in rendering, lifecycle, and constructors. They do NOT catch errors in event handlers, setTimeout/setInterval callbacks, or unhandled promise rejections. For these, add a global listener in your root layout:

```typescript
useEffect(() => {
  const handler = (event: PromiseRejectionEvent) => {
    logger.error({ reason: event.reason }, "Unhandled promise rejection");
    event.preventDefault();
  };
  window.addEventListener("unhandledrejection", handler);
  return () => window.removeEventListener("unhandledrejection", handler);
}, []);
```text

Event-handler errors should be caught locally with try/catch and reported via the same logger."

---

## 9. Cross-References

| Standard      | Relationship                                                                                                       |
| ------------- | ------------------------------------------------------------------------------------------------------------------ |
| STD-SEC-001   | Security error handling (no info leaks in error responses)                                                         |
| STD-AGENT-001 | Subagent error contract (failure reporting)                                                                        |
| STD-AGENT-002 | Orchestration error propagation (escalation ladder)                                                                |
| STD-META-001  | Standard ID System: registry entry for STD-ERR-001 must be kept in sync with the version in this document's header |
