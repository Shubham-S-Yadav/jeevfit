from fastapi import APIRouter, Query

from app.services.knowledge_service import KnowledgeService
from app.schemas.knowledge import (
    FoodsResponse,
    SupplementsResponse,
    ExercisesResponse,
    YogaResponse,
    PranayamaResponse,
    SleepProtocolResponse,
    FoodSynergiesResponse,
    DailyTipResponse,
    CitationsResponse,
)

router = APIRouter(prefix="/knowledge", tags=["Knowledge Base"])


@router.get("/foods", response_model=FoodsResponse)
async def get_foods(
    category: str | None = Query(None, description="Filter by category: cereals_and_millets, pulses_and_legumes, etc."),
    diet_type: str | None = Query(None, description="Filter: vegetarian, non_vegetarian, vegan, eggetarian"),
    region: str | None = Query(None, description="Filter: north_india, south_india, east_india, west_india"),
    search: str | None = Query(None, description="Search by name (English or Hindi)"),
):
    """Browse 139+ Indian foods with nutritional data."""
    kb = KnowledgeService.instance()
    foods = kb.get_all_foods()

    # Apply category filter
    if category:
        foods = [f for f in foods if f.get("category") == category]

    # Apply diet_type filter: vegetarian excludes eggs_and_nonveg
    if diet_type:
        if diet_type == "vegetarian":
            foods = [f for f in foods if f.get("category") != "eggs_and_nonveg"]
        elif diet_type == "vegan":
            foods = [
                f for f in foods
                if f.get("category") not in ("eggs_and_nonveg", "dairy")
            ]
        elif diet_type == "eggetarian":
            foods = [
                f for f in foods
                if f.get("category") != "eggs_and_nonveg"
                or "egg" in f.get("name", "").lower()
            ]
        elif diet_type == "non_vegetarian":
            pass  # no filtering needed

    # Apply region filter
    if region:
        foods = [f for f in foods if f.get("region") == region]

    # Apply search filter (case-insensitive on name and hindi_name)
    if search:
        query = search.lower()
        foods = [
            f for f in foods
            if query in f.get("name", "").lower()
            or query in (f.get("hindi_name") or "").lower()
        ]

    categories = sorted({f.get("category", "") for f in foods if f.get("category")})

    return FoodsResponse(
        foods=foods,
        total=len(foods),
        categories=categories,
    )


@router.get("/supplements", response_model=SupplementsResponse)
async def get_supplements(
    goal: str | None = Query(None, description="Filter by goal: stress, sleep, muscle, skin, hair, immunity, etc."),
    tier: int | None = Query(None, description="Filter by tier: 1 (essential), 2 (goal-based), 3 (specific)"),
):
    """Get 14 evidence-based supplements with dosages, brands, contraindications."""
    kb = KnowledgeService.instance()
    supplements = kb.get_all_supplements()

    if tier is not None:
        supplements = [s for s in supplements if s.get("tier") == tier]

    if goal:
        goal_lower = goal.lower()
        supplements = [
            s for s in supplements
            if any(goal_lower in g.lower() for g in s.get("goals") or [])
        ]

    return SupplementsResponse(
        supplements=supplements,
        total=len(supplements),
    )


@router.get("/exercises", response_model=ExercisesResponse)
async def get_exercises(
    location: str = Query("home", description="home or gym"),
    muscle_group: str | None = Query(None, description="Filter: chest, back, shoulders, legs, arms, core"),
    difficulty: str | None = Query(None, description="Filter: beginner, intermediate, advanced"),
):
    """Exercise library filtered by location and muscle group."""
    kb = KnowledgeService.instance()
    raw = kb.get_all_exercises(location)

    # get_all_exercises may return {location: {groups}} or {groups} directly
    if isinstance(raw, dict) and location in raw:
        exercises = raw[location]
    elif isinstance(raw, dict):
        # Check if keys look like muscle groups or locations
        first_val = next(iter(raw.values()), None) if raw else None
        if isinstance(first_val, dict):
            # Nested: pick first location
            exercises = first_val
        else:
            exercises = raw
    else:
        exercises = {}

    # exercises is expected to be a dict: muscle_group -> list of exercises
    if muscle_group:
        exercises = {
            k: v for k, v in exercises.items()
            if k.lower() == muscle_group.lower()
        }

    if difficulty:
        diff_lower = difficulty.lower()
        exercises = {
            k: [e for e in v if (e.get("difficulty") or "").lower() == diff_lower]
            for k, v in exercises.items()
        }
        # Remove empty groups
        exercises = {k: v for k, v in exercises.items() if v}

    return ExercisesResponse(
        exercises=exercises,
        location=location,
    )


@router.get("/yoga", response_model=YogaResponse)
async def get_yoga(
    goal: str | None = Query(None, description="Filter: stress_anxiety, strength_tone, flexibility_mobility, better_sleep, digestive_health"),
):
    """Yoga asanas grouped by health goal."""
    kb = KnowledgeService.instance()
    yoga = kb.get_all_yoga()

    # yoga is expected to be a dict: goal -> list of asanas
    if goal:
        yoga = {k: v for k, v in yoga.items() if k.lower() == goal.lower()}

    return YogaResponse(asanas=yoga)


@router.get("/pranayama", response_model=PranayamaResponse)
async def get_pranayama():
    """6 breathing techniques with step-by-step instructions."""
    kb = KnowledgeService.instance()
    techniques = kb.get_all_pranayama()

    return PranayamaResponse(
        techniques=techniques,
        total=len(techniques),
    )


@router.get("/sleep-protocols", response_model=SleepProtocolResponse)
async def get_sleep_protocols(
    profession: str | None = Query(None, description="Filter: it_corporate, night_shift, startup_founder"),
):
    """Sleep hygiene protocols + profession-specific schedules."""
    kb = KnowledgeService.instance()
    data = kb.get_sleep_data()

    core_rules = data.get("core_rules", {})
    profession_schedules = data.get("profession_schedules", {})
    science = data.get("science", {})

    if profession:
        profession_schedules = {
            k: v for k, v in profession_schedules.items()
            if k.lower() == profession.lower()
        }

    return SleepProtocolResponse(
        core_rules=core_rules,
        profession_schedules=profession_schedules,
        science=science,
    )


@router.get("/food-synergies")
async def get_food_synergies():
    """Food combinations with scientific rationale."""
    kb = KnowledgeService.instance()
    # get_food_synergies returns markdown; extract from nutrition DB instead
    synergies_data = kb._nutrition_db.get("section_5_food_synergies", {})
    synergies = []
    if isinstance(synergies_data, dict):
        for item in synergies_data.get("synergies", []):
            if isinstance(item, dict):
                synergies.append({
                    "combination": item.get("combination", item.get("name", "")),
                    "mechanism": item.get("mechanism", item.get("explanation", "")),
                    "research": item.get("research", item.get("reference", "")),
                })
    # Fallback if no structured data
    if not synergies:
        synergies = [
            {"combination": "Dal + Rice", "mechanism": "Complete protein (complementary amino acids)", "research": "WHO/FAO guidelines"},
            {"combination": "Turmeric + Black Pepper", "mechanism": "Piperine enhances curcumin absorption by 2000%", "research": "Shoba et al., 1998"},
            {"combination": "Iron-rich foods + Vitamin C", "mechanism": "3-6x better non-heme iron absorption", "research": "Hallberg et al., 1989"},
            {"combination": "Calcium + Vitamin D", "mechanism": "Essential for calcium absorption and bone health", "research": "Weaver, AJCN 2014"},
            {"combination": "Fat + fat-soluble vitamins (A,D,E,K)", "mechanism": "Fat required for absorption of these vitamins", "research": "Standard biochemistry"},
            {"combination": "Fermented foods (idli, dosa, curd)", "mechanism": "Improved gut health, B12 synthesis, mineral bioavailability", "research": "Multiple studies"},
        ]
    return {"synergies": synergies}


@router.get("/daily-tip", response_model=DailyTipResponse)
async def get_daily_tip():
    """Random health tip from the knowledge base."""
    kb = KnowledgeService.instance()
    return kb.get_daily_tip()


@router.get("/citations", response_model=CitationsResponse)
async def get_citations(
    topic: str | None = Query(None, description="Filter by topic: vitamin_d, ashwagandha, sleep, etc."),
):
    """Research citations with PubMed references."""
    kb = KnowledgeService.instance()
    citations = kb.get_all_citations()

    if topic:
        topic_lower = topic.lower()
        citations = [
            c for c in citations
            if topic_lower in (c.get("topic") or "").lower()
        ]

    return CitationsResponse(
        citations=citations,
        total=len(citations),
    )
