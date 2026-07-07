#!/usr/bin/env python3
"""
Quick validation script for skills - minimal version
"""

import sys
import os
import re
import yaml
from pathlib import Path


def validate_skill(skill_path):
    """Basic validation of a skill"""
    skill_path = Path(skill_path)

    # Check SKILL.md exists
    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        return False, "SKILL.md not found"

    # Read and validate frontmatter
    content = skill_md.read_text()
    if not content.startswith("---"):
        return False, "No YAML frontmatter found"

    # Extract frontmatter
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format"

    frontmatter_text = match.group(1)

    # Parse YAML frontmatter
    try:
        frontmatter = yaml.safe_load(frontmatter_text)
        if not isinstance(frontmatter, dict):
            return False, "Frontmatter must be a YAML dictionary"
    except yaml.YAMLError as e:
        return False, f"Invalid YAML in frontmatter: {e}"

    # Define allowed properties
    # Core fields (required): name, description
    # Optional fields:
    #   - license, allowed-tools, metadata (Z.ai spec)
    #   - compatibility (toolkit spec)
    #   - id, version, trigger, aligned_with (ZAI-META ID system, see id-assignment-guide.md)
    ALLOWED_PROPERTIES = {
        "name",
        "description",
        "license",
        "allowed-tools",
        "metadata",
        "compatibility",
        "id",
        "version",
        "trigger",
        "aligned_with",
    }

    # Check for unexpected properties (excluding nested keys under metadata)
    unexpected_keys = set(frontmatter.keys()) - ALLOWED_PROPERTIES
    if unexpected_keys:
        return False, (
            f"Unexpected key(s) in SKILL.md frontmatter: {', '.join(sorted(unexpected_keys))}. "
            f"Allowed properties are: {', '.join(sorted(ALLOWED_PROPERTIES))}"
        )

    # Validate ID field if present (ZAI-<DOMAIN>-<NNN> format)
    skill_id = frontmatter.get("id", "")
    if skill_id:
        if not isinstance(skill_id, str):
            return False, f"id must be a string, got {type(skill_id).__name__}"
        if not re.match(r"^ZAI-[A-Z]+-\d{3}$", skill_id.strip()):
            return False, (
                f"id '{skill_id}' must match format ZAI-<DOMAIN>-<NNN> "
                f"(e.g. ZAI-DEVTOOLS-002). Domains: MEM, FS, SESSION, DEV, ARCH, "
                f"QA, REQ, META, DEVTOOLS, GIT, SDK, SEC, DOC, HEALTH."
            )

    # Validate trigger field if present (comma-separated keywords)
    trigger = frontmatter.get("trigger", "")
    if trigger:
        if not isinstance(trigger, str):
            return False, f"trigger must be a string, got {type(trigger).__name__}"
        if len(trigger) > 500:
            return (
                False,
                f"trigger is too long ({len(trigger)} characters). Maximum is 500 characters.",
            )

    # Validate version field if present (YAML may parse 1.1 as float, 1.0.0 stays string)
    version = frontmatter.get("version", "")
    if version or version == 0:
        if isinstance(version, (int, float)):
            version = str(version)
        if not isinstance(version, str):
            return (
                False,
                f"version must be a string or number, got {type(version).__name__}",
            )
        if not re.match(r"^\d+\.\d+(\.\d+)?$", version.strip()):
            return (
                False,
                f"version '{version}' must be in semver-like format (e.g. 1.0 or 1.0.0)",
            )

    # Validate aligned_with field if present
    aligned_with = frontmatter.get("aligned_with", "")
    if aligned_with:
        if not isinstance(aligned_with, str):
            return (
                False,
                f"aligned_with must be a string, got {type(aligned_with).__name__}",
            )
        if len(aligned_with) > 200:
            return (
                False,
                f"aligned_with is too long ({len(aligned_with)} characters). Maximum is 200 characters.",
            )

    # Check required fields
    if "name" not in frontmatter:
        return False, "Missing 'name' in frontmatter"
    if "description" not in frontmatter:
        return False, "Missing 'description' in frontmatter"

    # Extract name for validation
    name = frontmatter.get("name", "")
    if not isinstance(name, str):
        return False, f"Name must be a string, got {type(name).__name__}"
    name = name.strip()
    if name:
        # Check naming convention (kebab-case: lowercase with hyphens)
        if not re.match(r"^[a-z0-9-]+$", name):
            return (
                False,
                f"Name '{name}' should be kebab-case (lowercase letters, digits, and hyphens only)",
            )
        if name.startswith("-") or name.endswith("-") or "--" in name:
            return (
                False,
                f"Name '{name}' cannot start/end with hyphen or contain consecutive hyphens",
            )
        # Check name length (max 64 characters per spec)
        if len(name) > 64:
            return (
                False,
                f"Name is too long ({len(name)} characters). Maximum is 64 characters.",
            )

    # Extract and validate description
    description = frontmatter.get("description", "")
    if not isinstance(description, str):
        return False, f"Description must be a string, got {type(description).__name__}"
    description = description.strip()
    if description:
        # Check for angle brackets
        if "<" in description or ">" in description:
            return False, "Description cannot contain angle brackets (< or >)"
        # Check description length (max 1024 characters per spec)
        if len(description) > 1024:
            return (
                False,
                f"Description is too long ({len(description)} characters). Maximum is 1024 characters.",
            )

    # Validate compatibility field if present (optional)
    compatibility = frontmatter.get("compatibility", "")
    if compatibility:
        if not isinstance(compatibility, str):
            return (
                False,
                f"Compatibility must be a string, got {type(compatibility).__name__}",
            )
        if len(compatibility) > 500:
            return (
                False,
                f"Compatibility is too long ({len(compatibility)} characters). Maximum is 500 characters.",
            )

    return True, "Skill is valid!"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)

    valid, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if valid else 1)
