class AppConstants {
  static const String appName = 'JeevFit';
  static const String appVersion = '1.0.0';

  // API
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';

  // Limits
  static const int maxImageSizeMB = 10;
  static const int maxMealsPerDay = 7;

  // Health categories
  static const Map<String, String> healthGoals = {
    'fat_loss': 'Fat Loss',
    'muscle_gain': 'Muscle Gain',
    'maintenance': 'Maintenance',
    'general_health': 'General Health',
    'stress_reduction': 'Stress Reduction',
    'better_sleep': 'Better Sleep',
    'skin_hair': 'Skin & Hair',
  };

  static const Map<String, String> activityLevels = {
    'sedentary': 'Sedentary (Desk Job)',
    'lightly_active': 'Lightly Active (1-3 days/week)',
    'moderately_active': 'Moderately Active (3-5 days/week)',
    'very_active': 'Very Active (6-7 days/week)',
    'extremely_active': 'Extremely Active (Physical Job + Exercise)',
  };

  static const Map<String, String> dietaryPreferences = {
    'vegetarian': 'Vegetarian',
    'non_vegetarian': 'Non-Vegetarian',
    'eggetarian': 'Eggetarian',
    'vegan': 'Vegan',
    'jain': 'Jain',
  };

  static const Map<String, String> regions = {
    'north_india': 'North India',
    'south_india': 'South India',
    'east_india': 'East India',
    'west_india': 'West India',
    'northeast_india': 'Northeast India',
    'pan_india': 'Pan India',
  };
}
