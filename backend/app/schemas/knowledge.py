from pydantic import BaseModel


class FoodItem(BaseModel):
    name: str
    hindi_name: str | None = None
    calories_kcal: float | None = None
    protein_g: float | None = None
    carbs_g: float | None = None
    fat_g: float | None = None
    fiber_g: float | None = None
    iron_mg: float | None = None
    calcium_mg: float | None = None
    zinc_mg: float | None = None
    key_nutrients: str | None = None
    glycemic_index: int | None = None
    category: str | None = None

    model_config = {"extra": "allow"}


class FoodsResponse(BaseModel):
    foods: list[FoodItem]
    total: int
    categories: list[str]


class SupplementBrand(BaseModel):
    name: str
    product: str
    price_inr: str


class ResearchRef(BaseModel):
    author: str | None = None
    journal: str | None = None
    year: int | None = None
    pmid: str | None = None
    finding: str | None = None


class SupplementItem(BaseModel):
    id: str
    name: str
    also_known_as: str | None = None
    tier: int | None = None
    why_needed: str | None = None
    dosage: dict | None = None
    when_to_take: str | None = None
    forms: list | None = None
    contraindications: list | None = None
    who_should_take: list | None = None
    brands_india: list | None = None
    research: list | None = None
    goals: list | None = None

    model_config = {"extra": "allow"}


class SupplementsResponse(BaseModel):
    supplements: list[SupplementItem]
    total: int


class ExerciseItem(BaseModel):
    name: str
    difficulty: str | None = None
    muscles: list[str] | None = None
    sets_reps: str | None = None
    instructions: str | None = None


class ExercisesResponse(BaseModel):
    exercises: dict  # muscle_group -> list of exercises
    location: str  # home or gym


class YogaAsana(BaseModel):
    name: str
    sanskrit: str | None = None
    hold_time: str | None = None
    benefits: str | None = None


class YogaResponse(BaseModel):
    asanas: dict  # goal -> list of asanas


class PranayamaItem(BaseModel):
    id: str
    name: str
    difficulty: str | None = None
    duration: str | None = None
    frequency: str | None = None
    steps: list[str] | None = None
    benefits: list[str] | None = None
    cautions: list[str] | None = None
    best_time: str | None = None


class PranayamaResponse(BaseModel):
    techniques: list[PranayamaItem]
    total: int


class SleepProtocolResponse(BaseModel):
    core_rules: dict
    profession_schedules: dict
    science: dict


class FoodSynergy(BaseModel):
    combination: str
    mechanism: str
    research: str | None = None


class FoodSynergiesResponse(BaseModel):
    synergies: list[FoodSynergy]


class DailyTipResponse(BaseModel):
    tip: str
    category: str = "general"
    source: str | None = None


class CitationItem(BaseModel):
    authors: str | None = None
    title: str | None = None
    journal: str | None = None
    year: int | None = None
    pmid: str | None = None
    topic: str | None = None
    key_finding: str | None = None


class CitationsResponse(BaseModel):
    citations: list[CitationItem]
    total: int
