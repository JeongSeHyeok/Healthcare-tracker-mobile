import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthcareTrackerApp());
}

class HealthcareTrackerApp extends StatelessWidget {
  const HealthcareTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthcare Tracker',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xff070b10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff45e17c),
          secondary: Color(0xff14c7d9),
          surface: Color(0xff111823),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff0d1f14),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xff111823),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xff151e29),
          labelStyle: const TextStyle(color: Color(0xffd7d9e5)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xff45e17c), width: 2),
          ),
        ),
      ),
      home: const TrackerShell(),
    );
  }
}

class Store {
  static const String key = 'healthcare-data-v2';

  static Future<Map<String, dynamic>> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(key) ?? sp.getString('healthcare-data');
    if (raw == null || raw.isEmpty) return initial();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return {
          ...initial(),
          ...decoded,
        };
      }
      return initial();
    } catch (_) {
      return initial();
    }
  }

  static Future<void> save(Map<String, dynamic> data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, jsonEncode(data));
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(key);
    await sp.remove('healthcare-data');
  }

  static Map<String, dynamic> initial() => {
        'exercises': <dynamic>[],
        'meals': <dynamic>[],
        'goals': <dynamic>[],
        'wearables': <dynamic>[],
        'notifications': <dynamic>[],
        'privacy': false,
        'openaiApiKey': '',
        'aiProvider': 'local',
        'aiApiKeys': <String, dynamic>{},
        'chatMessages': <dynamic>[],
      };
}

class ExercisePreset {
  final String name;
  final String type;
  final double met;
  final IconData icon;
  final bool usesMinutes;
  final bool usesIntensity;
  final bool usesSetsReps;
  final bool usesDistance;

  const ExercisePreset({
    required this.name,
    required this.type,
    required this.met,
    required this.icon,
    this.usesMinutes = true,
    this.usesIntensity = true,
    this.usesSetsReps = false,
    this.usesDistance = false,
  });
}

const exercisePresets = <ExercisePreset>[
  ExercisePreset(name: '러닝머신', type: '유산소', met: 8.3, icon: Icons.directions_run, usesDistance: true),
  ExercisePreset(name: '빠른 걷기', type: '유산소', met: 4.3, icon: Icons.directions_walk, usesDistance: true),
  ExercisePreset(name: '실내 자전거', type: '유산소', met: 6.8, icon: Icons.pedal_bike, usesDistance: true),
  ExercisePreset(name: '줄넘기', type: '유산소', met: 11.8, icon: Icons.sports_gymnastics),
  ExercisePreset(name: '웨이트 트레이닝', type: '근력', met: 6.0, icon: Icons.fitness_center, usesSetsReps: true),
  ExercisePreset(name: '스쿼트', type: '근력', met: 5.0, icon: Icons.accessibility_new, usesSetsReps: true),
  ExercisePreset(name: '푸시업', type: '근력', met: 4.0, icon: Icons.sports_mma, usesSetsReps: true),
  ExercisePreset(name: '요가/스트레칭', type: '회복', met: 2.5, icon: Icons.self_improvement, usesIntensity: false),
  ExercisePreset(name: '직접입력', type: '사용자 지정', met: 5.0, icon: Icons.edit, usesSetsReps: true, usesDistance: true),
];


class AiProviderInfo {
  final String id;
  final String name;
  final String model;
  final String apiKeyLabel;
  final String siteUrl;
  final String apiDescription;

  const AiProviderInfo({
    required this.id,
    required this.name,
    required this.model,
    required this.apiKeyLabel,
    required this.siteUrl,
    required this.apiDescription,
  });
}

const aiProviders = <AiProviderInfo>[
  AiProviderInfo(
    id: 'local',
    name: '로컬 추천',
    model: '내장 규칙 기반',
    apiKeyLabel: 'API 키 불필요',
    siteUrl: 'https://www.google.com/search?q=health+fitness+nutrition',
    apiDescription: '외부 AI API 없이 앱 내부 운동/식단 기록을 바탕으로 간단한 추천을 제공합니다.',
  ),
  AiProviderInfo(
    id: 'openai',
    name: 'ChatGPT / OpenAI',
    model: 'gpt-4o-mini',
    apiKeyLabel: 'OpenAI API Key',
    siteUrl: 'https://chatgpt.com/',
    apiDescription: 'OpenAI Chat Completions API로 운동/식단 질문에 답변합니다.',
  ),
  AiProviderInfo(
    id: 'gemini',
    name: 'Gemini / Google',
    model: 'gemini-1.5-flash',
    apiKeyLabel: 'Google AI Studio API Key',
    siteUrl: 'https://gemini.google.com/',
    apiDescription: 'Google Gemini API로 운동/식단 질문에 답변합니다.',
  ),
  AiProviderInfo(
    id: 'perplexity',
    name: 'Perplexity',
    model: 'sonar',
    apiKeyLabel: 'Perplexity API Key',
    siteUrl: 'https://www.perplexity.ai/',
    apiDescription: 'Perplexity API로 검색형 답변을 받을 수 있습니다.',
  ),
  AiProviderInfo(
    id: 'claude',
    name: 'Claude / Anthropic',
    model: 'claude-3-haiku-20240307',
    apiKeyLabel: 'Anthropic API Key',
    siteUrl: 'https://claude.ai/',
    apiDescription: '모바일 앱에서 직접 Claude API 호출은 CORS/보안 정책상 제한될 수 있어 사이트 연결과 안내 중심으로 동작합니다.',
  ),
];

enum TrackerPage { home, exercise, meal, goal, wearable, chart, ai, notification, privacy }

class FeatureInfo {
  final TrackerPage page;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const FeatureInfo(this.page, this.title, this.subtitle, this.icon, this.color);
}

const features = <FeatureInfo>[
  FeatureInfo(TrackerPage.exercise, '운동 기록', '종목별 칼로리', Icons.fitness_center, Color(0xff45e17c)),
  FeatureInfo(TrackerPage.meal, '식단 관리', '영양/칼로리', Icons.restaurant, Color(0xffffbd59)),
  FeatureInfo(TrackerPage.goal, '목표 설정', '목표 달성률', Icons.flag, Color(0xff7aa7ff)),
  FeatureInfo(TrackerPage.wearable, '웨어러블', '걸음/심박 기록', Icons.watch, Color(0xff14c7d9)),
  FeatureInfo(TrackerPage.chart, '리포트', '날짜별 표/그래프', Icons.bar_chart, Color(0xffb983ff)),
  FeatureInfo(TrackerPage.ai, 'AI 챗봇', 'AI 선택/사이트 연동', Icons.smart_toy, Color(0xffff6b6b)),
  FeatureInfo(TrackerPage.notification, '알림', '저장 기록', Icons.notifications_active, Color(0xff44d7b6)),
  FeatureInfo(TrackerPage.privacy, '개인정보', '동의/삭제', Icons.verified_user, Color(0xffc3f584)),
];

class TrackerShell extends StatefulWidget {
  const TrackerShell({super.key});

  @override
  State<TrackerShell> createState() => _TrackerShellState();
}

class _TrackerShellState extends State<TrackerShell> {
  Map<String, dynamic> data = Store.initial();
  TrackerPage page = TrackerPage.home;
  bool loaded = false;
  bool chatLoading = false;
  DateTime selectedReportDate = DateTime.now();
  String selectedAiProvider = 'local';

  String selectedExercise = exercisePresets.first.name;
  final customExerciseName = TextEditingController(text: '나만의 운동');
  final exMin = TextEditingController(text: '30');
  final exWeight = TextEditingController(text: '65');
  final exIntensity = TextEditingController(text: '5');
  final exSets = TextEditingController(text: '3');
  final exReps = TextEditingController(text: '12');
  final exDistance = TextEditingController(text: '3');
  final mealName = TextEditingController(text: '닭가슴살 샐러드');
  final mealKcal = TextEditingController(text: '350');
  final goalName = TextEditingController(text: '걸음 수');
  final goalTarget = TextEditingController(text: '10000');
  final goalNow = TextEditingController(text: '3000');
  final steps = TextEditingController(text: '4500');
  final bpm = TextEditingController(text: '92');
  final apiKeyController = TextEditingController();
  final chatController = TextEditingController();

  ExercisePreset get selectedPreset => exercisePresets.firstWhere(
        (e) => e.name == selectedExercise,
        orElse: () => exercisePresets.first,
      );

  @override
  void initState() {
    super.initState();
    Store.load().then((v) {
      if (!mounted) return;
      setState(() {
        data = v;
        selectedAiProvider = '${data['aiProvider'] ?? 'local'}';
        apiKeyController.text = _currentAiKey();
        loaded = true;
      });
    });
  }

  @override
  void dispose() {
    customExerciseName.dispose();
    exMin.dispose();
    exWeight.dispose();
    exIntensity.dispose();
    exSets.dispose();
    exReps.dispose();
    exDistance.dispose();
    mealName.dispose();
    mealKcal.dispose();
    goalName.dispose();
    goalTarget.dispose();
    goalNow.dispose();
    steps.dispose();
    bpm.dispose();
    apiKeyController.dispose();
    chatController.dispose();
    super.dispose();
  }

  String now() => DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  String dateKey([DateTime? value]) => DateFormat('yyyy-MM-dd').format(value ?? DateTime.now());

  List<dynamic> items(String key) => List<dynamic>.from(data[key] as List? ?? <dynamic>[]);

  Future<void> persist() => Store.save(data);

  void toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  Future<bool> _handleBack() async {
    if (page != TrackerPage.home) {
      setState(() => page = TrackerPage.home);
      return false;
    }
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('Healthcare Tracker를 종료하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('종료')),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  void addNotification(String text) {
    final list = items('notifications');
    list.insert(0, {'text': text, 'date': now()});
    data['notifications'] = list;
  }

  int sum(String key, String field, {String? date}) {
    return items(key).fold<int>(0, (total, e) {
      if (e is Map && e[field] is num) {
        if (date != null && !('${e['date'] ?? ''}'.startsWith(date))) return total;
        return total + (e[field] as num).toInt();
      }
      return total;
    });
  }

  int get latestSteps {
    final list = items('wearables');
    if (list.isEmpty || list.first is! Map || (list.first as Map)['steps'] is! num) return 0;
    return ((list.first as Map)['steps'] as num).toInt();
  }

  int get latestBpm {
    final list = items('wearables');
    if (list.isEmpty || list.first is! Map || (list.first as Map)['bpm'] is! num) return 0;
    return ((list.first as Map)['bpm'] as num).toInt();
  }

  int get totalSteps => sum('wearables', 'steps');
  int get totalExerciseKcal => sum('exercises', 'kcal');

  AiProviderInfo get currentAiProvider => aiProviders.firstWhere(
        (p) => p.id == selectedAiProvider,
        orElse: () => aiProviders.first,
      );

  String _currentAiKey() {
    final keys = data['aiApiKeys'];
    if (keys is Map && keys[selectedAiProvider] != null) return '${keys[selectedAiProvider]}';
    if (selectedAiProvider == 'openai') return '${data['openaiApiKey'] ?? ''}';
    return '';
  }

  void changeAiProvider(String? value) {
    if (value == null) return;
    setState(() {
      selectedAiProvider = value;
      data['aiProvider'] = value;
      apiKeyController.text = _currentAiKey();
    });
    persist();
  }

  Future<void> openAiProviderSite() async {
    final uri = Uri.parse(currentAiProvider.siteUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) toast('사이트를 열 수 없습니다.');
  }

  int calculateExerciseCalories() {
    final preset = selectedPreset;
    final minutes = double.tryParse(exMin.text) ?? 0;
    final weight = double.tryParse(exWeight.text) ?? 0;
    final intensity = double.tryParse(exIntensity.text) ?? 5;
    final sets = double.tryParse(exSets.text) ?? 0;
    final reps = double.tryParse(exReps.text) ?? 0;
    final distance = double.tryParse(exDistance.text) ?? 0;
    final intensityFactor = preset.usesIntensity ? (0.75 + (intensity.clamp(1, 10) * 0.05)) : 1.0;
    final base = preset.met * 3.5 * weight / 200 * minutes * intensityFactor;
    final strengthBonus = preset.usesSetsReps ? sets * reps * 0.18 * intensityFactor : 0;
    final distanceBonus = preset.usesDistance ? distance * weight * 0.08 : 0;
    return (base + strengthBonus + distanceBonus).round();
  }

  Future<void> saveExercise() async {
    final kcal = calculateExerciseCalories();
    final preset = selectedPreset;
    final name = selectedExercise == '직접입력' ? customExerciseName.text.trim() : selectedExercise;
    final list = items('exercises');
    list.insert(0, {
      'name': name.isEmpty ? '운동' : name,
      'type': preset.type,
      'minutes': int.tryParse(exMin.text) ?? 0,
      'weight': int.tryParse(exWeight.text) ?? 0,
      'intensity': int.tryParse(exIntensity.text) ?? 0,
      'sets': int.tryParse(exSets.text) ?? 0,
      'reps': int.tryParse(exReps.text) ?? 0,
      'distance': double.tryParse(exDistance.text) ?? 0,
      'met': preset.met,
      'kcal': kcal,
      'date': now(),
    });
    setState(() {
      data['exercises'] = list;
      addNotification('운동 저장 완료: ${name.isEmpty ? selectedExercise : name} $kcal kcal');
      selectedReportDate = DateTime.now();
    });
    await persist();
    toast('운동 데이터가 저장되었습니다.');
  }

  Future<void> saveMeal() async {
    final list = items('meals');
    list.insert(0, {
      'name': mealName.text.trim().isEmpty ? '식단' : mealName.text.trim(),
      'kcal': int.tryParse(mealKcal.text) ?? 0,
      'date': now(),
    });
    setState(() {
      data['meals'] = list;
      addNotification('식단 저장 완료: ${mealName.text} ${mealKcal.text} kcal');
      selectedReportDate = DateTime.now();
    });
    await persist();
    toast('식단 데이터가 저장되었습니다.');
  }

  Future<void> saveGoal() async {
    final list = items('goals');
    list.insert(0, {
      'name': goalName.text.trim().isEmpty ? '목표' : goalName.text.trim(),
      'target': int.tryParse(goalTarget.text) ?? 0,
      'current': int.tryParse(goalNow.text) ?? 0,
      'date': now(),
    });
    setState(() {
      data['goals'] = list;
      addNotification('목표 저장 완료: ${goalName.text}');
    });
    await persist();
    toast('목표 데이터가 저장되었습니다.');
  }

  Future<void> saveWearable() async {
    final list = items('wearables');
    list.insert(0, {
      'steps': int.tryParse(steps.text) ?? 0,
      'bpm': int.tryParse(bpm.text) ?? 0,
      'date': now(),
    });
    setState(() {
      data['wearables'] = list;
      addNotification('웨어러블 데이터 저장 완료: ${steps.text}보 / ${bpm.text}bpm');
      selectedReportDate = DateTime.now();
    });
    await persist();
    toast('웨어러블 데이터가 저장되었습니다.');
  }

  Future<void> clearAll() async {
    setState(() => data = Store.initial());
    await Store.clear();
    toast('전체 데이터가 삭제되었습니다.');
  }

  Future<void> savePrivacy(bool value) async {
    setState(() => data['privacy'] = value);
    await persist();
    toast(value ? '개인정보 동의가 저장되었습니다.' : '개인정보 동의가 철회되었습니다.');
  }

  Future<void> saveApiKey() async {
    final keys = Map<String, dynamic>.from(data['aiApiKeys'] as Map? ?? <String, dynamic>{});
    keys[selectedAiProvider] = apiKeyController.text.trim();
    setState(() {
      data['aiProvider'] = selectedAiProvider;
      data['aiApiKeys'] = keys;
      if (selectedAiProvider == 'openai') data['openaiApiKey'] = apiKeyController.text.trim();
    });
    await persist();
    toast('${currentAiProvider.name} API 키가 앱 내부 저장소에 저장되었습니다.');
  }

  Future<void> sendChatMessage() async {
    final text = chatController.text.trim();
    if (text.isEmpty) return;
    final messages = items('chatMessages');
    setState(() {
      messages.add({'role': 'user', 'text': text, 'date': now()});
      data['chatMessages'] = messages;
      chatController.clear();
      chatLoading = true;
    });
    await persist();

    final provider = currentAiProvider;
    final apiKey = _currentAiKey().trim();
    String answer;
    if (provider.id == 'local' || apiKey.isEmpty) {
      answer = _localAiAnswer(text);
      if (provider.id != 'local' && apiKey.isEmpty) {
        answer = '${provider.name} API 키가 없어 로컬 추천으로 답변합니다.\n\n$answer';
      }
    } else {
      answer = await _callSelectedAi(provider, text, messages, apiKey);
    }

    final updated = items('chatMessages');
    updated.add({'role': 'assistant', 'text': answer, 'date': now()});
    setState(() {
      data['chatMessages'] = updated;
      chatLoading = false;
    });
    await persist();
  }

  String _localAiAnswer(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('식단') || lower.contains('단백질')) {
      return 'API 키가 없어서 로컬 추천으로 답변합니다. 운동 후에는 닭가슴살, 달걀, 두부 같은 단백질 식단과 충분한 수분 섭취를 추천합니다.';
    }
    if (lower.contains('걷') || lower.contains('걸음')) {
      return '현재 누적 걸음 수는 $totalSteps보입니다. 목표가 10,000보라면 부족한 만큼 20~30분 산책을 추가해 보세요.';
    }
    if (lower.contains('운동') || lower.contains('칼로리')) {
      return '현재 누적 운동 칼로리는 $totalExerciseKcal kcal입니다. 무리하지 말고 유산소와 근력운동을 번갈아 진행하는 것을 추천합니다.';
    }
    return 'API 키가 없어서 로컬 추천으로 답변합니다. 운동 기록, 식단, 걸음 수를 저장하면 리포트 화면에서 날짜별로 확인할 수 있습니다.';
  }

  Future<String> _callSelectedAi(AiProviderInfo provider, String input, List<dynamic> messages, String apiKey) async {
    switch (provider.id) {
      case 'openai':
        return _callOpenAi(input, messages, apiKey);
      case 'gemini':
        return _callGemini(input, apiKey);
      case 'perplexity':
        return _callPerplexity(input, messages, apiKey);
      case 'claude':
        return 'Claude는 현재 앱 내부 직접 API 호출 대신 사이트 연결 방식으로 준비했습니다. AI 챗봇 화면의 "선택 AI 사이트 열기" 버튼으로 Claude를 열어 질문을 이어가세요.\n\n로컬 조언: ${_localAiAnswer(input)}';
      default:
        return _localAiAnswer(input);
    }
  }

  List<Map<String, String>> _recentOpenAiMessages(List<dynamic> messages) => messages.take(8).map((m) {
        final role = m is Map && m['role'] == 'assistant' ? 'assistant' : 'user';
        final content = m is Map ? '${m['text'] ?? ''}' : '$m';
        return {'role': role, 'content': content};
      }).toList();

  String get _systemPrompt => '너는 헬스케어 트래커 앱의 운동/식단 조언 챗봇이다. 의학적 진단은 하지 말고 일반적인 운동, 식단, 기록 관리 조언만 한국어로 간단히 답한다. 현재 누적 운동 칼로리: $totalExerciseKcal kcal, 누적 걸음 수: $totalSteps.';

  Future<String> _callOpenAi(String input, List<dynamic> messages, String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ..._recentOpenAiMessages(messages),
            {'role': 'user', 'content': input},
          ],
          'temperature': 0.7,
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'OpenAI API 호출 실패: ${response.statusCode}. API 키와 네트워크 연결을 확인하세요.';
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'];
      if (choices is List && choices.isNotEmpty) {
        final msg = choices.first['message'];
        if (msg is Map && msg['content'] != null) return '${msg['content']}';
      }
      return 'OpenAI 응답을 해석하지 못했습니다.';
    } catch (e) {
      return 'OpenAI 연결 오류: $e';
    }
  }

  Future<String> _callGemini(String input, String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': '$_systemPrompt\n\n사용자 질문: $input'}
              ]
            }
          ],
          'generationConfig': {'temperature': 0.7}
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Gemini API 호출 실패: ${response.statusCode}. API 키와 네트워크 연결을 확인하세요.';
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final content = candidates.first['content'];
        final parts = content is Map ? content['parts'] : null;
        if (parts is List && parts.isNotEmpty && parts.first is Map && parts.first['text'] != null) {
          return '${parts.first['text']}';
        }
      }
      return 'Gemini 응답을 해석하지 못했습니다.';
    } catch (e) {
      return 'Gemini 연결 오류: $e';
    }
  }

  Future<String> _callPerplexity(String input, List<dynamic> messages, String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.perplexity.ai/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'model': 'sonar',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ..._recentOpenAiMessages(messages),
            {'role': 'user', 'content': input},
          ],
          'temperature': 0.7,
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Perplexity API 호출 실패: ${response.statusCode}. API 키와 네트워크 연결을 확인하세요.';
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'];
      if (choices is List && choices.isNotEmpty) {
        final msg = choices.first['message'];
        if (msg is Map && msg['content'] != null) return '${msg['content']}';
      }
      return 'Perplexity 응답을 해석하지 못했습니다.';
    } catch (e) {
      return 'Perplexity 연결 오류: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = page == TrackerPage.home ? 'Healthcare Tracker' : features.firstWhere((f) => f.page == page).title;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canExit = await _handleBack();
        if (canExit && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: page == TrackerPage.home ? null : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => page = TrackerPage.home)),
          actions: [
            if (page != TrackerPage.home)
              IconButton(
                tooltip: '홈으로',
                onPressed: () => setState(() => page = TrackerPage.home),
                icon: const Icon(Icons.home),
              ),
          ],
        ),
        body: SafeArea(child: loaded ? _buildPage() : const Center(child: CircularProgressIndicator())),
      ),
    );
  }

  Widget _buildPage() {
    switch (page) {
      case TrackerPage.home:
        return _home();
      case TrackerPage.exercise:
        return _exercisePage();
      case TrackerPage.meal:
        return _mealPage();
      case TrackerPage.goal:
        return _goalPage();
      case TrackerPage.wearable:
        return _wearablePage();
      case TrackerPage.chart:
        return _chartPage();
      case TrackerPage.ai:
        return _aiPage();
      case TrackerPage.notification:
        return _notificationPage();
      case TrackerPage.privacy:
        return _privacyPage();
    }
  }

  Widget _home() => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _hero(),
          const SizedBox(height: 16),
          _summary(),
          const SizedBox(height: 14),
          _combinedTotalCard(),
          const SizedBox(height: 22),
          const Text('기능 선택', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.95, mainAxisSpacing: 14, crossAxisSpacing: 14),
            itemBuilder: (context, index) => _featureButton(features[index]),
          ),
        ],
      );

  Widget _featureButton(FeatureInfo f) => InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => setState(() => page = f.page),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xff141d29), f.color.withOpacity(0.23)]),
            border: Border.all(color: f.color.withOpacity(0.45)),
            boxShadow: [BoxShadow(color: f.color.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 66, height: 66, decoration: BoxDecoration(color: f.color, borderRadius: BorderRadius.circular(22)), child: Icon(f.icon, color: Colors.black, size: 34)),
                const SizedBox(height: 12),
                Text(f.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(f.subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xffb8bdc9))),
              ],
            ),
          ),
        ),
      );

  Widget _hero() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [Color(0xff13202e), Color(0xff101822)])),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('AI · WEARABLE · NUTRITION', style: TextStyle(color: Color(0xff45e17c), fontWeight: FontWeight.w900)),
                  SizedBox(height: 10),
                  Text('기능별 메뉴로\n건강 데이터를 관리', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2)),
                  SizedBox(height: 8),
                  Text('로그인 없이 운동, 식단, 목표, 웨어러블 기록을 바로 저장합니다.'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/images/health.jpeg', width: 130, height: 125, fit: BoxFit.cover)),
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)), child: Text('걸음 수\n$latestSteps', style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ],
        ),
      );

  Widget _summary() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.65,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _stat('오늘 운동', '${sum('exercises', 'kcal', date: dateKey())} kcal', Icons.local_fire_department),
          _stat('섭취 칼로리', '${sum('meals', 'kcal', date: dateKey())} kcal', Icons.restaurant),
          _stat('오늘 걸음 수', '${sum('wearables', 'steps', date: dateKey())}', Icons.directions_walk),
          _stat('최근 심박수', '$latestBpm bpm', Icons.favorite),
        ],
      );

  Widget _combinedTotalCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.insights, color: Color(0xff45e17c), size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('누적 활동 합산', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  Text('운동 칼로리 $totalExerciseKcal kcal · 웨어러블 걸음 수 $totalSteps보'),
                ]),
              ),
            ],
          ),
        ),
      );

  Widget _stat(String title, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [Icon(icon, color: const Color(0xff45e17c)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))]))]),
        ),
      );

  Widget _exercisePage() {
    final preset = selectedPreset;
    return _pageList([
      _section('운동 기록 + 칼로리 계산', 'Exercise Service', [
        DropdownButtonFormField<String>(
          value: selectedExercise,
          decoration: const InputDecoration(labelText: '운동 종목'),
          items: exercisePresets.map((e) => DropdownMenuItem(value: e.name, child: Text('${e.name} · ${e.type}'))).toList(),
          onChanged: (value) => setState(() => selectedExercise = value ?? exercisePresets.first.name),
        ),
        if (selectedExercise == '직접입력') _field(customExerciseName, '직접 입력 운동명'),
        _row([_field(exWeight, '몸무게 kg'), _field(exMin, '시간 분', number: true)]),
        if (preset.usesIntensity) _field(exIntensity, '강도 1~10', number: true),
        if (preset.usesSetsReps) _row([_field(exSets, '세트', number: true), _field(exReps, '횟수', number: true)]),
        if (preset.usesDistance) _field(exDistance, '거리 km', number: true),
        _previewCard('예상 칼로리', '${calculateExerciseCalories()} kcal', preset.icon),
        _btn('운동 저장', saveExercise),
        _list('exercises', (e) => '${e['name']} · ${e['type']} · ${e['minutes']}분 · ${e['kcal']} kcal · ${e['date']}'),
      ]),
    ]);
  }

  Widget _mealPage() => _pageList([
        _section('식단/영양 관리', 'Nutrition Service', [
          _row([_field(mealName, '식단명'), _field(mealKcal, 'kcal', number: true)]),
          _btn('식단 저장', saveMeal),
          _list('meals', (e) => '${e['name']} · ${e['kcal']} kcal · ${e['date']}'),
        ]),
      ]);

  Widget _goalPage() => _pageList([
        _section('목표 설정', 'Goal Service', [
          _row([_field(goalName, '목표명'), _field(goalTarget, '목표값', number: true)]),
          _field(goalNow, '현재값', number: true),
          _btn('목표 저장', saveGoal),
          _list('goals', (e) => '${e['name']} · ${e['current']} / ${e['target']} · ${e['date']}'),
        ]),
      ]);

  Widget _wearablePage() => _pageList([
        _section('웨어러블/API 시뮬레이션', 'Wearable API Adapter', [
          _row([_field(steps, '걸음 수', number: true), _field(bpm, '심박수', number: true)]),
          _btn('시뮬레이션 저장', saveWearable),
          _previewCard('누적 웨어러블 걸음 수', '$totalSteps 보', Icons.directions_walk),
          _list('wearables', (e) => '${e['steps']}보 · ${e['bpm']} bpm · ${e['date']}'),
        ]),
      ]);

  Widget _chartPage() => _pageList([
        _section('날짜별 데이터 리포트', 'Report Service', [
          _dateSelector(),
          _chart(),
          _reportTable(),
        ]),
      ]);

  Widget _dateSelector() => Row(
        children: [
          Expanded(child: Text('조회 날짜: ${dateKey(selectedReportDate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          FilledButton.tonal(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedReportDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => selectedReportDate = picked);
            },
            child: const Text('날짜 선택'),
          ),
        ],
      );

  Widget _reportTable() {
    final d = dateKey(selectedReportDate);
    final rows = <DataRow>[
      DataRow(cells: [const DataCell(Text('운동 칼로리')), DataCell(Text('${sum('exercises', 'kcal', date: d)} kcal'))]),
      DataRow(cells: [const DataCell(Text('식단 칼로리')), DataCell(Text('${sum('meals', 'kcal', date: d)} kcal'))]),
      DataRow(cells: [const DataCell(Text('걸음 수')), DataCell(Text('${sum('wearables', 'steps', date: d)} 보'))]),
      DataRow(cells: [const DataCell(Text('기록 수')), DataCell(Text('${itemsByDate('exercises', d).length + itemsByDate('meals', d).length + itemsByDate('wearables', d).length} 건'))]),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: const [DataColumn(label: Text('항목')), DataColumn(label: Text('값'))], rows: rows),
    );
  }

  List<dynamic> itemsByDate(String key, String d) => items(key).where((e) => e is Map && '${e['date'] ?? ''}'.startsWith(d)).toList();

  Widget _aiPage() => _pageList([
        _section('AI 챗봇', 'AI Provider', [
          const Text('사용할 AI를 선택하고, 해당 서비스의 API 키를 저장한 뒤 질문할 수 있습니다. API 키가 없으면 로컬 추천으로 답변합니다.'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedAiProvider,
            decoration: const InputDecoration(labelText: '사용할 AI 선택'),
            items: aiProviders.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} · ${p.model}'))).toList(),
            onChanged: changeAiProvider,
          ),
          const SizedBox(height: 10),
          _pill(currentAiProvider.apiDescription, Icons.info_outline),
          const SizedBox(height: 8),
          TextField(
            controller: apiKeyController,
            obscureText: true,
            decoration: InputDecoration(labelText: currentAiProvider.apiKeyLabel),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(onPressed: saveApiKey, child: const Text('API 키 저장')),
              OutlinedButton.icon(onPressed: openAiProviderSite, icon: const Icon(Icons.open_in_new), label: const Text('선택 AI 사이트 열기')),
            ],
          ),
          const SizedBox(height: 12),
          ...items('chatMessages').map((m) => _chatBubble(m is Map ? '${m['text'] ?? ''}' : '$m', m is Map && m['role'] == 'user')),
          if (chatLoading) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
          Row(children: [
            Expanded(child: TextField(controller: chatController, decoration: InputDecoration(labelText: '${currentAiProvider.name}에게 운동/식단 질문'))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: sendChatMessage, icon: const Icon(Icons.send)),
          ]),
        ]),
      ]);

  Widget _chatBubble(String text, bool isUser) => Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(color: isUser ? const Color(0xff45e17c) : const Color(0xff202733), borderRadius: BorderRadius.circular(16)),
          child: Text(text, style: TextStyle(color: isUser ? Colors.black : Colors.white)),
        ),
      );

  Widget _notificationPage() => _pageList([
        _section('알림', 'Notification Service', items('notifications').isEmpty ? [const Text('저장된 알림이 없습니다.')] : items('notifications').map((e) => _pill('${e['text']}\n${e['date']}', Icons.notifications)).toList()),
      ]);

  Widget _privacyPage() => _pageList([
        _section('개인정보 활용 동의', 'Privacy', [
          Text('현재 동의 상태: ${data['privacy'] == true ? '동의' : '미동의'}'),
          const SizedBox(height: 10),
          const Text('운동, 식단, 웨어러블 데이터는 사용자의 브라우저/앱 내부 저장소에 저장되며 리포트와 AI 추천 기능에 활용됩니다.'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: _showPrivacyDetail, child: const Text('세부내용 확인')),
            FilledButton(onPressed: () => savePrivacy(true), child: const Text('동의')),
            OutlinedButton(onPressed: () => savePrivacy(false), child: const Text('철회')),
            FilledButton.tonal(onPressed: () => toast(jsonEncode(data)), child: const Text('데이터 확인')),
            FilledButton(onPressed: clearAll, style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('데이터 삭제')),
          ]),
        ]),
      ]);

  void _showPrivacyDetail() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개인정보 활용 동의 세부내용'),
        content: const SingleChildScrollView(
          child: Text('1. 수집 항목: 운동명, 운동 시간, 강도, 세트/횟수, 칼로리, 식단명, 섭취 칼로리, 걸음 수, 심박수, 목표값.\n\n2. 활용 목적: 개인 운동/식단 기록 조회, 날짜별 그래프와 표 생성, AI 추천 및 챗봇 답변 보조.\n\n3. 저장 위치: 현재 앱 내부 저장소 SharedPreferences. 별도 백엔드 서버로 전송하지 않습니다. 단, OpenAI/Gemini/Perplexity 등 외부 AI API 키를 입력하고 챗봇을 사용할 경우 질문 내용과 요약 데이터가 선택한 AI 서비스 API 요청에 포함될 수 있습니다.\n\n4. 삭제 방법: 개인정보 화면의 데이터 삭제 버튼으로 전체 기록을 삭제할 수 있습니다.'),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
  }

  Widget _pageList(List<Widget> children) => ListView(padding: const EdgeInsets.all(18), children: children);

  Widget _section(String title, String tag, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), Chip(label: Text(tag, style: const TextStyle(fontSize: 11)))],), const SizedBox(height: 14), ...children]),
        ),
      );

  Widget _row(List<Widget> children) => Row(children: children.map((w) => Expanded(child: Padding(padding: const EdgeInsets.all(4), child: w))).toList());

  Widget _field(TextEditingController c, String label, {bool number = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(controller: c, keyboardType: number ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: label)),
      );

  Widget _btn(String text, Future<void> Function() action) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: () async {
              try {
                await action();
              } catch (e) {
                toast('저장 오류: $e');
                debugPrint('저장 오류: $e');
              }
            },
            child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      );

  Widget _previewCard(String title, String value, IconData icon) => Card(
        child: ListTile(leading: Icon(icon, color: const Color(0xff45e17c)), title: Text(title), trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      );

  Widget _pill(String text, IconData icon) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xff202733), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [Icon(icon, color: const Color(0xff45e17c)), const SizedBox(width: 10), Expanded(child: Text(text))]),
      );

  Widget _list(String key, String Function(dynamic) text) {
    final list = items(key);
    if (list.isEmpty) return Padding(padding: const EdgeInsets.only(top: 10), child: Text('저장된 $key 데이터가 없습니다.'));
    return Column(children: list.map((e) => _pill(text(e), Icons.check_circle)).toList());
  }

  Widget _chart() {
    final days = List<DateTime>.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    final values = days.map((d) {
      final k = dateKey(d);
      return sum('exercises', 'kcal', date: k) + (sum('wearables', 'steps', date: k) ~/ 10);
    }).toList();
    final maxValue = values.isEmpty ? 100 : values.reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = maxValue < 100 ? 100.0 : maxValue + 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('최근 7일 활동 그래프 = 운동 kcal + 걸음 수/10', style: TextStyle(color: Color(0xffb8bdc9))),
        const SizedBox(height: 12),
        SizedBox(
          height: 270,
          child: BarChart(
            BarChartData(
              maxY: maxY.toDouble(),
              minY: 0,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= days.length) return const SizedBox.shrink();
                      return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('M/d').format(days[index])));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: (maxY / 5).ceilToDouble(),
                    getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 11)),
                  ),
                ),
              ),
              barGroups: values.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.toDouble(), width: 22, borderRadius: BorderRadius.circular(6))])).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
