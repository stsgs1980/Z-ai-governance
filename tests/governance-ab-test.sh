#!/usr/bin/env bash
# ============================================================================
# governance-ab-test.sh — A/B test: governance ON vs OFF
# ============================================================================
# Tests whether governance hooks actually block violations.
#
# Usage:
#   bash tests/governance-ab-test.sh setup    # Create two test projects
#   bash tests/governance-ab-test.sh task     # Simulate agent work (write violating files)
#   bash tests/governance-ab-test.sh commit   # Try to commit in both projects
#   bash tests/governance-ab-test.sh compare  # Compare results
# ============================================================================

set -euo pipefail

TEST_DIR="/tmp/governance-ab-test"
PROJECT_OFF="$TEST_DIR/project-off"   # No governance
PROJECT_ON="$TEST_DIR/project-on"     # With governance
RESULTS_DIR="$TEST_DIR/results"
GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/guard"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[AB-TEST]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# ============================================================================
# SETUP — Create two identical projects
# ============================================================================
cmd_setup() {
    step "Setting up A/B test projects..."
    
    # Clean slate
    rm -rf "$TEST_DIR"
    mkdir -p "$RESULTS_DIR"
    
    for project in "$PROJECT_OFF" "$PROJECT_ON"; do
        mkdir -p "$project/src/app"
        mkdir -p "$project/src/components"
        mkdir -p "$project/src/lib"
        
        # package.json
        cat > "$project/package.json" << 'PKGEOF'
{
  "name": "governance-ab-test",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "lint": "next lint",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "next": "^16.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "typescript": "^5.7.0"
  }
}
PKGEOF

        # tsconfig.json
        cat > "$project/tsconfig.json" << 'TSEOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "strict": true,
    "noEmit": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "jsx": "preserve",
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
TSEOF

        # Initialize git
        cd "$project"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test User"
        
        # Initial commit
        echo "# Governance A/B Test" > README.md
        git add -A
        git commit -q -m "chore: initial setup"
    done
    
    # Install governance hooks in PROJECT_ON only
    step "Installing governance hooks in project-on..."
    mkdir -p "$PROJECT_ON/.husky"
    
    # Copy guard scripts
    mkdir -p "$PROJECT_ON/guard/scripts"
    cp "$GUARD_DIR/scripts/check-no-bypass.sh" "$PROJECT_ON/guard/scripts/" 2>/dev/null || true
    cp "$GUARD_DIR/scripts/check-commit-checklist.sh" "$PROJECT_ON/guard/scripts/" 2>/dev/null || true
    cp "$GUARD_DIR/scripts/check-version-bump.sh" "$PROJECT_ON/guard/scripts/" 2>/dev/null || true
    cp "$GUARD_DIR/scripts/check-read-before-write.sh" "$PROJECT_ON/guard/scripts/" 2>/dev/null || true
    cp "$GUARD_DIR/scripts/check-no-loops.sh" "$PROJECT_ON/guard/scripts/" 2>/dev/null || true
    cp "$GUARD_DIR/scripts/check-ahg-integrity.sh" "$PROJECT_ON/guard/scripts/" 2>/dev/null || true
    cp "$GUARD_DIR/scripts/check-sandbox-env.sh" "$PROJECT_ON/guard/scripts/" 2>/dev/null || true
    cp "$GUARD_DIR/scripts/check-session-start.sh" "$PROJECT_ON/guard/scripts/" 2>/dev/null || true
    
    # Create pre-commit hook (mirrors real .husky/pre-commit with --hard)
    cat > "$PROJECT_ON/.husky/pre-commit" << 'HOOKEOF'
#!/usr/bin/env bash
set -euo pipefail

echo "=== Governance Pre-commit Hook (HARD MODE) ==="

VIOLATIONS=0

# Run governance checks with --hard
for script in guard/scripts/check-*.sh; do
    if [ -f "$script" ]; then
        echo ""
        echo "--- Running $(basename "$script") --hard ---"
        if ! bash "$script" --hard; then
            echo "FAIL: $script"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi
    fi
done

echo ""
echo "=== Governance checks: $VIOLATIONS violation(s) ==="

if [ $VIOLATIONS -gt 0 ]; then
    echo "COMMIT BLOCKED by governance"
    exit 1
fi

echo "=== All governance checks passed ==="
HOOKEOF
    chmod +x "$PROJECT_ON/.husky/pre-commit"
    
    # Tell git to use .husky as hooks path
    cd "$PROJECT_ON"
    git config core.hooksPath .husky
    git config core.fileMode false
    
    # Create worklog
    cat > "$PROJECT_ON/worklog.md" << 'WLEOF'
# Worklog

## 2026-07-06 (1)
- Status: Active
- Task: A/B governance test
WLEOF
    
    # Commit worklog (skip hooks during setup)
    cd "$PROJECT_ON"
    git add worklog.md
    git commit --no-verify -q -m "chore: add worklog"
    
    log "Setup complete"
    log "  PROJECT_OFF: $PROJECT_OFF (no governance)"
    log "  PROJECT_ON:  $PROJECT_ON (with governance)"
}

# ============================================================================
# TASK — Simulate agent work with violations
# ============================================================================
cmd_task() {
    step "Simulating agent work (writing violating files)..."
    
    # The same "task" for both projects: create a registration form
    # This simulates what an AI agent would do without governance
    
    for project in "$PROJECT_OFF" "$PROJECT_ON"; do
        cd "$project"
        
        info "Writing to: $(basename "$project")"
        
        # VIOLATION 1: Monolithic file (>250 lines)
        # An agent might dump everything into one file
        cat > src/components/RegistrationForm.tsx << 'FORMEOF'
"use client";

import React, { useState, useCallback, useMemo, useEffect } from 'react';

interface FormData {
  email: string;
  password: string;
  confirmPassword: string;
  firstName: string;
  lastName: string;
  phone: string;
  address: string;
  city: string;
  country: string;
  zipCode: string;
  agreeToTerms: boolean;
  newsletter: boolean;
}

interface FormErrors {
  email?: string;
  password?: string;
  confirmPassword?: string;
  firstName?: string;
  lastName?: string;
  phone?: string;
  address?: string;
  city?: string;
  country?: string;
  zipCode?: string;
  agreeToTerms?: string;
}

export default function RegistrationForm() {
  const [formData, setFormData] = useState<FormData>({
    email: '',
    password: '',
    confirmPassword: '',
    firstName: '',
    lastName: '',
    phone: '',
    address: '',
    city: '',
    country: '',
    zipCode: '',
    agreeToTerms: false,
    newsletter: false,
  });
  
  const [errors, setErrors] = useState<FormErrors>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [passwordStrength, setPasswordStrength] = useState(0);
  
  // Email validation
  const validateEmail = (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };
  
  // Password strength calculator
  const calculatePasswordStrength = (password: string): number => {
    let strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (/[a-z]/.test(password) && /[A-Z]/.test(password)) strength++;
    if (/\d/.test(password)) strength++;
    if (/[^a-zA-Z0-9]/.test(password)) strength++;
    return strength;
  };
  
  // Phone validation
  const validatePhone = (phone: string): boolean => {
    const phoneRegex = /^\+?[\d\s-]{10,}$/;
    return phoneRegex.test(phone);
  };
  
  // Zip code validation
  const validateZipCode = (zipCode: string): boolean => {
    const zipRegex = /^\d{5}(-\d{4})?$/;
    return zipRegex.test(zipCode);
  };
  
  // Handle input change
  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    const checked = type === 'checkbox' ? (e.target as HTMLInputElement).checked : undefined;
    
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }));
    
    // Clear error when user starts typing
    if (errors[name as keyof FormErrors]) {
      setErrors(prev => ({
        ...prev,
        [name]: undefined,
      }));
    }
    
    // Update password strength
    if (name === 'password') {
      setPasswordStrength(calculatePasswordStrength(value));
    }
  }, [errors]);
  
  // Validate form
  const validateForm = useCallback((): boolean => {
    const newErrors: FormErrors = {};
    
    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!validateEmail(formData.email)) {
      newErrors.email = 'Invalid email format';
    }
    
    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 8) {
      newErrors.password = 'Password must be at least 8 characters';
    }
    
    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }
    
    if (!formData.firstName) {
      newErrors.firstName = 'First name is required';
    } else if (formData.firstName.length < 2) {
      newErrors.firstName = 'First name must be at least 2 characters';
    }
    
    if (!formData.lastName) {
      newErrors.lastName = 'Last name is required';
    } else if (formData.lastName.length < 2) {
      newErrors.lastName = 'Last name must be at least 2 characters';
    }
    
    if (formData.phone && !validatePhone(formData.phone)) {
      newErrors.phone = 'Invalid phone number';
    }
    
    if (!formData.address) {
      newErrors.address = 'Address is required';
    }
    
    if (!formData.city) {
      newErrors.city = 'City is required';
    }
    
    if (!formData.country) {
      newErrors.country = 'Country is required';
    }
    
    if (formData.zipCode && !validateZipCode(formData.zipCode)) {
      newErrors.zipCode = 'Invalid zip code';
    }
    
    if (!formData.agreeToTerms) {
      newErrors.agreeToTerms = 'You must agree to the terms';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [formData]);
  
  // Handle submit
  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }
    
    setIsSubmitting(true);
    
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 2000));
      setSubmitSuccess(true);
    } catch (error) {
      console.error('Registration failed:', error);
    } finally {
      setIsSubmitting(false);
    }
  }, [validateForm]);
  
  // Password strength color
  const strengthColor = useMemo(() => {
    if (passwordStrength <= 1) return 'bg-red-500';
    if (passwordStrength <= 2) return 'bg-orange-500';
    if (passwordStrength <= 3) return 'bg-yellow-500';
    if (passwordStrength <= 4) return 'bg-lime-500';
    return 'bg-green-500';
  }, [passwordStrength]);
  
  // Password strength text
  const strengthText = useMemo(() => {
    if (passwordStrength <= 1) return 'Very Weak';
    if (passwordStrength <= 2) return 'Weak';
    if (passwordStrength <= 3) return 'Fair';
    if (passwordStrength <= 4) return 'Strong';
    return 'Very Strong';
  }, [passwordStrength]);
  
  if (submitSuccess) {
    return (
      <div className="max-w-md mx-auto p-6 bg-white rounded-lg shadow-md">
        <h2 className="text-2xl font-bold text-green-600 mb-4">Registration Successful!</h2>
        <p className="text-gray-600">Thank you for registering. Please check your email to verify your account.</p>
      </div>
    );
  }
  
  return (
    <div className="max-w-md mx-auto p-6 bg-white rounded-lg shadow-md">
      <h2 className="text-2xl font-bold mb-6">Create Account</h2>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Email */}
        <div>
          <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
            Email *
          </label>
          <input
            type="email"
            id="email"
            name="email"
            value={formData.email}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md ${errors.email ? 'border-red-500' : 'border-gray-300'}`}
            placeholder="you@example.com"
          />
          {errors.email && <p className="text-red-500 text-sm mt-1">{errors.email}</p>}
        </div>
        
        {/* Password */}
        <div>
          <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
            Password *
          </label>
          <input
            type="password"
            id="password"
            name="password"
            value={formData.password}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md ${errors.password ? 'border-red-500' : 'border-gray-300'}`}
            placeholder="Min. 8 characters"
          />
          {formData.password && (
            <div className="mt-2">
              <div className="flex gap-1">
                {[1, 2, 3, 4, 5].map(i => (
                  <div
                    key={i}
                    className={`h-1 flex-1 rounded ${i <= passwordStrength ? strengthColor : 'bg-gray-200'}`}
                  />
                ))}
              </div>
              <p className="text-xs text-gray-500 mt-1">{strengthText}</p>
            </div>
          )}
          {errors.password && <p className="text-red-500 text-sm mt-1">{errors.password}</p>}
        </div>
        
        {/* Confirm Password */}
        <div>
          <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-1">
            Confirm Password *
          </label>
          <input
            type="password"
            id="confirmPassword"
            name="confirmPassword"
            value={formData.confirmPassword}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md ${errors.confirmPassword ? 'border-red-500' : 'border-gray-300'}`}
            placeholder="Repeat password"
          />
          {errors.confirmPassword && <p className="text-red-500 text-sm mt-1">{errors.confirmPassword}</p>}
        </div>
        
        {/* First Name */}
        <div>
          <label htmlFor="firstName" className="block text-sm font-medium text-gray-700 mb-1">
            First Name *
          </label>
          <input
            type="text"
            id="firstName"
            name="firstName"
            value={formData.firstName}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md ${errors.firstName ? 'border-red-500' : 'border-gray-300'}`}
          />
          {errors.firstName && <p className="text-red-500 text-sm mt-1">{errors.firstName}</p>}
        </div>
        
        {/* Last Name */}
        <div>
          <label htmlFor="lastName" className="block text-sm font-medium text-gray-700 mb-1">
            Last Name *
          </label>
          <input
            type="text"
            id="lastName"
            name="lastName"
            value={formData.lastName}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md ${errors.lastName ? 'border-red-500' : 'border-gray-300'}`}
          />
          {errors.lastName && <p className="text-red-500 text-sm mt-1">{errors.lastName}</p>}
        </div>
        
        {/* Phone */}
        <div>
          <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-1">
            Phone (optional)
          </label>
          <input
            type="tel"
            id="phone"
            name="phone"
            value={formData.phone}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md ${errors.phone ? 'border-red-500' : 'border-gray-300'}`}
            placeholder="+1 (555) 123-4567"
          />
          {errors.phone && <p className="text-red-500 text-sm mt-1">{errors.phone}</p>}
        </div>
        
        {/* Address */}
        <div>
          <label htmlFor="address" className="block text-sm font-medium text-gray-700 mb-1">
            Address *
          </label>
          <input
            type="text"
            id="address"
            name="address"
            value={formData.address}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md ${errors.address ? 'border-red-500' : 'border-gray-300'}`}
          />
          {errors.address && <p className="text-red-500 text-sm mt-1">{errors.address}</p>}
        </div>
        
        {/* City */}
        <div>
          <label htmlFor="city" className="block text-sm font-medium text-gray-700 mb-1">
            City *
          </label>
          <input
            type="text"
            id="city"
            name="city"
            value={formData.city}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md ${errors.city ? 'border-red-500' : 'border-gray-300'}`}
          />
          {errors.city && <p className="text-red-500 text-sm mt-1">{errors.city}</p>}
        </div>
        
        {/* Country */}
        <div>
          <label htmlFor="country" className="block text-sm font-medium text-gray-700 mb-1">
            Country *
          </label>
          <select
            id="country"
            name="country"
            value={formData.country}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md ${errors.country ? 'border-red-500' : 'border-gray-300'}`}
          >
            <option value="">Select country</option>
            <option value="US">United States</option>
            <option value="CA">Canada</option>
            <option value="UK">United Kingdom</option>
            <option value="DE">Germany</option>
            <option value="FR">France</option>
          </select>
          {errors.country && <p className="text-red-500 text-sm mt-1">{errors.country}</p>}
        </div>
        
        {/* Zip Code */}
        <div>
          <label htmlFor="zipCode" className="block text-sm font-medium text-gray-700 mb-1">
            Zip Code (optional)
          </label>
          <input
            type="text"
            id="zipCode"
            name="zipCode"
            value={formData.zipCode}
            onChange={handleChange}
            className={`w-full px-3 py-2 border rounded-md ${errors.zipCode ? 'border-red-500' : 'border-gray-300'}`}
            placeholder="12345"
          />
          {errors.zipCode && <p className="text-red-500 text-sm mt-1">{errors.zipCode}</p>}
        </div>
        
        {/* Agree to Terms */}
        <div className="flex items-center">
          <input
            type="checkbox"
            id="agreeToTerms"
            name="agreeToTerms"
            checked={formData.agreeToTerms}
            onChange={handleChange}
            className="h-4 w-4 text-blue-600 rounded"
          />
          <label htmlFor="agreeToTerms" className="ml-2 text-sm text-gray-600">
            I agree to the <a href="#" className="text-blue-600 hover:underline">Terms of Service</a> *
          </label>
        </div>
        {errors.agreeToTerms && <p className="text-red-500 text-sm">{errors.agreeToTerms}</p>}
        
        {/* Newsletter */}
        <div className="flex items-center">
          <input
            type="checkbox"
            id="newsletter"
            name="newsletter"
            checked={formData.newsletter}
            onChange={handleChange}
            className="h-4 w-4 text-blue-600 rounded"
          />
          <label htmlFor="newsletter" className="ml-2 text-sm text-gray-600">
            Subscribe to newsletter
          </label>
        </div>
        
        {/* Submit */}
        <button
          type="submit"
          disabled={isSubmitting}
          className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
        >
          {isSubmitting ? 'Creating Account...' : 'Create Account'}
        </button>
      </form>
    </div>
  );
}
FORMEOF
        
        # VIOLATION 2: Emoji in markdown
        cat > README.md << 'READMEEOF'
# 🚀 Registration Form

## ✨ Features

- 📧 Email validation
- 🔒 Password strength indicator
- 📱 Phone number support
- 🏠 Address form
- 🎉 Success animation

## 🛠️ Tech Stack

- React 19
- TypeScript
- Tailwind CSS

## 📦 Installation

```bash
npm install
npm run dev
```

## 📄 License

MIT
READMEEOF
        
        # VIOLATION 3: No worklog update (for project-on this should fail)
        
        # VIOLATION 4: Missing documentation for complex component
        
        log "Files written to $(basename "$project")"
    done
    
    # Show what we created
    echo ""
    info "=== Files created ==="
    for project in "$PROJECT_OFF" "$PROJECT_ON"; do
        echo ""
        echo "$(basename "$project"):"
        find "$project/src" -type f -name "*.tsx" -o -name "*.md" | while read f; do
            lines=$(wc -l < "$f")
            echo "  $(echo "$f" | sed "s|$project/||") ($lines lines)"
        done
    done
}

# ============================================================================
# COMMIT — Try to commit in both projects
# ============================================================================
cmd_commit() {
    step "Attempting commits..."
    
    # Track results
    local off_result="PASS"
    local on_result="PASS"
    local off_output=""
    local on_output=""
    
    # --- PROJECT OFF (no governance) ---
    echo ""
    info "=== PROJECT OFF (no governance) ==="
    cd "$PROJECT_OFF"
    git add -A
    
    if output=$(git commit -m "feat: add registration form" 2>&1); then
        off_result="PASS"
        off_output="$output"
        log "Commit PASSED (no governance to block it)"
    else
        off_result="FAIL"
        off_output="$output"
        warn "Commit FAILED (unexpected)"
    fi
    
    # --- PROJECT ON (with governance) ---
    echo ""
    info "=== PROJECT ON (with governance) ==="
    cd "$PROJECT_ON"
    git add -A
    
    if output=$(git commit -m "feat: add registration form" 2>&1); then
        on_result="PASS"
        on_output="$output"
        warn "Commit PASSED (governance did NOT block violations)"
    else
        on_result="FAIL"
        on_output="$output"
        log "Commit BLOCKED by governance"
    fi
    
    # Save results
    cat > "$RESULTS_DIR/commit-results.json" << CEOF
{
  "project_off": {
    "result": "$off_result",
    "output": $(echo "$off_output" | head -20 | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
  },
  "project_on": {
    "result": "$on_result",
    "output": $(echo "$on_output" | head -20 | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
  }
}
CEOF
    
    log "Results saved to $RESULTS_DIR/commit-results.json"
}

# ============================================================================
# COMPARE — Analyze results
# ============================================================================
cmd_compare() {
    step "Comparing results..."
    
    echo ""
    echo "=========================================="
    echo "  GOVERNANCE A/B TEST RESULTS"
    echo "=========================================="
    echo ""
    
    # --- File analysis ---
    echo "| Metric | GOV=OFF | GOV=ON |"
    echo "|--------|---------|--------|"
    
    # Count files
    local off_files=$(find "$PROJECT_OFF/src" -name "*.tsx" -o -name "*.ts" 2>/dev/null | wc -l)
    local on_files=$(find "$PROJECT_ON/src" -name "*.tsx" -o -name "*.ts" 2>/dev/null | wc -l)
    echo "| Files created | $off_files | $on_files |"
    
    # Count monolithic files (>250 lines)
    local off_mono=0
    local on_mono=0
    while IFS= read -r f; do
        lines=$(wc -l < "$f" 2>/dev/null || echo 0)
        if [ "$lines" -gt 250 ]; then
            off_mono=$((off_mono + 1))
        fi
    done < <(find "$PROJECT_OFF/src" -name "*.tsx" -o -name "*.ts" 2>/dev/null)
    while IFS= read -r f; do
        lines=$(wc -l < "$f" 2>/dev/null || echo 0)
        if [ "$lines" -gt 250 ]; then
            on_mono=$((on_mono + 1))
        fi
    done < <(find "$PROJECT_ON/src" -name "*.tsx" -o -name "*.ts" 2>/dev/null)
    echo "| Monolithic files (>250 lines) | $off_mono | $on_mono |"
    
    # Max file size
    local off_max=0
    local on_max=0
    while IFS= read -r f; do
        lines=$(wc -l < "$f" 2>/dev/null || echo 0)
        [ "$lines" -gt "$off_max" ] && off_max=$lines
    done < <(find "$PROJECT_OFF/src" -name "*.tsx" -o -name "*.ts" 2>/dev/null)
    while IFS= read -r f; do
        lines=$(wc -l < "$f" 2>/dev/null || echo 0)
        [ "$lines" -gt "$on_max" ] && on_max=$lines
    done < <(find "$PROJECT_ON/src" -name "*.tsx" -o -name "*.ts" 2>/dev/null)
    echo "| Max file size (lines) | $off_max | $on_max |"
    
    # Emoji in README
    local off_emoji=0
    local on_emoji=0
    [ -f "$PROJECT_OFF/README.md" ] && off_emoji=$(grep -cP '[\x{1F300}-\x{1F9FF}]' "$PROJECT_OFF/README.md" 2>/dev/null || echo 0)
    [ -f "$PROJECT_ON/README.md" ] && on_emoji=$(grep -cP '[\x{1F300}-\x{1F9FF}]' "$PROJECT_ON/README.md" 2>/dev/null || echo 0)
    echo "| Emoji lines in README | $off_emoji | $on_emoji |"
    
    # Worklog entries
    local off_worklog=0
    local on_worklog=0
    [ -f "$PROJECT_OFF/worklog.md" ] && off_worklog=$(grep -c "^##" "$PROJECT_OFF/worklog.md" 2>/dev/null || echo 0)
    [ -f "$PROJECT_ON/worklog.md" ] && on_worklog=$(grep -c "^##" "$PROJECT_ON/worklog.md" 2>/dev/null || echo 0)
    echo "| Worklog entries | $off_worklog | $on_worklog |"
    
    # Commit result — check git log for the feat commit
    local off_commit="FAIL"
    local on_commit="FAIL"
    if git -C "$PROJECT_OFF" log --oneline -5 2>/dev/null | grep -q "feat: add registration form"; then
        off_commit="PASS"
    fi
    if git -C "$PROJECT_ON" log --oneline -5 2>/dev/null | grep -q "feat: add registration form"; then
        on_commit="PASS"
    fi
    echo "| Commit result | $off_commit | $on_commit |"
    
    echo ""
    echo "=========================================="
    echo "  ANALYSIS"
    echo "=========================================="
    echo ""
    
    # Verdict
    if [ "$off_commit" = "PASS" ] && [ "$on_commit" = "FAIL" ]; then
        echo -e "${GREEN}✅ VERDICT: Governance WORKS${NC}"
        echo ""
        echo "   Without governance: monolithic ${off_max}-line component committed"
        echo "   With governance: commit BLOCKED (violations detected)"
        echo ""
        echo "   Governance caught:"
        [ "$off_mono" -gt 0 ] && echo "   - $off_mono monolithic file(s) (>250 lines)"
        [ "$off_emoji" -gt 0 ] && echo "   - $off_emoji emoji line(s) in README"
    elif [ "$off_commit" = "PASS" ] && [ "$on_commit" = "PASS" ]; then
        echo -e "${YELLOW}⚠️  VERDICT: Governance DID NOT block violations${NC}"
        echo "   Both commits passed — governance hooks may not be active"
        echo ""
        echo "   Debug: check if .husky/pre-commit exists and is executable"
        ls -la "$PROJECT_ON/.husky/pre-commit" 2>/dev/null || echo "   .husky/pre-commit NOT FOUND"
        echo ""
        echo "   Debug: check git hooks path"
        git -C "$PROJECT_ON" config core.hooksPath 2>/dev/null || echo "   core.hooksPath NOT SET"
    else
        echo -e "${YELLOW}⚠️  VERDICT: Unexpected result${NC}"
        echo "   OFF=$off_commit, ON=$on_commit"
    fi
    
    echo ""
    echo "=========================================="
}

# ============================================================================
# FULL — Run all steps
# ============================================================================
cmd_full() {
    cmd_setup
    echo ""
    cmd_task
    echo ""
    cmd_commit
    echo ""
    cmd_compare
}

# ============================================================================
# MAIN
# ============================================================================
case "${1:-help}" in
    setup)   cmd_setup ;;
    task)    cmd_task ;;
    commit)  cmd_commit ;;
    compare) cmd_compare ;;
    full)    cmd_full ;;
    *)
        echo "Usage: $0 {setup|task|commit|compare|full}"
        echo ""
        echo "  setup   — Create two test projects (on/off)"
        echo "  task    — Simulate agent work (write violating files)"
        echo "  commit  — Try to commit in both projects"
        echo "  compare — Compare results"
        echo "  full    — Run all steps sequentially"
        exit 1
        ;;
esac
