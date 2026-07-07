# Standard: Security Core v2.1 (EN)

> ID: STD-SEC-001
> Version: 2.1
> Level: **[C] Critical**
> Last Updated: 2026-06
> Related: STD-ENV-001 (environment), STD-GIT-001 (github), STD-DOC-002 (markdown), STD-META-001 (ID system)

---

## 1. OWASP Top 10 Compliance

### 1.1 Quick Reference

| # | Risk | Mitigation | Status |
|---|------|------------|--------|
| A01 | Broken Access Control | RBAC, principle of least privilege | Required |
| A02 | Cryptographic Failures | TLS, encrypted storage, key rotation | Required |
| A03 | Injection | Parameterized queries, input validation | Required |
| A04 | Insecure Design | Threat modeling, security patterns | Required |
| A05 | Security Misconfiguration | Hardening, security headers | Required |
| A06 | Vulnerable Components | Dependency scanning, updates | Required |
| A07 | Authentication Failures | MFA, session management | Required |
| A08 | Software/Data Integrity | Code signing, CI/CD security | Required |
| A09 | Logging/Monitoring Failures | Audit logs, alerting | Required |
| A10 | SSRF | Allow-lists, network segmentation | Required |

---

## 2. Secrets Management

### 2.1 Never Store Secrets in Code

```typescript
// [FAIL] NEVER DO THIS
const API_KEY = "sk-live-abc123xyz";
const DB_PASSWORD = "admin123";
const JWT_SECRET = "my-secret-key";

// [OK] Use environment variables
const API_KEY = process.env.API_KEY;
const DB_PASSWORD = process.env.DATABASE_PASSWORD;
const JWT_SECRET = process.env.JWT_SECRET;

// [OK] Validate secrets at startup
function validateSecrets() {
  const required = [
    'DATABASE_URL',
    'JWT_SECRET',
    'API_KEY',
  ];

  const missing = required.filter(key => !process.env[key]);
  if (missing.length > 0) {
    console.warn(`Missing required environment variables: ${missing.join(', ')}`);
    // In production: throw new Error(`Missing required secrets: ${missing.join(', ')}`);
    // In sandbox/development: warn only, do not crash (see STD-ENV-001 §1.1)
  }

  // Validate secret strength (only if secret exists)
  if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
    throw new Error('JWT_SECRET must be at least 32 characters');
  }
}
```

### 2.2 .env File Handling

```bash
# .env.example (committed to repo)
# Note: For Z.ai sandbox projects using SQLite, DATABASE_URL uses file: protocol
# Example: DATABASE_URL="file:./dev.db"
DATABASE_URL=postgresql://user:password@localhost:5432/db
JWT_SECRET=your-secret-key-here
API_KEY=your-api-key-here

# .env (NEVER commit)
DATABASE_URL=postgresql://prod_user:real_password@prod-host:5432/prod_db
JWT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
API_KEY=sk-live-real-key
```

```gitignore
# .gitignore
.env
.env.local
.env.*.local
*.pem
*.key
credentials.json
```

### 2.3 Secret Rotation Schedule

| Secret Type | Rotation Frequency | Procedure |
|-------------|-------------------|-----------|
| API Keys | Every 90 days | Generate new, deploy, revoke old |
| Database Passwords | Every 90 days | Update in vault, rotate connections |
| JWT Secret | Every 180 days | Grace period with multi-secret validation |
| Encryption Keys | Every 365 days | Re-encrypt data with new key |
| SSH Keys | Every 365 days | Replace on all servers |

### 2.4 Secrets in CI/CD

```yaml
# GitHub Actions - Use secrets, never hardcode
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          JWT_SECRET: ${{ secrets.JWT_SECRET }}
        run: |
          # Secrets are masked in logs automatically
          npm run deploy
```

---

## 3. Input Validation & Sanitization

### 3.1 Validation Schema

```typescript
import { z } from 'zod';

// User registration schema
const UserRegistrationSchema = z.object({
  email: z.string()
    .email()
    .max(255)
    .transform(email => email.toLowerCase().trim()),

  password: z.string()
    .min(12)
    .max(128)
    .regex(/[A-Z]/, 'Must contain uppercase')
    .regex(/[a-z]/, 'Must contain lowercase')
    .regex(/[0-9]/, 'Must contain number')
    .regex(/[^A-Za-z0-9]/, 'Must contain symbol'),

  name: z.string()
    .min(1)
    .max(100)
    .regex(/^[\p{L}\s'-]+$/u, 'Invalid characters')
    .transform(name => name.trim()),
});

// Validate and parse
function validateUserRegistration(data: unknown) {
  return UserRegistrationSchema.safeParse(data);
}
```

### 3.2 SQL Injection Prevention

```typescript
// [FAIL] NEVER: String concatenation
const query = `SELECT * FROM users WHERE id = ${userId}`;

// [OK] Parameterized queries
const query = 'SELECT * FROM users WHERE id = $1';
const result = await db.query(query, [userId]);

// [OK] ORM with automatic escaping
const user = await prisma.user.findFirst({
  where: { id: userId },
});
```

### 3.3 XSS Prevention

```typescript
import DOMPurify from 'dompurify';

// Sanitize HTML input
function sanitizeHTML(input: string): string {
  return DOMPurify.sanitize(input, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a'],
    ALLOWED_ATTR: ['href'],
  });
}

// Output encoding
import { escape } from 'html-escaper';

function renderUserContent(content: string): string {
  return escape(content); // & < > " '
}
```

---

## 4. Security Headers

### 4.1 Required Headers

```typescript
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'", 'https://api.example.com'],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      frameSrc: ["'none'"],
      baseUri: ["'self'"],
      formAction: ["'self'"],
      frameAncestors: ["'none'"],
    },
  },
  crossOriginEmbedderPolicy: true,
  crossOriginOpenerPolicy: true,
  crossOriginResourcePolicy: { policy: 'same-origin' },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
  noSniff: true,
  originAgentCluster: true,
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
  xssFilter: true,
}));
```

### 4.2 Additional Headers

```typescript
// Custom security headers
app.use((req, res, next) => {
  // Prevent clickjacking
  res.setHeader('X-Frame-Options', 'DENY');

  // Prevent MIME sniffing
  res.setHeader('X-Content-Type-Options', 'nosniff');

  // XSS protection
  res.setHeader('X-XSS-Protection', '1; mode=block');

  // Referrer policy
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

  // Permissions policy
  res.setHeader('Permissions-Policy', [
    'geolocation=()',
    'camera=()',
    'microphone=()',
    'payment=()',
  ].join(', '));

  next();
});
```

---

## 5. Secure Dependencies

### 5.1 Dependency Auditing

```json
// package.json scripts
{
  "scripts": {
    "audit": "npm audit",
    "audit:fix": "npm audit fix",
    "outdated": "npm outdated"
  }
}
```

```yaml
# GitHub Actions - Automated security audit
name: Security Audit
on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=moderate
      - uses: dependabot/fetch-metadata@v1
      # Auto-merge security updates
```

---

## 6. Sensitive Data Handling

### 6.1 Never Log Sensitive Data

```typescript
// Never log sensitive data
const SENSITIVE_FIELDS = [
  'password',
  'token',
  'secret',
  'apiKey',
  'creditCard',
  'ssn',
];

function sanitizeLog(data: Record<string, unknown>): Record<string, unknown> {
  const sanitized = { ...data };

  for (const field of SENSITIVE_FIELDS) {
    if (sanitized[field]) {
      sanitized[field] = '[REDACTED]';
    }
  }

  return sanitized;
}
```

---

## 7. Core Scope Definition

These sections apply to every project, including sandbox prototypes:

| Section | Topic | Why Always Required |
|---------|-------|---------------------|
| 2 | Secrets Management | .env files, gitignore — prevents credential leaks |
| 3.1-3.3 | Input Validation & Sanitization | Zod validation, SQL injection prevention, XSS prevention |
| 4.1-4.2 | Security Headers | Helmet configuration — one-time setup |
| 5.1 | Dependency Auditing | npm audit — automated check |
| 6.1 | Sensitive Data Handling | Never log passwords/tokens |

---

## 8. Quick Core Checklist (for sandbox projects)

- [ ] Secrets in .env (not in code)
- [ ] .env in .gitignore
- [ ] Input validated with Zod on all API routes
- [ ] SQL injection prevented (Prisma parameterized queries)
- [ ] XSS prevented (DOMPurify for user HTML, escape for output)
- [ ] Error responses do not leak internal details
- [ ] No passwords/tokens in logs
- [ ] Dependencies audited (`npm audit`)
- [ ] Security headers configured (helmet)

---

## 9. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.1 | 2025-01 | Initial security standard |
| 2.0 | 2026-05 | Major restructuring: extended content (authentication, authorization, rate limiting, monitoring, deployment, incident response, compliance) extracted to STD-SEC-002. Core retains secrets, input validation, headers, dependency auditing, sensitive data handling. |
| 2.1 | 2026-06 | Added §9A Known Issues documenting SEC-001 through SEC-003 (validation regex \p{L} compatibility, helmet dependency injection ambiguity, .env.example DATABASE_URL contradiction). Added STD-META-001 to Related and Cross-References. No normative rule changes. |

---

## 9A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### SEC-001 `[OPEN]` — §3.1 validation regex uses `\p{L}` Unicode property escape without flag `u`

**Problem:** §3.1 (Validation Schema) defines:

```typescript
name: z.string()
  .regex(/^[\p{L}\s'-]+$/u, 'Invalid characters')
```

The `\p{L}` Unicode property escape requires the `u` flag, which is correctly applied here. However, the same regex pattern appears in other standards and project code without the `u` flag — copying this regex without the flag will silently break Unicode name validation (the `\p{L}` will be interpreted as a literal `p` followed by `{L}`).

**Proposed solution:** Add a note to §3.1: "The `\p{L}` Unicode property escape matches any Unicode letter (Latin, Cyrillic, CJK, etc.). It REQUIRES the `u` flag — without it, the regex silently matches only the literal characters 'p', '{', 'L', '}'. Always include the `u` flag when using `\p{...}` escapes." Add a test case: `expect(regex.test('José')).toBe(true)` to verify the flag is present.

### SEC-002 `[OPEN]` — §4.1 helmet configuration is injected via `app.use(helmet({...}))` but no app variable is declared

**Problem:** §4.1 (Required Headers) shows:

```typescript
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: { /* ... */ },
  // ...
}));
```

The variable `app` is not declared in the example. A reader unfamiliar with Express may not know that `app` is the Express application instance (`const app = express()`). The example also assumes an Express-style middleware chain, but the project may use Next.js middleware (which has a different API) or another framework.

**Proposed solution:** Either (a) add the `app` declaration: `const app = express();` (or `const app = createNextApp();` for Next.js), or (b) add a note: "This example uses Express-style middleware. For Next.js, use the `middleware.ts` file and set headers via `NextResponse.next().headers.set(...)`. For other frameworks, adapt the helmet configuration to the framework's middleware API."

### SEC-003 `[OPEN]` — §2.2 .env.example shows PostgreSQL URL but §1 Note recommends SQLite for sandbox

**Problem:** §2.2 (.env File Handling) shows the .env.example with:

```env
DATABASE_URL=postgresql://user:password@localhost:5432/db
```

But the Note in §2.2 says: "For Z.ai sandbox projects using SQLite, DATABASE_URL uses file: protocol. Example: DATABASE_URL=\"file:./dev.db\"". The example and the note contradict each other — the example shows PostgreSQL, the note says SQLite for sandbox. A reader landing on §2.2 will be confused about which to use.

**Proposed solution:** Show both examples explicitly:

```bash
# .env.example (committed to repo)

# For Z.ai sandbox projects (SQLite):
DATABASE_URL="file:./dev.db"

# For production projects (PostgreSQL):
# DATABASE_URL=postgresql://user:password@localhost:5432/db
```

Add a note: "The default is SQLite for Z.ai sandbox projects (per STD-ENV-001 §2.1). For production deployments, uncomment the PostgreSQL URL and remove the SQLite line."

---

## 10. Cross-References

| Standard | Relationship |
|----------|-------------|
| STD-SEC-002 | Extended security (auth, RBAC, rate limiting, monitoring, incident response, compliance) |
| STD-ENV-001 | Environment variable validation |
| STD-ERR-001 | Error response security (no info leaks) |
| STD-META-001 | Standard ID System: registry entry for STD-SEC-001 must be kept in sync with the version in this document's header |
