"""
KnowledgeService - Singleton service that loads structured JSON knowledge bases
and provides compact, AI-prompt-ready markdown strings for plan generation.

Also exposes raw data methods for API endpoints.
"""
import json
import logging
import random
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

# Root of the data directory
_DATA_DIR = Path(__file__).resolve().parent.parent / "data"
_PARSED_DIR = _DATA_DIR / "parsed"


class KnowledgeService:
    """Loads nutrition, exercise, and wellness knowledge from JSON files.

    Usage::

        kb = KnowledgeService.instance()
        md = kb.get_foods_for_user("vegetarian", "south_india")
    """

    _instance: "KnowledgeService | None" = None

    @classmethod
    def instance(cls) -> "KnowledgeService":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    @classmethod
    def reset(cls) -> None:
        """Drop the cached singleton (useful in tests)."""
        cls._instance = None

    # ------------------------------------------------------------------
    # Init / data loading
    # ------------------------------------------------------------------

    def __init__(self) -> None:
        self._nutrition_db: dict = self._load_json(
            _DATA_DIR / "indian_nutrition_knowledge_base.json", default={}
        )
        self._supplements: list = self._load_json(
            _PARSED_DIR / "supplements.json", default=[]
        )
        self._exercises_home: list = self._load_json(
            _PARSED_DIR / "exercises_home.json", default=[]
        )
        self._exercises_gym: list = self._load_json(
            _PARSED_DIR / "exercises_gym.json", default=[]
        )
        self._workout_programs: dict = self._load_json(
            _PARSED_DIR / "workout_programs.json", default={}
        )
        self._yoga: dict = self._load_json(
            _PARSED_DIR / "yoga_asanas.json", default={}
        )
        self._pranayama: list = self._load_json(
            _PARSED_DIR / "pranayama.json", default=[]
        )
        self._sleep: dict = self._load_json(
            _PARSED_DIR / "sleep_protocols.json", default={}
        )
        self._stress: dict = self._load_json(
            _PARSED_DIR / "stress_management.json", default={}
        )
        self._supplement_stacks: dict = self._load_json(
            _PARSED_DIR / "supplement_stacks.json", default={}
        )
        self._citations: list = self._load_json(
            _PARSED_DIR / "research_citations.json", default=[]
        )
        logger.info("KnowledgeService initialised")

    @staticmethod
    def _load_json(path: Path, default: Any = None) -> Any:
        """Load a JSON file; return *default* if the file is missing."""
        try:
            with open(path, "r", encoding="utf-8") as fh:
                return json.load(fh)
        except FileNotFoundError:
            logger.warning("Data file not found, using default: %s", path)
            return default if default is not None else {}
        except json.JSONDecodeError as exc:
            logger.error("Invalid JSON in %s: %s", path, exc)
            return default if default is not None else {}

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _foods_section(self) -> dict:
        return self._nutrition_db.get("section_2_indian_foods_nutritional_database", {})

    def _rda_section(self) -> dict:
        return self._nutrition_db.get("section_1_icmr_dietary_guidelines", {})

    def _regional_section(self) -> dict:
        return self._nutrition_db.get("section_3_regional_diet_patterns", {})

    def _goals_section(self) -> dict:
        return self._nutrition_db.get("section_4_nutrition_for_health_goals", {})

    def _synergy_section(self) -> dict:
        return self._nutrition_db.get("section_5_indian_food_combinations", {})

    def _gi_section(self) -> dict:
        return self._nutrition_db.get("section_6_glycemic_index_indian_foods", {})

    def _appendix(self) -> dict:
        return self._nutrition_db.get("appendix", {})

    @staticmethod
    def _fmt_food(f: dict) -> str:
        """One-line summary of a food item."""
        parts = [f"{f.get('calories_kcal', '?')} kcal"]
        if f.get("protein_g"):
            parts.append(f"{f['protein_g']}g protein")
        if f.get("calcium_mg") and f["calcium_mg"] >= 100:
            parts.append(f"{f['calcium_mg']}mg Ca")
        if f.get("iron_mg") and f["iron_mg"] >= 3:
            parts.append(f"{f['iron_mg']}mg Fe")
        gi = f.get("glycemic_index")
        if gi is not None:
            parts.append(f"GI {gi}")
        hindi = f.get("hindi_name", "")
        name = f.get("name", "Unknown")
        label = f"{name} ({hindi})" if hindi else name
        return f"- {label}: {', '.join(parts)}"

    # ------------------------------------------------------------------
    # Markdown-returning methods (for AI prompts)
    # ------------------------------------------------------------------

    def get_foods_for_user(self, diet_type: str, region: str) -> str:
        """Return relevant foods as markdown filtered by diet type and region.

        *diet_type*: vegetarian | non_veg | vegan | eggetarian
        *region*: north_india | south_india | east_india | west_india | pan_india
        """
        section = self._foods_section()
        if not section:
            return ""

        # Categories to always include
        veg_categories = [
            "cereals_and_millets",
            "pulses_and_legumes",
            "vegetables",
            "fruits",
            "dairy",
            "oils_and_fats",
            "nuts_and_seeds",
            "spices_and_herbs",
            "common_prepared_foods",
        ]
        # Non-veg / egg categories
        nonveg_categories = ["eggs_and_nonveg"]

        categories = list(veg_categories)
        if diet_type in ("non_veg", "eggetarian"):
            categories += nonveg_categories
        if diet_type == "vegan":
            # Exclude dairy
            categories = [c for c in categories if c != "dairy"]

        lines: list[str] = [f"## Relevant Foods ({diet_type.replace('_', ' ').title()}, {region.replace('_', ' ').title()})"]

        for cat_key in categories:
            foods = section.get(cat_key, [])
            if not foods:
                continue
            cat_label = cat_key.replace("_", " ").title()
            lines.append(f"### {cat_label}")
            for f in foods[:12]:  # cap per category for token economy
                lines.append(self._fmt_food(f))

        # Append regional info
        regional_md = self.get_regional_diet(region)
        if regional_md:
            lines.append("")
            lines.append(regional_md)

        return "\n".join(lines)

    def get_rda_for_user(self, age: int, gender: str, activity_level: str) -> str:
        """Return ICMR RDA values tailored to the user."""
        rda = self._rda_section()
        if not rda:
            return ""

        rda_data = rda.get("recommended_dietary_allowances_rda", {})
        lines = ["## ICMR RDA (Personalised)"]

        # Energy
        energy = rda_data.get("energy_requirements_kcal_per_day", {})
        gender_key = "men" if gender == "male" else "women"
        act_map = {
            "sedentary": "sedentary",
            "lightly_active": "moderate",
            "moderately_active": "moderate",
            "very_active": "heavy",
            "extremely_active": "heavy",
        }
        act_key = act_map.get(activity_level, "sedentary")

        if age >= 60:
            elderly = energy.get("elderly_60_plus", {})
            kcal = elderly.get(gender_key, {}).get(act_key, "N/A")
        elif age >= 18:
            adults = energy.get("adults_by_activity_level", {})
            kcal = adults.get(gender_key, {}).get(act_key, "N/A")
        elif age >= 16:
            kcal = energy.get("adolescents", {}).get("16_17_years", {}).get(gender, "N/A")
        elif age >= 13:
            kcal = energy.get("adolescents", {}).get("13_15_years", {}).get(gender, "N/A")
        elif age >= 10:
            kcal = energy.get("adolescents", {}).get("10_12_years", {}).get(gender, "N/A")
        else:
            kcal = "N/A"

        lines.append(f"- Energy: {kcal} kcal/day")

        # Protein
        protein = rda_data.get("protein_g_per_day", {})
        if age >= 18:
            adults_p = protein.get("adults", {})
            p_val = adults_p.get("men_reference_65kg" if gender == "male" else "women_reference_55kg", "N/A")
            lines.append(f"- Protein: {p_val}g/day (increase 20% for plant-heavy diet)")
        else:
            lines.append("- Protein: age-appropriate (see ICMR tables)")

        # Fat
        fat = rda_data.get("fat_g_per_day", {})
        fat_adults = fat.get("adults", {})
        fat_range = fat_adults.get(act_key, {}).get(gender_key, "25-35g")
        lines.append(f"- Visible fat: {fat_range}")

        # Macros
        macros = rda_data.get("macronutrient_energy_distribution", {})
        lines.append(f"- Carbs: {macros.get('carbohydrates', {}).get('percent_of_total_energy', '55-65%')} of energy")
        lines.append(f"- Fiber: {macros.get('fiber', {}).get('g_per_day', '30-40')}g/day")

        # Key micros
        micros = rda_data.get("key_micronutrient_rda", {})
        g_key = "adult_men" if gender == "male" else "adult_women_menstruating"
        iron = micros.get("iron_mg", {}).get(g_key, "19")
        calcium = micros.get("calcium_mg", {}).get("adults", 600)
        vit_d = micros.get("vitamin_d_iu", {}).get("all_ages", 600)
        b12 = micros.get("vitamin_b12_mcg", {}).get("adults", 2.2)
        zinc_key = "adult_men" if gender == "male" else "adult_women"
        zinc = micros.get("zinc_mg", {}).get(zinc_key, 12)

        lines.append(f"- Iron: {iron}mg | Calcium: {calcium}mg | Vit D: {vit_d} IU | B12: {b12} mcg | Zinc: {zinc}mg")

        return "\n".join(lines)

    def get_supplements_for_user(
        self,
        goals: list,
        gender: str,
        diet_type: str,
        conditions: list | None = None,
    ) -> str:
        """Return supplement recommendations filtered by goals and conditions."""
        conditions = conditions or []
        conditions_lower = [str(c).lower() for c in conditions]
        goals_lower = [str(g).lower() for g in goals]

        # If parsed supplements exist, use them
        if self._supplements:
            lines = ["## Recommended Supplements"]
            for s in self._supplements:
                name = s.get("name", "")
                tier = s.get("tier", 3)

                # Contraindication: Ashwagandha + thyroid/autoimmune
                if "ashwagandha" in name.lower():
                    if any(c in " ".join(conditions_lower) for c in ["thyroid", "autoimmune", "hyperthyroid"]):
                        continue

                # Iron only if confirmed deficiency
                if "iron" in name.lower() and "iron deficiency" not in " ".join(conditions_lower):
                    if tier >= 3:
                        continue

                # Tier 1 always included
                if tier == 1:
                    pass
                elif tier == 2:
                    s_goals = [str(g).lower() for g in s.get("goals", [])]
                    if not any(g in " ".join(goals_lower) for g in s_goals):
                        continue
                elif tier == 3:
                    s_goals = [str(g).lower() for g in s.get("goals", [])]
                    if not any(g in " ".join(goals_lower) for g in s_goals):
                        continue

                dose = s.get("dosage", "")
                when = s.get("when", "")
                cost = s.get("monthly_cost_inr", "")
                brands = s.get("brands", "")
                reason = s.get("reason", "")
                lines.append(f"- **{name}** (Tier {tier}): {dose}, {when}. {reason} ~INR {cost}. Brands: {brands}")
            return "\n".join(lines)

        # Fallback: build from hardcoded ICMR knowledge embedded in nutrition_db
        deficiencies = self._appendix().get("common_indian_nutritional_deficiencies", {}).get("deficiencies", [])
        if not deficiencies:
            return ""

        lines = ["## Key Supplement Considerations (ICMR data)"]
        for d in deficiencies:
            lines.append(f"- **{d['nutrient']}**: {d.get('prevalence', '')} | RDA: {d.get('rda', '')} | Solutions: {d.get('food_solutions', '')}")
        return "\n".join(lines)

    def get_exercises_for_user(
        self,
        location: str,
        equipment: str,
        experience: str,
        goals: list,
        time_minutes: int = 30,
    ) -> str:
        """Return exercise recommendations filtered by location, experience, time."""
        lines = [f"## Exercise Database ({location}, {experience}, {time_minutes}min)"]

        exercises = self._exercises_home if location == "home" else self._exercises_gym
        if exercises:
            exp_filter = {"beginner": ["beginner", "easy"], "intermediate": ["beginner", "intermediate"], "advanced": ["beginner", "intermediate", "advanced"]}
            allowed = exp_filter.get(experience, ["beginner", "intermediate"])

            # exercises is {muscle_group: [exercise_dicts]} for home, or may have "programs" key for gym
            if isinstance(exercises, dict):
                for group, exs in exercises.items():
                    if group in ("programs", "equipment_exercises", "progression_principles"):
                        continue
                    if not isinstance(exs, list):
                        continue
                    filtered = [ex for ex in exs if isinstance(ex, dict) and str(ex.get("difficulty", "beginner")).lower() in allowed]
                    if filtered:
                        lines.append(f"### {group.replace('_', ' ').title()}")
                        for ex in filtered[:5]:
                            name = ex.get("name", "")
                            sets = ex.get("sets_reps", ex.get("sets", ""))
                            lines.append(f"- {name}: {sets}")
            elif isinstance(exercises, list):
                by_group: dict[str, list] = {}
                for ex in exercises:
                    if not isinstance(ex, dict):
                        continue
                    lvl = str(ex.get("difficulty", "beginner")).lower()
                    if lvl not in allowed:
                        continue
                    group = ex.get("muscle_group", "other")
                    by_group.setdefault(group, []).append(ex)
                for group, exs in by_group.items():
                    lines.append(f"### {group.title()}")
                    for ex in exs[:5]:
                        name = ex.get("name", "")
                        sets = ex.get("sets_reps", ex.get("sets", ""))
                        lines.append(f"- {name}: {sets}")
        else:
            # Fallback: inline basics
            if location == "home":
                lines.append("### Bodyweight Exercises")
                lines.append("- Push-ups, Squats, Lunges, Plank, Mountain climbers, Burpees")
                lines.append("- Glute bridges, Calf raises, Tricep dips (chair), Superman")
            else:
                lines.append("### Gym Exercises")
                lines.append("- Bench press, Squats, Deadlift, Lat pulldown, OHP, Rows")
                lines.append("- Cable flys, Leg press, Curls, Tricep pushdowns")

        # Time-based routines from workout programs
        if self._workout_programs:
            programs = self._workout_programs
            if isinstance(programs, dict):
                for prog_name, prog_data in list(programs.items())[:2]:
                    lines.append(f"### Program: {prog_name}")
                    desc = prog_data if isinstance(prog_data, str) else str(prog_data)[:200]
                    lines.append(f"  {desc}")

        return "\n".join(lines)

    def get_regional_diet(self, region: str) -> str:
        """Return regional diet pattern for the given region."""
        section = self._regional_section()
        if not section:
            return ""

        region_map = {
            "north_india": "north_indian",
            "south_india": "south_indian",
            "east_india": "east_indian",
            "west_india": "west_indian",
            "pan_india": None,
        }
        key = region_map.get(region)
        if key is None:
            # pan_india: return a brief summary of all
            lines = ["## Regional Diet Patterns (Pan-India Overview)"]
            for rk, rdata in section.items():
                if not isinstance(rdata, dict):
                    continue
                staples = ", ".join(rdata.get("staple_grains", [])[:3])
                lines.append(f"- **{rk.replace('_', ' ').title()}**: Staples: {staples}")
            return "\n".join(lines)

        data = section.get(key, {})
        if not data:
            return ""

        lines = [f"## Regional Pattern: {key.replace('_', ' ').title()}"]
        lines.append(f"- Region: {data.get('region', '')}")
        lines.append(f"- Staples: {', '.join(data.get('staple_grains', []))}")
        lines.append(f"- Proteins: {', '.join(data.get('primary_proteins', []))}")
        lines.append(f"- Fats: {', '.join(data.get('key_fats', []))}")
        lines.append(f"- Signature dishes: {', '.join(data.get('signature_dishes', [])[:6])}")

        meal_pattern = data.get("typical_meal_pattern", {})
        if meal_pattern:
            lines.append("### Typical meals")
            for meal, desc in meal_pattern.items():
                lines.append(f"  - {meal}: {desc}")

        strengths = data.get("nutritional_strengths", [])
        if strengths:
            lines.append(f"- Strengths: {'; '.join(strengths[:4])}")
        concerns = data.get("nutritional_concerns", [])
        if concerns:
            lines.append(f"- Concerns: {'; '.join(concerns[:4])}")

        return "\n".join(lines)

    def get_sleep_protocol(self, profession: str | None = None) -> str:
        """Return sleep hygiene rules and optional profession-specific schedule."""
        if self._sleep:
            lines = ["## Sleep Protocol"]
            rules = self._sleep.get("rules", self._sleep.get("hygiene_rules", []))
            if isinstance(rules, list):
                for r in rules[:10]:
                    if isinstance(r, str):
                        lines.append(f"- {r}")
                    elif isinstance(r, dict):
                        lines.append(f"- {r.get('rule', r.get('name', ''))}: {r.get('detail', '')}")
            if profession:
                schedules = self._sleep.get("profession_schedules", {})
                sched = schedules.get(profession.lower())
                if sched:
                    lines.append(f"### Schedule for {profession}")
                    lines.append(f"  {sched}")
            return "\n".join(lines)
        return ""

    def get_pranayama(self) -> str:
        """Return all pranayama techniques as formatted string."""
        if not self._pranayama:
            return ""
        lines = ["## Pranayama Techniques"]
        items = self._pranayama if isinstance(self._pranayama, list) else self._pranayama.get("techniques", [])
        for t in items:
            if isinstance(t, dict):
                name = t.get("name", "")
                duration = t.get("duration", "")
                benefits = t.get("benefits", "")
                lines.append(f"- **{name}**: {duration}. {benefits}")
            else:
                lines.append(f"- {t}")
        return "\n".join(lines)

    def get_yoga_for_goals(self, goals: list) -> str:
        """Return yoga asanas filtered by health goals."""
        if not self._yoga:
            return ""
        lines = ["## Yoga Asanas for Goals"]
        goals_lower = [str(g).lower() for g in goals]

        if isinstance(self._yoga, dict):
            for goal_key, asanas in self._yoga.items():
                if goals_lower and not any(g in goal_key.lower() for g in goals_lower):
                    # Also include if goal_key is generic / always relevant
                    if goal_key.lower() not in ("general", "flexibility", "all"):
                        continue
                lines.append(f"### {goal_key.replace('_', ' ').title()}")
                if isinstance(asanas, list):
                    for a in asanas[:6]:
                        if isinstance(a, dict):
                            lines.append(f"- {a.get('name', '')}: {a.get('benefits', '')}")
                        else:
                            lines.append(f"- {a}")
        return "\n".join(lines)

    def get_stress_management(self) -> str:
        """Return stress management techniques."""
        if not self._stress:
            return ""
        lines = ["## Stress Management"]
        if isinstance(self._stress, dict):
            for key, val in self._stress.items():
                if isinstance(val, list):
                    lines.append(f"### {key.replace('_', ' ').title()}")
                    for item in val[:6]:
                        if isinstance(item, dict):
                            lines.append(f"- {item.get('name', item.get('technique', ''))}: {item.get('benefit', item.get('description', ''))}")
                        else:
                            lines.append(f"- {item}")
                elif isinstance(val, str):
                    lines.append(f"- **{key}**: {val}")
        return "\n".join(lines)

    def get_food_synergies(self) -> str:
        """Return food synergy combinations with scientific rationale."""
        section = self._synergy_section()
        combos = section.get("synergistic_combinations", [])
        if not combos:
            return ""
        lines = ["## Food Synergies (Research-Backed)"]
        for c in combos:
            combo = c.get("combination", "")
            rationale = c.get("scientific_rationale", "")
            refs = c.get("references", [])
            # Truncate rationale for token economy
            short = rationale[:200] + "..." if len(rationale) > 200 else rationale
            ref_str = f" [{refs[0]}]" if refs else ""
            lines.append(f"- **{combo}**: {short}{ref_str}")

        avoid = section.get("combinations_to_avoid", [])
        if avoid:
            lines.append("### Avoid")
            for a in avoid:
                lines.append(f"- {a.get('combination', '')}: {a.get('rationale', '')[:100]}")
        return "\n".join(lines)

    def get_gi_data(self) -> str:
        """Return glycemic index data for common Indian foods."""
        section = self._gi_section()
        gi_values = section.get("gi_values", {})
        if not gi_values:
            return ""
        lines = ["## Glycemic Index - Indian Foods"]
        for cat, foods in gi_values.items():
            lines.append(f"### {cat.replace('_', ' ').title()}")
            if isinstance(foods, list):
                for f in foods[:10]:
                    food_name = f.get("food", "")
                    gi = f.get("gi", "?")
                    cat_label = f.get("category", "")
                    gl = f.get("gl_per_serving", "")
                    gl_str = f", GL {gl}" if gl else ""
                    lines.append(f"- {food_name}: GI {gi} ({cat_label}){gl_str}")

        tips = section.get("tips_to_lower_glycemic_response", [])
        if tips:
            lines.append("### Tips to Lower GI Response")
            for t in tips[:6]:
                lines.append(f"- {t}")
        return "\n".join(lines)

    def get_deficiency_risks(self, diet_type: str, gender: str) -> str:
        """Return likely micronutrient deficiency risks based on diet and gender."""
        appendix = self._appendix()
        defs = appendix.get("common_indian_nutritional_deficiencies", {}).get("deficiencies", [])
        if not defs:
            return ""
        lines = ["## Common Deficiency Risks"]

        for d in defs:
            nutrient = d.get("nutrient", "")
            prevalence = d.get("prevalence", "")
            solutions = d.get("food_solutions", "")
            rda = d.get("rda", "")

            # Highlight B12 for vegetarians/vegans
            extra = ""
            if nutrient == "Vitamin B12" and diet_type in ("vegetarian", "vegan"):
                extra = " **[HIGH RISK for vegetarians]**"
            if nutrient == "Iron" and gender == "female":
                extra = " **[HIGH RISK for women]**"
            if nutrient == "Omega-3 Fatty Acids" and diet_type in ("vegetarian", "vegan"):
                extra = " **[HIGH RISK - no fish intake]**"

            lines.append(f"- **{nutrient}**{extra}: {prevalence}. RDA: {rda}. Food fixes: {solutions}")
        return "\n".join(lines)

    # ------------------------------------------------------------------
    # Raw data methods (for API endpoints, return dicts/lists)
    # ------------------------------------------------------------------

    def get_all_foods(self) -> list:
        """Return all foods from the nutrition database as a flat list of dicts with category."""
        section = self._foods_section()
        all_foods: list[dict] = []
        for cat_key, foods in section.items():
            if isinstance(foods, list):
                for food in foods:
                    item = dict(food)
                    item["category"] = cat_key
                    all_foods.append(item)
        return all_foods

    def get_all_supplements(self) -> list:
        """Return all supplements."""
        return list(self._supplements) if self._supplements else []

    def get_all_exercises(self, location: str | None = None) -> dict:
        """Return exercises, optionally filtered by location."""
        if location == "home":
            return {"home": self._exercises_home}
        if location == "gym":
            return {"gym": self._exercises_gym}
        return {"home": self._exercises_home, "gym": self._exercises_gym}

    def get_all_yoga(self) -> dict:
        """Return all yoga asanas by goal."""
        return dict(self._yoga) if isinstance(self._yoga, dict) else {}

    def get_all_pranayama(self) -> list:
        """Return all pranayama techniques."""
        if isinstance(self._pranayama, list):
            return list(self._pranayama)
        return self._pranayama.get("techniques", []) if isinstance(self._pranayama, dict) else []

    def get_sleep_data(self) -> dict:
        """Return full sleep protocols data."""
        return dict(self._sleep) if isinstance(self._sleep, dict) else {}

    def get_all_citations(self) -> list:
        """Return all research citations."""
        return list(self._citations) if self._citations else []

    def get_daily_tip(self) -> dict:
        """Return a random health tip from the knowledge base."""
        tips: list[str] = []

        # Gather tips from various sources
        gi_tips = self._gi_section().get("tips_to_lower_glycemic_response", [])
        tips.extend(gi_tips)

        synergies = self._synergy_section().get("synergistic_combinations", [])
        for s in synergies:
            combo = s.get("combination", "")
            rationale = s.get("scientific_rationale", "")
            if combo and rationale:
                tips.append(f"{combo}: {rationale[:120]}")

        superfoods = self._appendix().get("indian_superfoods_summary", {}).get("superfoods", [])
        for sf in superfoods:
            tips.append(f"{sf.get('name', '')}: {sf.get('why', '')[:120]}")

        if not tips:
            return {"tip": "Drink 8-10 glasses of water daily for optimal health.", "source": "ICMR"}

        chosen = random.choice(tips)
        return {"tip": chosen, "source": "JeevFit Knowledge Base"}

    def get_supplement_stacks(self) -> dict:
        """Return pre-built supplement stacks."""
        return dict(self._supplement_stacks) if isinstance(self._supplement_stacks, dict) else {}
