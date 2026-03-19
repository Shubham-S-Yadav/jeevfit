import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Use your Mac's local IP for physical device, localhost for simulator/web
  static const String baseUrl = 'http://192.168.1.228:8000/api/v1';
  static final ApiService _instance = ApiService._internal();

  // Shared generation state so tab screens can show "in progress"
  static bool isGeneratingDiet = false;
  static bool isGeneratingExercise = false;
  static bool isGeneratingTimetable = false;

  factory ApiService() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 300),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _storage.delete(key: 'access_token');
        }
        return handler.next(error);
      },
    ));
  }

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      if (phone != null) 'phone': phone,
    });
    final data = response.data;
    await _storage.write(key: 'access_token', value: data['access_token']);
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data;
    await _storage.write(key: 'access_token', value: data['access_token']);
    return data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  // ==================== PROFILE ====================

  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> data) async {
    final response = await _dio.post('/profile/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/profile/');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/profile/', data: data);
    return response.data;
  }

  // ==================== ASSESSMENT ====================

  Future<Map<String, dynamic>> analyzeImage(String imagePath, String imageType) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath),
      'image_type': imageType,
    });
    final response = await _dio.post('/assessment/analyze', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> getLatestAssessment() async {
    final response = await _dio.get('/assessment/latest');
    return response.data;
  }

  // ==================== PLANS ====================

  Future<Map<String, dynamic>> generateDietPlan({String planType = 'weekly'}) async {
    final response = await _dio.post('/plans/diet/generate', data: {'plan_type': planType});
    return response.data;
  }

  Future<Map<String, dynamic>> getActiveDietPlan() async {
    final response = await _dio.get('/plans/diet/active');
    return response.data;
  }

  Future<Map<String, dynamic>> generateExercisePlan({String planType = 'weekly'}) async {
    final response = await _dio.post('/plans/exercise/generate', data: {'plan_type': planType});
    return response.data;
  }

  Future<Map<String, dynamic>> getActiveExercisePlan() async {
    final response = await _dio.get('/plans/exercise/active');
    return response.data;
  }

  Future<Map<String, dynamic>> generateTimetable() async {
    final response = await _dio.post('/plans/timetable/generate');
    return response.data;
  }

  Future<Map<String, dynamic>> getActiveTimetable() async {
    final response = await _dio.get('/plans/timetable/active');
    return response.data;
  }

  Future<Map<String, dynamic>> getMealAlternative({
    required Map<String, dynamic> mealContext,
    required List<Map<String, String>> conversation,
  }) async {
    final response = await _dio.post('/plans/diet/alternative', data: {
      'meal_context': mealContext,
      'conversation': conversation,
    });
    return response.data;
  }

  // ==================== TRACKING ====================

  Future<Map<String, dynamic>> logMeal(Map<String, dynamic> data) async {
    final response = await _dio.post('/tracking/meals', data: data);
    return response.data;
  }

  Future<List<dynamic>> getTodayMeals() async {
    final response = await _dio.get('/tracking/meals/today');
    return response.data;
  }

  Future<Map<String, dynamic>> logExercise(Map<String, dynamic> data) async {
    final response = await _dio.post('/tracking/exercises', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> logProgress(Map<String, dynamic> data) async {
    final response = await _dio.post('/tracking/progress', data: data);
    return response.data;
  }

  Future<List<dynamic>> getProgressHistory({int days = 30}) async {
    final response = await _dio.get('/tracking/progress/history', queryParameters: {'days': days});
    return response.data;
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get('/tracking/dashboard');
    return response.data;
  }

  // ==================== KNOWLEDGE BASE ====================

  Future<Map<String, dynamic>> getFoods({String? category, String? dietType, String? search}) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    if (dietType != null) params['diet_type'] = dietType;
    if (search != null) params['search'] = search;
    final response = await _dio.get('/knowledge/foods', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getSupplements({String? goal}) async {
    final params = <String, dynamic>{};
    if (goal != null) params['goal'] = goal;
    final response = await _dio.get('/knowledge/supplements', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getExercises({String location = 'home', String? muscleGroup, String? difficulty}) async {
    final params = <String, dynamic>{'location': location};
    if (muscleGroup != null) params['muscle_group'] = muscleGroup;
    if (difficulty != null) params['difficulty'] = difficulty;
    final response = await _dio.get('/knowledge/exercises', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getYoga({String? goal}) async {
    final params = <String, dynamic>{};
    if (goal != null) params['goal'] = goal;
    final response = await _dio.get('/knowledge/yoga', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getPranayama() async {
    final response = await _dio.get('/knowledge/pranayama');
    return response.data;
  }

  Future<Map<String, dynamic>> getSleepProtocols({String? profession}) async {
    final params = <String, dynamic>{};
    if (profession != null) params['profession'] = profession;
    final response = await _dio.get('/knowledge/sleep-protocols', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getDailyTip() async {
    final response = await _dio.get('/knowledge/daily-tip');
    return response.data;
  }
}
