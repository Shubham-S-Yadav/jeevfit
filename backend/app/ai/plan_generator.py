"""
AI-powered personalized plan generator.
Generates diet plans, exercise plans, supplement recommendations, and timetables.
All recommendations are research-backed with citations for Indian users.
"""
import asyncio
import json
import logging
import re
from datetime import date, timedelta
from functools import partial

from google.genai import types

from app.config import get_settings
from app.ai import get_gemini_client
from app.services.knowledge_service import KnowledgeService

logger = logging.getLogger(__name__)
settings = get_settings()


def _extract_json(response, label: str = "response") -> dict:
    """Robustly extract JSON from a Gemini response."""
    text = None

    # Try response.text first
    try:
        if response.text:
            text = response.text.strip()
    except Exception:
        pass

    # Fallback: dig into candidates/parts
    if not text and response.candidates:
        for part in response.candidates[0].content.parts:
            if hasattr(part, "text") and part.text:
                t = part.text.strip()
                if t.startswith("{") or t.startswith("[") or "```" in t:
                    text = t
                    break
                text = t

    if not text:
        logger.error(f"Empty {label} from Gemini. Candidates: {response.candidates}")
        raise ValueError(f"Failed to generate {label}. AI returned empty response.")

    # Strip markdown code fences
    if "```" in text:
        match = re.search(r"```(?:json)?\s*\n?(.*?)```", text, re.DOTALL)
        if match:
            text = match.group(1).strip()

    # Find first { to last }
    if not text.startswith("{"):
        start = text.find("{")
        end = text.rfind("}")
        if start != -1 and end != -1 and end > start:
            text = text[start : end + 1]

    # Fix common JSON issues from LLMs
    # Remove trailing commas before } or ]
    text = re.sub(r",\s*([}\]])", r"\1", text)
    # Remove comments
    text = re.sub(r"//.*?$", "", text, flags=re.MULTILINE)

    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse {label} (error: {e}): {text[:2000]}")
        raise ValueError(f"Failed to generate {label}. Please try again.")


# Knowledge is now loaded from structured JSON via KnowledgeService.
# See app/services/knowledge_service.py


def _build_user_context(profile: dict, assessment: dict | None = None) -> str:
    """Build a rich user context string from profile and assessment data."""
    bmi = profile.get("weight_kg", 70) / ((profile.get("height_cm", 170) / 100) ** 2)
    bmr_male = 10 * profile.get("weight_kg", 70) + 6.25 * profile.get("height_cm", 170) - 5 * profile.get("age", 25) + 5
    bmr_female = 10 * profile.get("weight_kg", 60) + 6.25 * profile.get("height_cm", 160) - 5 * profile.get("age", 25) - 161

    activity_multipliers = {
        "sedentary": 1.2, "lightly_active": 1.375, "moderately_active": 1.55,
        "very_active": 1.725, "extremely_active": 1.9
    }
    multiplier = activity_multipliers.get(profile.get("activity_level", "sedentary"), 1.2)

    if profile.get("gender") == "male":
        tdee = bmr_male * multiplier
    else:
        tdee = bmr_female * multiplier

    ctx = f"""
## USER PROFILE:
- Name: {profile.get('full_name', 'User')}
- Age: {profile.get('age', 25)} years, Gender: {profile.get('gender', 'not specified')}
- Height: {profile.get('height_cm', 170)} cm, Weight: {profile.get('weight_kg', 70)} kg
- BMI: {bmi:.1f} ({'Underweight' if bmi < 18.5 else 'Normal' if bmi < 25 else 'Overweight' if bmi < 30 else 'Obese'})
- Estimated BMR: {bmr_male if profile.get('gender') == 'male' else bmr_female:.0f} kcal/day
- Estimated TDEE: {tdee:.0f} kcal/day
- Region: {profile.get('region', 'pan_india')}
- Profession: {profile.get('profession', 'not specified')}
- Work hours: {profile.get('work_hours', '9:00-18:00')}
- Activity level: {profile.get('activity_level', 'sedentary')}

## SLEEP & LIFESTYLE:
- Sleep time: {profile.get('preferred_sleep_time', '23:00')} → Wake: {profile.get('preferred_wake_time', '07:00')}
- Current sleep: {profile.get('current_sleep_hours', 'unknown')} hours
- Stress level: {profile.get('stress_level', 'unknown')}/10
- Water intake: {profile.get('water_intake_liters', 'unknown')} L/day
- Smoking: {profile.get('smoking', False)}, Alcohol: {profile.get('alcohol', 'none')}
- Screen time: {profile.get('screen_time_hours', 'unknown')} hrs/day

## DIET PREFERENCES:
- Type: {profile.get('dietary_preference', 'vegetarian')}
- Allergies: {profile.get('food_allergies', 'None')}
- Cannot eat: {profile.get('foods_cant_eat', 'None')}
- Prefers: {profile.get('foods_prefer', 'No specific preference')}
- Meals/day: {profile.get('meals_per_day', 3)}
- Can meal prep: {profile.get('can_meal_prep', False)}
- Monthly food budget: ₹{profile.get('monthly_food_budget', 'flexible')}
- Diet adherence capacity: {profile.get('diet_adherence_level', 5)}/10
- Current diet: {json.dumps(profile.get('current_diet', {}), indent=2) if profile.get('current_diet') else 'Not specified'}

## EXERCISE PREFERENCES:
- Location: {profile.get('exercise_location', 'home')}
- Equipment: {profile.get('available_equipment', 'None/bodyweight only')}
- Time available: {profile.get('exercise_time_minutes', 30)} min/session
- Days/week: {profile.get('exercise_days_per_week', 3)}
- Experience: {profile.get('exercise_experience', 'beginner')}
- Exercise adherence capacity: {profile.get('exercise_adherence_level', 5)}/10

## HEALTH GOALS:
- Primary goals: {profile.get('fitness_goals', ['general_health'])}
- Specific concerns: {profile.get('specific_concerns', 'None')}

## MEDICAL:
- Conditions: {profile.get('medical_conditions', 'None')}
- Medications: {profile.get('current_medications', 'None')}
- Injuries: {profile.get('injuries', 'None')}
"""

    if assessment:
        ctx += f"""
## IMAGE ANALYSIS RESULTS:
- Estimated body fat: {assessment.get('estimated_body_fat_pct', 'N/A')}%
- Body type: {assessment.get('body_type', 'N/A')}
- Posture issues: {json.dumps(assessment.get('posture_analysis', {}), indent=2)}
- Muscle assessment: {json.dumps(assessment.get('muscle_assessment', {}), indent=2)}
- Fat distribution: {json.dumps(assessment.get('fat_distribution', {}), indent=2)}
- Skin concerns: {json.dumps(assessment.get('skin_assessment', {}), indent=2)}
- Hair concerns: {json.dumps(assessment.get('hair_assessment', {}), indent=2)}
- Overall score: {assessment.get('overall_health_score', 'N/A')}/100
- AI Summary: {assessment.get('summary', 'N/A')}
"""

    return ctx


async def generate_diet_plan(
    profile: dict, assessment: dict | None = None, plan_type: str = "weekly"
) -> dict:
    """Generate a personalized Indian diet plan with research backing."""
    client = get_gemini_client()

    user_context = _build_user_context(profile, assessment)

    # --- Build targeted knowledge context via KnowledgeService ---
    kb = KnowledgeService.instance()
    nutrition_ctx = kb.get_foods_for_user(
        profile.get("dietary_preference", "vegetarian"),
        profile.get("region", "pan_india"),
    )
    rda_ctx = kb.get_rda_for_user(
        profile.get("age", 25),
        profile.get("gender", "male"),
        profile.get("activity_level", "sedentary"),
    )
    supplement_ctx = kb.get_supplements_for_user(
        profile.get("fitness_goals", []),
        profile.get("gender", "male"),
        profile.get("dietary_preference", "vegetarian"),
        profile.get("medical_conditions", []),
    )
    synergy_ctx = kb.get_food_synergies()

    # Conditional context
    goals = profile.get("fitness_goals", [])
    conditions = profile.get("medical_conditions", []) or []
    gi_ctx = ""
    if any(g in str(goals) for g in ["fat_loss", "weight_loss"]) or any(
        c in str(conditions) for c in ["diabetes", "pcos"]
    ):
        gi_ctx = kb.get_gi_data()

    deficiency_ctx = kb.get_deficiency_risks(
        profile.get("dietary_preference", "vegetarian"),
        profile.get("gender", "male"),
    )
    regional_ctx = kb.get_regional_diet(profile.get("region", "pan_india"))

    # Build hard constraint strings
    allergies = profile.get("food_allergies") or []
    cant_eat = profile.get("foods_cant_eat") or []
    prefer = profile.get("foods_prefer") or []
    meds = profile.get("current_medications") or []
    conditions_list = profile.get("medical_conditions") or []

    hard_constraints = ""
    if allergies:
        hard_constraints += f"\n⛔ ALLERGIES (NEVER include these - life threatening): {', '.join(allergies)}"
    if cant_eat:
        hard_constraints += f"\n⛔ CANNOT EAT (user has explicitly said they will NOT eat these): {', '.join(cant_eat)}"
    if prefer:
        hard_constraints += f"\n✅ PREFERRED FOODS (prioritize these - user enjoys eating them): {', '.join(prefer)}"
    if conditions_list:
        hard_constraints += f"\n⚕️ MEDICAL CONDITIONS (adjust diet accordingly): {', '.join(conditions_list)}"
    if meds:
        hard_constraints += f"\n💊 CURRENT MEDICATIONS (check for food/supplement interactions): {', '.join(meds)}"

    diet_pref = profile.get("dietary_preference", "vegetarian")
    if diet_pref == "vegetarian":
        hard_constraints += "\n⛔ VEGETARIAN: Do NOT include any meat, fish, or eggs."
    elif diet_pref == "vegan":
        hard_constraints += "\n⛔ VEGAN: Do NOT include any animal products (no dairy, eggs, honey, meat, fish)."
    elif diet_pref == "eggetarian":
        hard_constraints += "\n⛔ EGGETARIAN: Do NOT include meat or fish. Eggs are OK."
    elif diet_pref == "jain":
        hard_constraints += "\n⛔ JAIN: Do NOT include root vegetables (onion, garlic, potato, ginger), meat, fish, or eggs."

    prompt = f"""You are India's top nutritionist with expertise in ICMR guidelines and evidence-based nutrition.

{nutrition_ctx}

{rda_ctx}

{supplement_ctx}

{synergy_ctx}

{gi_ctx}

{deficiency_ctx}

{regional_ctx}

{user_context}

## ⚠️ HARD CONSTRAINTS (MUST FOLLOW - NEVER VIOLATE):
{hard_constraints}

## YOUR TASK:
Create a DETAILED, PERSONALIZED {plan_type} Indian diet plan for this user.

CRITICAL RULES:
1. NEVER suggest foods the user is allergic to or cannot eat — this is NON-NEGOTIABLE
2. PRIORITIZE foods the user prefers/loves — build meals around these
3. Match their region's cuisine preferences ({profile.get('region', 'pan_india')})
4. Stay within their budget if specified
5. Adjust portions to their calorie/macro targets
6. Consider their adherence capacity - if low, keep it SIMPLE
7. Include SPECIFIC quantities (e.g., "2 medium rotis", "1 katori dal", "150ml curd")
8. Every recommendation must have a research basis
9. Supplements must NOT conflict with user's medical conditions or medications
10. If user has thyroid/autoimmune conditions, do NOT recommend Ashwagandha
11. Do NOT recommend Iron supplements unless user explicitly has confirmed iron deficiency

## EXAMPLE OUTPUT (Monday only - you must generate ALL 7 days):

{{
    "plan_name": "Balanced Indian Nutrition Plan",
    "daily_calories": 1800,
    "protein_g": 75,
    "carbs_g": 225,
    "fat_g": 55,
    "fiber_g": 32,
    "meal_plan": {{
        "monday": {{
            "early_morning": {{
                "time": "06:30",
                "items": [
                    {{"name": "Warm water with lemon", "qty": "1 glass (200ml)", "calories": 10, "protein": 0, "carbs": 3, "fat": 0, "benefit": "Kickstarts metabolism, Vitamin C"}}
                ],
                "total_calories": 10
            }},
            "breakfast": {{
                "time": "08:00",
                "items": [
                    {{"name": "Moong dal cheela", "qty": "2 medium", "calories": 180, "protein": 12, "carbs": 22, "fat": 5, "benefit": "High protein, low GI"}},
                    {{"name": "Mint chutney", "qty": "2 tbsp", "calories": 15, "protein": 0, "carbs": 3, "fat": 0, "benefit": "Digestion aid"}},
                    {{"name": "Curd", "qty": "1 katori (100g)", "calories": 60, "protein": 3, "carbs": 5, "fat": 3, "benefit": "Probiotics, calcium"}}
                ],
                "total_calories": 255
            }},
            "mid_morning_snack": {{
                "time": "10:30",
                "items": [
                    {{"name": "Soaked almonds", "qty": "8 pieces", "calories": 65, "protein": 2, "carbs": 2, "fat": 6, "benefit": "Vitamin E, healthy fats"}},
                    {{"name": "Green tea", "qty": "1 cup", "calories": 2, "protein": 0, "carbs": 0, "fat": 0, "benefit": "Antioxidants, metabolism"}}
                ],
                "total_calories": 67
            }},
            "lunch": {{
                "time": "13:00",
                "items": [
                    {{"name": "Brown rice", "qty": "1 katori (150g cooked)", "calories": 185, "protein": 4, "carbs": 39, "fat": 1, "benefit": "Complex carbs, fiber"}},
                    {{"name": "Rajma curry", "qty": "1 katori (150g)", "calories": 190, "protein": 13, "carbs": 33, "fat": 1, "benefit": "Protein, iron, fiber"}},
                    {{"name": "Mixed vegetable sabzi", "qty": "1 katori", "calories": 80, "protein": 2, "carbs": 10, "fat": 3, "benefit": "Vitamins, minerals"}},
                    {{"name": "Cucumber raita", "qty": "1 katori", "calories": 50, "protein": 2, "carbs": 4, "fat": 3, "benefit": "Cooling, probiotics"}}
                ],
                "total_calories": 505
            }},
            "evening_snack": {{
                "time": "16:30",
                "items": [
                    {{"name": "Roasted chana", "qty": "1 katori (30g)", "calories": 110, "protein": 6, "carbs": 18, "fat": 2, "benefit": "Protein, fiber, iron"}},
                    {{"name": "Masala chai", "qty": "1 cup (no sugar)", "calories": 30, "protein": 1, "carbs": 3, "fat": 1, "benefit": "Antioxidants"}}
                ],
                "total_calories": 140
            }},
            "dinner": {{
                "time": "20:00",
                "items": [
                    {{"name": "Multigrain roti", "qty": "2 medium", "calories": 200, "protein": 7, "carbs": 36, "fat": 4, "benefit": "Complex carbs, B vitamins"}},
                    {{"name": "Palak paneer", "qty": "1 katori (150g)", "calories": 220, "protein": 12, "carbs": 8, "fat": 15, "benefit": "Iron, calcium, protein"}},
                    {{"name": "Dal tadka", "qty": "1 katori", "calories": 120, "protein": 7, "carbs": 18, "fat": 3, "benefit": "Protein, folate"}}
                ],
                "total_calories": 540
            }},
            "before_bed": {{
                "time": "22:00",
                "items": [
                    {{"name": "Haldi doodh (turmeric milk)", "qty": "1 glass (200ml)", "calories": 100, "protein": 4, "carbs": 8, "fat": 5, "benefit": "Anti-inflammatory curcumin, sleep aid"}}
                ],
                "total_calories": 100
            }}
        }},
        "tuesday": {{ "...same structure as monday with different meals..." }},
        "wednesday": {{ "...same structure..." }},
        "thursday": {{ "...same structure..." }},
        "friday": {{ "...same structure..." }},
        "saturday": {{ "...same structure..." }},
        "sunday": {{ "...same structure..." }}
    }},
    "supplements": [
        {{
            "name": "Vitamin D3",
            "dosage": "2000 IU",
            "when": "Morning with breakfast",
            "reason": "70-90% Indians are Vitamin D deficient (Ritu & Gupta, 2014)",
            "safety": "No side effects at recommended dose. Upper limit 4000 IU/day (IOM)",
            "monthly_cost_inr": 300,
            "recommended_brand": "HealthKart HK Vitals / Carbamide Forte"
        }}
    ],
    "foods_to_emphasize": [
        {{"food": "Turmeric milk", "reason": "Anti-inflammatory curcumin (Hewlings & Kalman, 2017)", "frequency": "Daily before bed"}}
    ],
    "foods_to_avoid": [
        {{"food": "Refined sugar & maida", "reason": "Spikes insulin, promotes fat storage", "alternative": "Jaggery (moderate), whole wheat"}}
    ],
    "hydration_plan": {{
        "daily_target_liters": 3.0,
        "schedule": ["7:00 AM: 500ml warm water", "10:00 AM: 300ml", "1:00 PM: 500ml", "4:00 PM: 500ml", "7:00 PM: 500ml", "9:00 PM: 200ml"]
    }},
    "research_references": [
        {{"claim": "High protein increases satiety", "source": "Leidy et al., 2015, Adv Nutr", "summary": "Protein-rich breakfast reduces hunger"}}
    ],
    "goal_specific_notes": {{
        "general_health": "Focus on balanced macros with emphasis on micronutrient-rich Indian foods"
    }},
    "weekly_cheat_meal": {{
        "allowed": true,
        "guidelines": "1 cheat meal per week, preferably lunch on Sunday. Stay within +500 kcal of target."
    }}
}}

IMPORTANT: Generate complete meals for ALL 7 days (monday through sunday). Each day must have all 7 meal slots filled with real Indian food items. Make each day DIFFERENT with variety. Be PRACTICAL - these are meals an Indian person would actually cook and eat.

You MUST return ONLY valid JSON. No explanations, no markdown, no comments. Just the JSON object."""

    response = await asyncio.to_thread(
        client.models.generate_content,
        model=settings.GEMINI_MODEL,
        contents=prompt,
        config=types.GenerateContentConfig(
            temperature=0.4,
            max_output_tokens=65536,
            response_mime_type="application/json",
        ),
    )

    return _extract_json(response, "diet plan")


async def generate_exercise_plan(
    profile: dict, assessment: dict | None = None, plan_type: str = "weekly"
) -> dict:
    """Generate a personalized exercise plan."""
    client = get_gemini_client()

    user_context = _build_user_context(profile, assessment)

    # --- Build targeted knowledge context via KnowledgeService ---
    kb = KnowledgeService.instance()
    exercise_ctx = kb.get_exercises_for_user(
        profile.get("exercise_location", "home"),
        profile.get("available_equipment", "none"),
        profile.get("exercise_experience", "beginner"),
        profile.get("fitness_goals", []),
        profile.get("exercise_time_minutes", 30),
    )
    yoga_ctx = kb.get_yoga_for_goals(profile.get("fitness_goals", []))

    prompt = f"""You are India's top fitness coach and exercise physiologist.

{exercise_ctx}

{yoga_ctx}

{user_context}

## YOUR TASK:
Create a DETAILED, PERSONALIZED {plan_type} exercise plan.

CRITICAL RULES:
1. ONLY use exercises possible with user's available equipment and location
2. Match their experience level - don't give advanced exercises to beginners
3. Stay within their time constraint ({profile.get('exercise_time_minutes', 30)} min)
4. Respect their available days ({profile.get('exercise_days_per_week', 3)} days/week)
5. Consider injuries and medical conditions
6. Include warm-up and cool-down
7. Add yoga/pranayama for stress, sleep, and mental health
8. Include progressive overload plan
9. Address their specific health goals through exercise
10. Consider their adherence capacity

## EXAMPLE OUTPUT (showing monday and tuesday - you must generate ALL 7 days):

{{
    "plan_name": "Home Beginner Full Body Plan",
    "location": "home",
    "difficulty": "beginner",
    "duration_minutes": 30,
    "days_per_week": 3,
    "workout_plan": {{
        "monday": {{
            "focus": "Full Body Strength",
            "is_rest_day": false,
            "warmup": [
                {{"name": "Arm circles", "duration": "1 min", "instructions": "Stand tall, extend arms. Circle forward 15 times, then backward 15 times."}},
                {{"name": "High knees", "duration": "1 min", "instructions": "March in place lifting knees to hip height. Increase speed gradually."}},
                {{"name": "Bodyweight squats", "duration": "1 min", "instructions": "Slow tempo, focus on depth and form. 10 reps."}}
            ],
            "exercises": [
                {{
                    "name": "Push-ups (knee variation)",
                    "sets": 3,
                    "reps": "8-10",
                    "rest_seconds": 60,
                    "muscle_group": "chest",
                    "instructions": "Knees on ground, hands shoulder-width. Lower chest to floor, push back up. Keep core tight.",
                    "alternatives": ["Wall push-ups", "Incline push-ups on table"],
                    "calories_burned": 25
                }},
                {{
                    "name": "Bodyweight squats",
                    "sets": 3,
                    "reps": "12-15",
                    "rest_seconds": 60,
                    "muscle_group": "legs",
                    "instructions": "Feet shoulder-width, sit back like sitting in a chair. Go as deep as comfortable. Stand back up.",
                    "alternatives": ["Chair squats", "Wall sit 30 sec"],
                    "calories_burned": 30
                }},
                {{
                    "name": "Plank hold",
                    "sets": 3,
                    "reps": "20-30 sec",
                    "rest_seconds": 45,
                    "muscle_group": "core",
                    "instructions": "Forearms on ground, body in straight line from head to heels. Hold position, breathe normally.",
                    "alternatives": ["Knee plank"],
                    "calories_burned": 15
                }},
                {{
                    "name": "Glute bridges",
                    "sets": 3,
                    "reps": "12-15",
                    "rest_seconds": 45,
                    "muscle_group": "glutes",
                    "instructions": "Lie on back, knees bent, feet flat. Push hips up squeezing glutes. Lower slowly.",
                    "alternatives": ["Single-leg glute bridge"],
                    "calories_burned": 20
                }}
            ],
            "cooldown": [
                {{"name": "Standing forward fold", "duration": "30 sec"}},
                {{"name": "Quad stretch (each leg)", "duration": "30 sec"}},
                {{"name": "Child's pose", "duration": "1 min"}}
            ],
            "total_duration_min": 28,
            "estimated_calories_burned": 150
        }},
        "tuesday": {{
            "focus": "Active Recovery",
            "is_rest_day": true,
            "active_recovery": "15 min brisk walk + 10 min gentle stretching"
        }},
        "wednesday": {{ "...workout day with different exercises..." }},
        "thursday": {{ "...rest or active recovery..." }},
        "friday": {{ "...workout day..." }},
        "saturday": {{ "...rest or light activity..." }},
        "sunday": {{ "...rest day..." }}
    }},
    "yoga_plan": {{
        "morning_routine": [
            {{"name": "Surya Namaskar", "rounds": 3, "duration": "8 min", "benefits": "Full body warm-up, flexibility, circulation"}}
        ],
        "evening_routine": [
            {{"name": "Viparita Karani (Legs up wall)", "duration": "5 min", "benefits": "Reduces anxiety, improves circulation"}},
            {{"name": "Shavasana", "duration": "5 min", "benefits": "Deep relaxation, stress reduction"}}
        ],
        "pranayama": [
            {{"name": "Anulom Vilom", "duration": "5 min", "when": "Morning empty stomach", "benefits": "Balances nervous system, reduces anxiety"}},
            {{"name": "Bhramari", "duration": "3 min", "when": "Before bed", "benefits": "Calms mind, improves sleep"}}
        ]
    }},
    "progression": {{
        "week_1_2": "Focus on form and building habit. Use easier variations if needed.",
        "week_3_4": "Increase reps by 2-3 per set. Add 1 extra set if time allows.",
        "month_2": "Progress to harder variations (e.g., knee push-ups to standard push-ups).",
        "month_3": "Increase intensity. Add new exercises. Consider adding light weights."
    }},
    "goal_specific_notes": {{
        "general_health": "Consistent movement 3x/week builds a strong foundation for long-term health"
    }},
    "research_references": [
        {{"claim": "Bodyweight training improves strength in beginners", "source": "Harrison, 2010, J Strength Cond Res", "summary": "Progressive bodyweight exercises effective for untrained individuals"}}
    ],
    "safety_notes": [
        "Always warm up 3-5 minutes before exercise",
        "Stop immediately if you feel sharp or shooting pain",
        "Stay hydrated - sip water every 10-15 minutes",
        "Breathe normally during exercises, never hold your breath"
    ]
}}

IMPORTANT: Generate ALL 7 days (monday through sunday). Include 3-4 workout days and 3-4 rest/active recovery days based on user's days_per_week preference. Each workout day must have warmup, 4-6 exercises, and cooldown.

You MUST return ONLY valid JSON. No explanations, no markdown, no comments. Just the JSON object."""

    response = await asyncio.to_thread(
        client.models.generate_content,
        model=settings.GEMINI_MODEL,
        contents=prompt,
        config=types.GenerateContentConfig(
            temperature=0.4,
            max_output_tokens=65536,
            response_mime_type="application/json",
        ),
    )

    return _extract_json(response, "exercise plan")


async def generate_timetable(
    profile: dict, assessment: dict | None = None
) -> dict:
    """Generate a comprehensive daily timetable."""
    client = get_gemini_client()

    user_context = _build_user_context(profile, assessment)

    # --- Build targeted knowledge context via KnowledgeService ---
    kb = KnowledgeService.instance()
    sleep_ctx = kb.get_sleep_protocol(profile.get("profession"))
    stress_ctx = kb.get_stress_management()
    pranayama_ctx = kb.get_pranayama()

    prompt = f"""You are a lifestyle optimization expert specializing in Indian professionals.

{sleep_ctx}

{stress_ctx}

{pranayama_ctx}

{user_context}

## YOUR TASK:
Create a COMPREHENSIVE daily timetable that optimizes this user's health, productivity, and wellbeing.

Consider:
1. Their work hours and profession
2. Their sleep/wake preferences
3. When they can exercise
4. Meal timing for optimal nutrition
5. Stress management activities
6. Screen time management
7. Social/family time (important in Indian culture)
8. Skincare routine
9. Hydration schedule

## EXAMPLE OUTPUT:

{{
    "plan_name": "Optimized Daily Routine for IT Professional",
    "schedule": {{
        "weekday": {{
            "06:00": {{"activity": "Wake up + drink warm water with lemon", "category": "routine", "duration_min": 10, "health_benefit": "Kickstarts metabolism, hydration"}},
            "06:10": {{"activity": "Morning sunlight exposure (balcony/terrace)", "category": "health", "duration_min": 10, "health_benefit": "Sets circadian rhythm, Vitamin D synthesis"}},
            "06:20": {{"activity": "Pranayama - Anulom Vilom + Kapalbhati", "category": "wellness", "duration_min": 10, "health_benefit": "Reduces cortisol, improves focus"}},
            "06:30": {{"activity": "Exercise / workout", "category": "exercise", "duration_min": 30, "health_benefit": "Strength, cardiovascular health, mood boost"}},
            "07:00": {{"activity": "Cool-down stretching + shower", "category": "routine", "duration_min": 20, "health_benefit": "Recovery, hygiene"}},
            "07:20": {{"activity": "Skincare routine (cleanser + moisturizer + sunscreen)", "category": "health", "duration_min": 10, "health_benefit": "Skin protection, anti-aging"}},
            "07:30": {{"activity": "Breakfast (protein-rich: eggs/paneer/dal cheela + fruit)", "category": "nutrition", "duration_min": 20, "health_benefit": "Stable energy, muscle protein synthesis"}},
            "07:50": {{"activity": "Supplements: Vitamin D3 + B12 + Omega-3", "category": "health", "duration_min": 2, "health_benefit": "Address common Indian deficiencies"}},
            "08:00": {{"activity": "Commute / start work", "category": "work", "duration_min": 60, "health_benefit": "Use for podcast/audiobook"}},
            "09:00": {{"activity": "Deep work block 1", "category": "work", "duration_min": 90, "health_benefit": "Peak focus period (cortisol-driven)"}},
            "10:30": {{"activity": "Mid-morning snack + water (500ml)", "category": "nutrition", "duration_min": 10, "health_benefit": "Sustained energy, hydration"}},
            "10:40": {{"activity": "Deep work block 2", "category": "work", "duration_min": 80, "health_benefit": "Continued productivity"}},
            "12:00": {{"activity": "5-min walk + eye rest (20-20-20 rule)", "category": "health", "duration_min": 10, "health_benefit": "Reduces screen fatigue, improves circulation"}},
            "12:10": {{"activity": "Work block 3", "category": "work", "duration_min": 50, "health_benefit": "Complete morning tasks"}},
            "13:00": {{"activity": "Lunch (balanced: dal + roti/rice + sabzi + salad + curd)", "category": "nutrition", "duration_min": 30, "health_benefit": "Complete nutrition, gut health"}},
            "13:30": {{"activity": "Post-lunch walk (10 min)", "category": "health", "duration_min": 10, "health_benefit": "Blood sugar control, digestion (Indian tradition)"}},
            "13:40": {{"activity": "Work block 4", "category": "work", "duration_min": 110, "health_benefit": "Afternoon productivity (last caffeine by 1 PM)"}},
            "15:30": {{"activity": "Green tea + 5-min stretching", "category": "health", "duration_min": 10, "health_benefit": "Antioxidants, posture reset"}},
            "15:40": {{"activity": "Work block 5", "category": "work", "duration_min": 140, "health_benefit": "Close out work tasks"}},
            "18:00": {{"activity": "End work + commute home", "category": "routine", "duration_min": 60, "health_benefit": "Mental transition from work mode"}},
            "19:00": {{"activity": "Evening walk / light play / family time", "category": "social", "duration_min": 30, "health_benefit": "Bonding, stress relief, light activity"}},
            "19:30": {{"activity": "Evening snack (fruits/sprouts)", "category": "nutrition", "duration_min": 10, "health_benefit": "Pre-dinner nutrition"}},
            "19:40": {{"activity": "Hobby / personal time", "category": "personal", "duration_min": 20, "health_benefit": "Mental wellbeing, creative outlet"}},
            "20:00": {{"activity": "Dinner (lighter: roti + sabzi + dal, avoid heavy rice)", "category": "nutrition", "duration_min": 30, "health_benefit": "Lighter dinner = better sleep"}},
            "20:30": {{"activity": "Family time / conversation (no screens)", "category": "social", "duration_min": 30, "health_benefit": "Relationships, emotional health"}},
            "21:00": {{"activity": "Dim lights, no screens. Reading / light stretching", "category": "wellness", "duration_min": 30, "health_benefit": "Melatonin production begins"}},
            "21:30": {{"activity": "Night skincare + brush teeth", "category": "routine", "duration_min": 10, "health_benefit": "Skin repair preparation"}},
            "21:40": {{"activity": "Magnesium supplement + haldi doodh", "category": "health", "duration_min": 5, "health_benefit": "Sleep quality, anti-inflammatory"}},
            "21:45": {{"activity": "4-7-8 breathing or Yoga Nidra", "category": "wellness", "duration_min": 10, "health_benefit": "Activates parasympathetic system for sleep"}},
            "22:00": {{"activity": "Sleep", "category": "routine", "duration_min": 480, "health_benefit": "8 hours for optimal recovery and health"}}
        }},
        "weekend": {{
            "07:00": {{"activity": "Wake up naturally (no alarm)", "category": "routine", "duration_min": 10, "health_benefit": "Natural sleep cycle completion"}},
            "07:10": {{"activity": "Warm water + sunlight", "category": "health", "duration_min": 15, "health_benefit": "Circadian rhythm maintenance"}},
            "07:25": {{"activity": "Yoga / Surya Namaskar (extended session)", "category": "exercise", "duration_min": 30, "health_benefit": "Flexibility, strength, mindfulness"}},
            "08:00": {{"activity": "Shower + skincare", "category": "routine", "duration_min": 20, "health_benefit": "Self-care"}},
            "08:20": {{"activity": "Leisurely breakfast (try new healthy recipe)", "category": "nutrition", "duration_min": 30, "health_benefit": "Nutrition variety, cooking skill"}},
            "09:00": {{"activity": "Meal prep for the week", "category": "nutrition", "duration_min": 60, "health_benefit": "Ensures healthy eating all week"}},
            "10:00": {{"activity": "Hobby / learning / personal project", "category": "personal", "duration_min": 120, "health_benefit": "Growth mindset, fulfillment"}},
            "12:00": {{"activity": "Outdoor activity (park/sports/walk)", "category": "exercise", "duration_min": 60, "health_benefit": "Nature exposure, vitamin D, social"}},
            "13:00": {{"activity": "Lunch", "category": "nutrition", "duration_min": 30, "health_benefit": "Balanced nutrition"}},
            "13:30": {{"activity": "Rest / nap (20 min max)", "category": "wellness", "duration_min": 30, "health_benefit": "Recovery without disrupting night sleep"}},
            "14:00": {{"activity": "Social time / friends / family outing", "category": "social", "duration_min": 180, "health_benefit": "Social bonds, mental health"}},
            "17:00": {{"activity": "Evening tea + light snack", "category": "nutrition", "duration_min": 15, "health_benefit": "Sustained energy"}},
            "17:15": {{"activity": "Week review + next week planning", "category": "personal", "duration_min": 30, "health_benefit": "Reduces Monday anxiety"}},
            "17:45": {{"activity": "Grocery shopping (healthy items)", "category": "routine", "duration_min": 45, "health_benefit": "Stock healthy options for the week"}},
            "18:30": {{"activity": "Cook dinner together with family", "category": "social", "duration_min": 45, "health_benefit": "Bonding, healthy food control"}},
            "19:15": {{"activity": "Dinner", "category": "nutrition", "duration_min": 30, "health_benefit": "Home-cooked nutrition"}},
            "19:45": {{"activity": "Evening walk with family", "category": "social", "duration_min": 30, "health_benefit": "Digestion, bonding"}},
            "20:15": {{"activity": "Movie / relaxation (limit screen brightness)", "category": "personal", "duration_min": 90, "health_benefit": "Rest and enjoyment"}},
            "21:45": {{"activity": "Wind-down routine (same as weekday)", "category": "wellness", "duration_min": 15, "health_benefit": "Consistent sleep signal"}},
            "22:00": {{"activity": "Sleep", "category": "routine", "duration_min": 540, "health_benefit": "Extra recovery on weekends"}}
        }}
    }},
    "weekly_goals": {{
        "exercise": "Complete 3 workout sessions",
        "nutrition": "Follow diet plan at least 80% of meals",
        "sleep": "Get 7-8 hours of sleep on 6/7 nights",
        "hydration": "Drink 3L water daily",
        "stress": "10 min meditation/pranayama daily",
        "social": "Quality time with family/friends 3x per week",
        "progress": "Log weight and measurements once per week"
    }},
    "monthly_goals": {{
        "body": "Improve body composition gradually",
        "fitness": "Increase exercise capacity by 10-15%",
        "habits": "Build consistent sleep schedule",
        "health": "Get blood work done (Vitamin D, B12, Iron, Lipid profile, Thyroid)",
        "appearance": "Noticeable skin/hair improvement with consistent nutrition"
    }},
    "habit_stacking_tips": [
        "After brushing teeth -> drink warm water (links to existing habit)",
        "After lunch -> 10 min walk (aids digestion, breaks sedentary behavior)",
        "After dinner -> 10 min family walk (bonding + digestion)"
    ]
}}

IMPORTANT: Adjust ALL times based on the user's actual sleep/wake preferences and work hours. Generate a complete schedule for both weekday and weekend with realistic Indian lifestyle activities.

You MUST return ONLY valid JSON. No explanations, no markdown, no comments. Just the JSON object."""

    response = await asyncio.to_thread(
        client.models.generate_content,
        model=settings.GEMINI_MODEL,
        contents=prompt,
        config=types.GenerateContentConfig(
            temperature=0.4,
            max_output_tokens=65536,
            response_mime_type="application/json",
        ),
    )

    return _extract_json(response, "timetable")


async def generate_meal_alternative(
    profile: dict,
    meal_context: dict,
    conversation: list[dict],
) -> dict:
    """Generate alternative meal suggestions based on user's situation.

    Args:
        profile: User's health profile dict
        meal_context: The original meal being replaced {day, meal_type, items, total_calories, protein, ...}
        conversation: List of {role: "user"|"assistant", text: "..."} messages
    """
    client = get_gemini_client()
    kb = KnowledgeService.instance()

    # Build user constraint context
    allergies = profile.get("food_allergies") or []
    cant_eat = profile.get("foods_cant_eat") or []
    prefer = profile.get("foods_prefer") or []
    conditions = profile.get("medical_conditions") or []
    diet_pref = profile.get("dietary_preference", "vegetarian")
    region = profile.get("region", "pan_india")

    # Get relevant food data
    nutrition_ctx = kb.get_foods_for_user(diet_pref, region)
    synergy_ctx = kb.get_food_synergies()

    # Format the original meal
    original_items = meal_context.get("items", [])
    original_desc = ""
    for item in original_items:
        if isinstance(item, dict):
            original_desc += f"  - {item.get('name', '?')} ({item.get('qty', '?')}) — {item.get('calories', '?')} cal, {item.get('protein', '?')}g protein\n"
        else:
            original_desc += f"  - {item}\n"

    target_calories = meal_context.get("total_calories", 300)
    target_protein = sum(
        (item.get("protein", 0) if isinstance(item, dict) else 0)
        for item in original_items
    )

    # Format conversation history
    chat_history = ""
    for msg in conversation:
        role = "User" if msg.get("role") == "user" else "Nutritionist"
        chat_history += f"\n{role}: {msg.get('text', '')}"

    # Build hard constraints
    constraints = []
    if allergies:
        constraints.append(f"⛔ ALLERGIES (LIFE-THREATENING — NEVER suggest): {', '.join(allergies)}")
    if cant_eat:
        constraints.append(f"⛔ WILL NOT EAT: {', '.join(cant_eat)}")
    if prefer:
        constraints.append(f"✅ LOVES EATING: {', '.join(prefer)}")
    if conditions:
        constraints.append(f"⚕️ MEDICAL CONDITIONS: {', '.join(conditions)}")

    diet_rules = {
        "vegetarian": "No meat, fish, or eggs",
        "vegan": "No animal products at all (no dairy, eggs, honey, meat, fish)",
        "eggetarian": "No meat or fish. Eggs OK.",
        "jain": "No root vegetables (onion, garlic, potato), no meat/fish/eggs",
    }
    if diet_pref in diet_rules:
        constraints.append(f"⛔ DIET: {diet_pref.upper()} — {diet_rules[diet_pref]}")

    constraints_text = "\n".join(constraints) if constraints else "No specific restrictions."

    prompt = f"""You are a friendly Indian nutritionist helping a user find meal alternatives.

## KNOWLEDGE BASE:
{nutrition_ctx}

{synergy_ctx}

## USER PROFILE:
- Diet: {diet_pref}, Region: {region}
- Age: {profile.get('age')}, Gender: {profile.get('gender')}
- Goals: {profile.get('fitness_goals', [])}

## ⚠️ HARD CONSTRAINTS (NEVER VIOLATE):
{constraints_text}

## ORIGINAL MEAL ({meal_context.get('day', 'today').title()} — {meal_context.get('meal_type', 'meal').replace('_', ' ').title()}):
{original_desc}
Target: ~{target_calories} calories, ~{target_protein}g protein

## CONVERSATION SO FAR:
{chat_history}

## YOUR TASK:
Respond to the user's latest message. Suggest 2-3 alternative meal options that:
1. Match the same calorie range (~{target_calories} cal ± 15%)
2. Match the same protein target (~{target_protein}g ± 20%)
3. RESPECT all hard constraints above (allergies, diet type, dislikes)
4. PRIORITIZE foods the user loves
5. Are practical Indian meals the user can easily make or find
6. Consider the user's situation (traveling, fasting, ingredient unavailable, etc.)

Return a JSON object:
{{
    "message": "Your friendly response to the user explaining the alternatives",
    "alternatives": [
        {{
            "name": "Alternative meal name",
            "items": [
                {{"name": "Food item", "qty": "quantity", "calories": 120, "protein": 8, "benefit": "why this is good"}}
            ],
            "total_calories": 300,
            "total_protein": 15,
            "why": "Brief reason this alternative works for the user's situation"
        }}
    ]
}}

Be warm, conversational, and knowledgeable. Use Indian food names. If the user is fasting, respect the specific type of fast (Hindu, Jain, etc.) and suggest appropriate foods.

You MUST return ONLY valid JSON. No markdown, no comments."""

    response = await asyncio.to_thread(
        client.models.generate_content,
        model=settings.GEMINI_MODEL,
        contents=prompt,
        config=types.GenerateContentConfig(
            temperature=0.6,
            max_output_tokens=16384,
            response_mime_type="application/json",
        ),
    )

    return _extract_json(response, "meal alternative")
