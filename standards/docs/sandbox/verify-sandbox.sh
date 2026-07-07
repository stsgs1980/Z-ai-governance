#!/usr/bin/env bash
#
# docs/sandbox/verify-sandbox.sh — Z.ai Sandbox Documentation Verification Script
# Запускать внутри sandbox: bash docs/sandbox/verify-sandbox.sh
#
set -euo pipefail

PASS=0
FAIL=0
PROJECT="/home/z/my-project"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }

check() {
  local label="$1" result="$2"
  if [ "$result" = "PASS" ]; then
    green "  [PASS] $label"
    PASS=$((PASS + 1))
  else
    red "  [FAIL] $label"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "=== Z.ai Sandbox Documentation Verification ==="
echo ""

# ─── 1. bun vs npm ────────────────────────────────────────────────
echo "--- 1. Package Manager (bun vs npm) ---"

BUN_VER=$(bun --version 2>/dev/null || echo "NOT_FOUND")
NPM_VER=$(npm --version 2>/dev/null || echo "NOT_FOUND")
check "bun установлен ($BUN_VER)" "$( [ "$BUN_VER" != "NOT_FOUND" ] && echo PASS || echo FAIL )"
check "npm установлен ($NPM_VER)"   "$( [ "$NPM_VER" != "NOT_FOUND" ] && echo PASS || echo FAIL )"

# Какой менеджер реально используется в .zscripts/dev.sh?
if [ -f "$PROJECT/.zscripts/dev.sh" ]; then
  DEV_MGR=$(head -20 "$PROJECT/.zscripts/dev.sh" | grep -oP 'bun|npm|npx' | head -1)
  check "dev.sh использует '$DEV_MGR'" "PASS"
else
  red "  [SKIP] dev.sh не найден"
fi

# ─── 2. Dev server: запрет vs разрешение ───────────────────────────
echo ""
echo "--- 2. Dev server ---"

# Есть ли процесс next/bun на порту 3000?
if command -v ss &>/dev/null; then
  DEV_PROC=$(ss -tlnp 2>/dev/null | grep ':3000' || echo "NOT_FOUND")
elif command -v lsof &>/dev/null; then
  DEV_PROC=$(lsof -i :3000 2>/dev/null || echo "NOT_FOUND")
else
  DEV_PROC="UNKNOWN"
fi

if [ "$DEV_PROC" != "NOT_FOUND" ] && [ "$DEV_PROC" != "UNKNOWN" ]; then
  check "Порт 3000 занят — dev server запущен автоматически" "PASS"
else
  check "Порт 3000: процесс не найден (возможно idle timeout)" "FAIL"
fi

# Как стартует сервер?
if [ -f "$PROJECT/.zscripts/dev.sh" ]; then
  START_CMD=$(grep -E "next dev|bun run|npm run" "$PROJECT/.zscripts/dev.sh" | head -1)
  check "dev.sh содержит ручной старт: $([ -n "$START_CMD" ] && echo "$START_CMD" || echo "запуск не через next/bun")" \
    "$( [ -z "$START_CMD" ] && echo PASS || echo FAIL )"
fi

# ─── 3. API routes / multi-page ────────────────────────────────────
echo ""
echo "--- 3. API routes / multi-page ---"

if [ -d "$PROJECT/src/app/api" ]; then
  API_ROUTES=$(find "$PROJECT/src/app/api" -name "route.ts" 2>/dev/null | wc -l)
  check "API routes созданы: $API_ROUTES шт. (Guide запрещает)" \
    "$( [ "$API_ROUTES" -eq 0 ] && echo PASS || echo FAIL )"
else
  check "api/ не существует — соответствует Guide" "PASS"
fi

PAGES=$(find "$PROJECT/src/app" -maxdepth 2 -name "page.tsx" 2>/dev/null | wc -l)
if [ "$PAGES" -le 2 ]; then
  check "Доп. страницы: $PAGES page.tsx — OK" "PASS"
else
  check "Доп. страницы: $PAGES page.tsx (Guide: только page.tsx + layout)" "FAIL"
fi

# ─── 4. allowedDevOrigins ──────────────────────────────────────────
echo ""
echo "--- 4. allowedDevOrigins ---"

if [ -f "$PROJECT/next.config.ts" ]; then
  HAS_ADO=$(grep -c "allowedDevOrigins" "$PROJECT/next.config.ts" 2>/dev/null || echo 0)
  check "allowedDevOrigins в next.config.ts (Guide требует, шаблон не содержит)" \
    "$( [ "$HAS_ADO" -gt 0 ] && echo PASS || echo FAIL )"
elif [ -f "$PROJECT/next.config.js" ]; then
  HAS_ADO=$(grep -c "allowedDevOrigins" "$PROJECT/next.config.js" 2>/dev/null || echo 0)
  check "allowedDevOrigins в next.config.js" \
    "$( [ "$HAS_ADO" -gt 0 ] && echo PASS || echo FAIL )"
else
  check "next.config не найден" "FAIL"
fi

# ─── 5. XTransformPort ─────────────────────────────────────────────
echo ""
echo "--- 5. XTransformPort ---"

if [ -f "$PROJECT/Caddyfile" ]; then
  HAS_XTP=$(grep -c "XTransformPort" "$PROJECT/Caddyfile" 2>/dev/null || echo 0)
  check "XTransformPort в Caddyfile (есть в коде, нет в документации)" \
    "$( [ "$HAS_XTP" -gt 0 ] && echo FAIL || echo PASS )"
else
  check "Caddyfile не найден — странно" "FAIL"
fi

# ─── 6. Dockerfile / build ─────────────────────────────────────────
echo ""
echo "--- 6. Dockerfile / build ---"

if [ -f "$PROJECT/Dockerfile" ]; then
  check "Dockerfile существует — OK" "PASS"
else
  check "Dockerfile не найден" "INFO"
fi

check "npm run build компилируется" \
  "$( cd "$PROJECT" && npm run build 2>&1 | tail -5 | grep -q "successfully" && echo PASS || echo FAIL )"

# ─── 7. Фактические версии (сверка с commands_reference.md) ────────
echo ""
echo "--- 7. Version check (vs commands_reference.md) ---"

check "Node.js: $(node --version 2>/dev/null || echo N/A)" "PASS"
check "Bun: $(bun --version 2>/dev/null || echo N/A)" "PASS"
check "npm: $(npm --version 2>/dev/null || echo N/A)" "PASS"
PY_VER=$(python3 --version 2>/dev/null || echo "N/A")
check "Python: $PY_VER" "PASS"
check "Git: $(git --version 2>/dev/null || echo N/A)" "PASS"

# ─── 8. z-ai-web-dev-sdk ──────────────────────────────────────────
echo ""
echo "--- 8. z-ai-web-dev-sdk ---"

SDK_VER=$(cd "$PROJECT" && bun list z-ai-web-dev-sdk 2>/dev/null || npm list z-ai-web-dev-sdk 2>/dev/null || echo "NOT_FOUND")
check "z-ai-web-dev-sdk установлен ($SDK_VER)" \
  "$( echo "$SDK_VER" | grep -q "z-ai-web-dev-sdk" && echo PASS || echo FAIL )"

# ─── 9. Prisma ─────────────────────────────────────────────────────
echo ""
echo "--- 9. Prisma ---"

if [ -f "$PROJECT/prisma/schema.prisma" ]; then
  check "prisma/schema.prisma существует" "PASS"
  check "bun run db:push работает" \
    "$( cd "$PROJECT" && bun run db:push 2>&1 | tail -3 | grep -qiE "success|already" && echo PASS || echo FAIL )"
else
  check "Prisma schema не найдена" "INFO"
fi

# ─── 10. submodule ─────────────────────────────────────────────────
echo ""
echo "--- 10. Git submodule ---"

if [ -f "$PROJECT/.gitmodules" ]; then
  SUB_COUNT=$(grep -c "\[submodule" "$PROJECT/.gitmodules" 2>/dev/null || echo 0)
  check "Submodules: $SUB_COUNT" "PASS"
  SUB_INIT=$(cd "$PROJECT" && git submodule status 2>&1 | head -5)
  check "Submodule status: $SUB_INIT" "PASS"
else
  check ".gitmodules не найден" "INFO"
fi

# ─── 11. Hooks: useChat dependency ─────────────────────────────────
echo ""
echo "--- 11. Hooks code quality ---"

if [ -f "$PROJECT/src/hooks/useChat.ts" ]; then
  HAS_MSG_DEP=$(grep -A2 "useCallback" "$PROJECT/src/hooks/useChat.ts" 2>/dev/null | grep -c "messages")
  if [ "$HAS_MSG_DEP" -gt 0 ]; then
    yellow "  [WARN] useCallback depends on 'messages' — пересоздаётся при каждом сообщении"
  fi
fi

# ─── ИТОГО ─────────────────────────────────────────────────────────
echo ""
echo "=============================="
green " PASS: $PASS"
red " FAIL: $FAIL"
echo "=============================="

if [ "$FAIL" -gt 0 ]; then
  echo ""
  yellow "Рекомендации:"
  [ -f "$PROJECT/next.config.ts" ] && grep -q "allowedDevOrigins" "$PROJECT/next.config.ts" || \
    echo "  - Добавить allowedDevOrigins в next.config.ts (см. Guide 17.2)"
fi
echo ""
