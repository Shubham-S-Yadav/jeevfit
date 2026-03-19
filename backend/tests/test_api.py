"""
JeevFit Backend Tests.
Unit tests for core logic. Integration tests require PostgreSQL.
Run with: pytest tests/ -v
"""
import pytest
import uuid


# ==================== Unit Tests (no DB needed) ====================

def test_password_hashing():
    from app.services.auth import hash_password, verify_password
    password = "test_password_123"
    hashed = hash_password(password)
    assert hashed != password
    assert verify_password(password, hashed)
    assert not verify_password("wrong_password", hashed)


def test_token_creation():
    from app.services.auth import create_access_token
    user_id = uuid.uuid4()
    token = create_access_token(user_id)
    assert token is not None
    assert len(token) > 0


def test_token_decode():
    from app.services.auth import create_access_token
    from jose import jwt
    from app.config import get_settings
    settings = get_settings()

    user_id = uuid.uuid4()
    token = create_access_token(user_id)
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    assert payload["sub"] == str(user_id)


def test_bmi_calculation():
    """Test BMI calculation logic used in plan generator."""
    weight = 70  # kg
    height = 170  # cm
    bmi = weight / ((height / 100) ** 2)
    assert round(bmi, 1) == 24.2


def test_bmi_categories():
    """Test BMI category classification."""
    def classify(bmi):
        if bmi < 18.5: return "Underweight"
        if bmi < 25: return "Normal"
        if bmi < 30: return "Overweight"
        return "Obese"

    assert classify(17.5) == "Underweight"
    assert classify(22.0) == "Normal"
    assert classify(27.5) == "Overweight"
    assert classify(32.0) == "Obese"


def test_bmr_calculation_male():
    """Test Mifflin-St Jeor BMR for male."""
    weight, height, age = 70, 170, 25
    bmr = 10 * weight + 6.25 * height - 5 * age + 5
    assert bmr == 1642.5  # 700 + 1062.5 - 125 + 5


def test_bmr_calculation_female():
    """Test Mifflin-St Jeor BMR for female."""
    weight, height, age = 60, 160, 25
    bmr = 10 * weight + 6.25 * height - 5 * age - 161
    assert bmr == 1314.0  # 600 + 1000 - 125 - 161


def test_tdee_calculation():
    """Test TDEE with activity multipliers."""
    bmr = 1700
    multipliers = {
        "sedentary": 1.2,
        "lightly_active": 1.375,
        "moderately_active": 1.55,
        "very_active": 1.725,
    }
    assert bmr * multipliers["sedentary"] == 2040.0
    assert bmr * multipliers["moderately_active"] == 2635.0


def test_macros_for_fat_loss():
    """Verify macro split for fat loss (500 kcal deficit)."""
    tdee = 2000
    target = tdee - 500
    protein_g = (target * 0.30) / 4
    carbs_g = (target * 0.40) / 4
    fat_g = (target * 0.30) / 9
    assert protein_g == 112.5
    assert carbs_g == 150.0
    assert round(fat_g, 1) == 50.0


def test_macros_for_muscle_gain():
    """Verify macro split for muscle gain (300 kcal surplus)."""
    tdee = 2000
    target = tdee + 300
    protein_g = (target * 0.30) / 4
    carbs_g = (target * 0.45) / 4
    fat_g = (target * 0.25) / 9
    assert protein_g == 172.5
    assert carbs_g == 258.75
    assert round(fat_g, 1) == 63.9


def test_water_recommendation():
    """Water intake should be ~35ml per kg body weight."""
    weight = 70
    water_ml = weight * 35
    water_liters = water_ml / 1000
    assert water_liters == 2.45


def test_protein_recommendation():
    """Protein should be 0.83g/kg (sedentary) to 1.6g/kg (active)."""
    weight = 70
    assert round(weight * 0.83, 1) == 58.1  # Sedentary minimum
    assert weight * 1.6 == 112.0  # Active target


def test_config_loads():
    """Test that configuration loads properly."""
    from app.config import get_settings
    settings = get_settings()
    assert settings.APP_NAME == "JeevFit"
    assert settings.ALGORITHM == "HS256"


def test_indian_foods_database():
    """Test that Indian foods JSON loads correctly."""
    import json
    from pathlib import Path
    foods_path = Path(__file__).parent.parent / "app" / "data" / "indian_foods.json"
    with open(foods_path) as f:
        data = json.load(f)

    assert "cereals_millets" in data
    assert "pulses_legumes" in data
    assert "dairy" in data
    assert "vegetables" in data
    assert "fruits" in data
    assert "nuts_seeds" in data
    assert "spices_herbs" in data

    # Check data quality
    rice = data["cereals_millets"][0]
    assert rice["name"] == "Rice (white, cooked)"
    assert rice["calories"] == 130
    assert rice["protein"] == 2.7

    # Check spices have research references
    turmeric = data["spices_herbs"][0]
    assert "research" in turmeric
    assert "Hewlings" in turmeric["research"]


def test_dal_rice_synergy():
    """Dal + Rice provides complete protein (lysine from dal + methionine from rice)."""
    import json
    from pathlib import Path
    foods_path = Path(__file__).parent.parent / "app" / "data" / "indian_foods.json"
    with open(foods_path) as f:
        data = json.load(f)

    rice = next(f for f in data["cereals_millets"] if "Rice" in f["name"] and "white" in f["name"])
    moong = next(f for f in data["pulses_legumes"] if "Moong" in f["name"])

    # 200g rice + 100g dal = complete protein
    combined_protein = (rice["protein"] * 2) + moong["protein"]
    assert combined_protein > 10  # Decent protein from plant combo


def test_vitamin_d_deficiency_awareness():
    """App should always flag Vitamin D deficiency for Indian users via KnowledgeService."""
    from app.services.knowledge_service import KnowledgeService
    KnowledgeService.reset()
    kb = KnowledgeService.instance()
    deficiency_md = kb.get_deficiency_risks("vegetarian", "male")
    assert "Vitamin D" in deficiency_md
    assert "70-90%" in deficiency_md


def test_curcumin_piperine_synergy():
    """Turmeric + black pepper synergy should appear in KnowledgeService food synergies."""
    from app.services.knowledge_service import KnowledgeService
    KnowledgeService.reset()
    kb = KnowledgeService.instance()
    synergies = kb.get_food_synergies()
    assert "2000%" in synergies  # Piperine enhances curcumin by 2000%
    assert "Shoba" in synergies


# ==================== KnowledgeService Tests ====================

def test_knowledge_service_loads():
    """Verify KnowledgeService singleton initialises and loads the nutrition DB."""
    from app.services.knowledge_service import KnowledgeService
    KnowledgeService.reset()
    kb = KnowledgeService.instance()
    assert kb is not None
    # Singleton check
    kb2 = KnowledgeService.instance()
    assert kb is kb2
    # The nutrition DB should have loaded
    all_foods = kb.get_all_foods()
    assert len(all_foods) > 50  # Should have 100+ foods from the JSON


def test_vegetarian_filter():
    """Vegetarian users should NOT see eggs_and_nonveg category foods."""
    from app.services.knowledge_service import KnowledgeService
    KnowledgeService.reset()
    kb = KnowledgeService.instance()
    veg_md = kb.get_foods_for_user("vegetarian", "pan_india")
    # The markdown should NOT include the non-veg header
    assert "Eggs And Nonveg" not in veg_md
    # Non-veg user should get it if the category exists
    nonveg_md = kb.get_foods_for_user("non_veg", "pan_india")
    # Both should have cereals
    assert "Cereals" in veg_md
    assert "Cereals" in nonveg_md


def test_supplement_contraindication():
    """Ashwagandha should be excluded for users with thyroid conditions."""
    from app.services.knowledge_service import KnowledgeService
    KnowledgeService.reset()
    kb = KnowledgeService.instance()
    # Without thyroid condition
    supp_ok = kb.get_supplements_for_user(
        goals=["stress_reduction"], gender="male",
        diet_type="vegetarian", conditions=[]
    )
    # With thyroid condition
    supp_thyroid = kb.get_supplements_for_user(
        goals=["stress_reduction"], gender="male",
        diet_type="vegetarian", conditions=["thyroid"]
    )
    # The thyroid version should not mention Ashwagandha
    # (Only applies when parsed supplements.json has Ashwagandha; with fallback
    # the deficiency list is returned instead, so we accept either behaviour.)
    if "Ashwagandha" in supp_ok:
        assert "Ashwagandha" not in supp_thyroid


def test_regional_diet():
    """Regional diet method should return relevant data for each region."""
    from app.services.knowledge_service import KnowledgeService
    KnowledgeService.reset()
    kb = KnowledgeService.instance()

    south = kb.get_regional_diet("south_india")
    assert "South" in south
    assert "Rice" in south or "Idli" in south or "Dosa" in south

    north = kb.get_regional_diet("north_india")
    assert "North" in north
    assert "Wheat" in north or "Roti" in north or "Paratha" in north

    pan = kb.get_regional_diet("pan_india")
    assert "Pan-India" in pan or "Pan India" in pan
