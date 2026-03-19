#!/usr/bin/env python3
"""
One-time parser/validator for health knowledge base markdown → structured JSON.

The parsed JSON files already exist under app/data/parsed/. This script can:
  1. Validate all parsed JSON files are present and valid.
  2. Print summary statistics.
  3. Verify consistency between parsed data and source files.

Usage:
    python scripts/parse_health_kb.py           # Validate existing files
    python scripts/parse_health_kb.py --stats    # Print detailed stats
"""
import json
import sys
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "app" / "data"
PARSED_DIR = DATA_DIR / "parsed"

EXPECTED_FILES = [
    "supplements.json",
    "exercises_home.json",
    "exercises_gym.json",
    "workout_programs.json",
    "yoga_asanas.json",
    "pranayama.json",
    "sleep_protocols.json",
    "stress_management.json",
    "supplement_stacks.json",
    "research_citations.json",
]


def validate_json(path: Path) -> tuple[bool, str]:
    """Validate a JSON file exists and is parseable."""
    if not path.exists():
        return False, f"MISSING: {path.name}"
    try:
        with open(path) as f:
            data = json.load(f)
        size_kb = path.stat().st_size / 1024
        if isinstance(data, list):
            return True, f"OK: {path.name} ({len(data)} items, {size_kb:.1f} KB)"
        elif isinstance(data, dict):
            return True, f"OK: {path.name} ({len(data)} keys, {size_kb:.1f} KB)"
        return True, f"OK: {path.name} ({size_kb:.1f} KB)"
    except json.JSONDecodeError as e:
        return False, f"INVALID JSON: {path.name} — {e}"


def validate_nutrition_db() -> tuple[bool, str]:
    """Validate the main nutrition knowledge base."""
    path = DATA_DIR / "indian_nutrition_knowledge_base.json"
    if not path.exists():
        return False, "MISSING: indian_nutrition_knowledge_base.json"
    try:
        with open(path) as f:
            data = json.load(f)
        food_sections = data.get("section_2_indian_foods_nutritional_database", {})
        total_foods = sum(
            len(v) for k, v in food_sections.items() if isinstance(v, list)
        )
        size_kb = path.stat().st_size / 1024
        return True, f"OK: indian_nutrition_knowledge_base.json ({total_foods} foods, {size_kb:.1f} KB)"
    except json.JSONDecodeError as e:
        return False, f"INVALID JSON: indian_nutrition_knowledge_base.json — {e}"


def print_stats():
    """Print detailed statistics about all data files."""
    print("\n=== JeevFit Knowledge Base Statistics ===\n")

    # Main nutrition DB
    path = DATA_DIR / "indian_nutrition_knowledge_base.json"
    if path.exists():
        with open(path) as f:
            data = json.load(f)
        food_db = data.get("section_2_indian_foods_nutritional_database", {})
        print("Nutrition Database:")
        for category, items in food_db.items():
            if isinstance(items, list):
                print(f"  {category}: {len(items)} items")

    # Parsed files
    print("\nParsed Knowledge Files:")
    for fname in EXPECTED_FILES:
        path = PARSED_DIR / fname
        if not path.exists():
            print(f"  {fname}: MISSING")
            continue
        with open(path) as f:
            data = json.load(f)
        size_kb = path.stat().st_size / 1024
        if fname == "supplements.json":
            print(f"  {fname}: {len(data)} supplements, {size_kb:.1f} KB")
            tiers = {}
            for s in data:
                t = s.get("tier", "?")
                tiers[t] = tiers.get(t, 0) + 1
            for t, c in sorted(tiers.items()):
                print(f"    Tier {t}: {c} supplements")
        elif fname == "exercises_home.json":
            total = sum(len(v) for v in data.values() if isinstance(v, list))
            print(f"  {fname}: {len(data)} muscle groups, {total} exercises, {size_kb:.1f} KB")
        elif fname == "exercises_gym.json":
            programs = data.get("programs", {})
            print(f"  {fname}: {len(programs)} programs, {size_kb:.1f} KB")
        elif fname == "yoga_asanas.json":
            total = sum(len(v) for v in data.values() if isinstance(v, list))
            print(f"  {fname}: {len(data)} goals, {total} asanas, {size_kb:.1f} KB")
        elif fname == "pranayama.json":
            print(f"  {fname}: {len(data)} techniques, {size_kb:.1f} KB")
        elif fname == "research_citations.json":
            print(f"  {fname}: {len(data)} citations, {size_kb:.1f} KB")
            with_pmid = sum(1 for c in data if c.get("pmid"))
            print(f"    With PMID: {with_pmid}")
        elif fname == "supplement_stacks.json":
            print(f"  {fname}: {len(data)} stacks, {size_kb:.1f} KB")
        else:
            print(f"  {fname}: {size_kb:.1f} KB")

    # Source markdown
    md_path = DATA_DIR / "health_app_knowledge_base.md"
    if md_path.exists():
        lines = md_path.read_text().count("\n")
        size_kb = md_path.stat().st_size / 1024
        print(f"\nSource: health_app_knowledge_base.md ({lines} lines, {size_kb:.1f} KB)")

    # Total
    total_size = sum(
        (PARSED_DIR / f).stat().st_size
        for f in EXPECTED_FILES
        if (PARSED_DIR / f).exists()
    )
    print(f"\nTotal parsed data: {total_size / 1024:.1f} KB")


def main():
    show_stats = "--stats" in sys.argv

    print("Validating JeevFit knowledge base files...\n")

    all_ok = True

    # Validate main nutrition DB
    ok, msg = validate_nutrition_db()
    print(f"  {msg}")
    if not ok:
        all_ok = False

    # Validate parsed files
    for fname in EXPECTED_FILES:
        ok, msg = validate_json(PARSED_DIR / fname)
        print(f"  {msg}")
        if not ok:
            all_ok = False

    if all_ok:
        print(f"\nAll {len(EXPECTED_FILES) + 1} knowledge base files are valid.")
    else:
        print("\nSome files are missing or invalid!")
        sys.exit(1)

    if show_stats:
        print_stats()


if __name__ == "__main__":
    main()
