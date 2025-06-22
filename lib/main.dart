import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'reminder_service.dart';
import 'reminder_setting_page.dart';
import 'community_memo_page.dart';

/// 앱에서 지원하는 언어 코드와 표시 이름을 담은 Map
final Map<String, String> supportedLanguages = {
  'ko': '한국어',
  'en': 'English',
  'ja': '日本語',
  'zh': '中文',
  'es': 'Español',
};

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    logger.i('ENV loaded successfully');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    logger.i('Supabase initialized successfully');

    // ReminderService 초기화
    await ReminderService.instance.init();
    logger.i('ReminderService initialized successfully');
  } catch (e) {
    logger.e('초기화 중 오류 발생: $e');
  }
  runApp(const LuckyTenCommandmentsApp());
}

class LuckyTenCommandmentsApp extends StatelessWidget {
  const LuckyTenCommandmentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '행운의 십계명 카드',
      theme: ThemeData(primarySwatch: Colors.deepPurple, fontFamily: 'Roboto'),
      home: const CommandmentCardPage(),
    );
  }
}

class CommandmentCardPage extends StatefulWidget {
  const CommandmentCardPage({super.key});

  @override
  State<CommandmentCardPage> createState() => _CommandmentCardPageState();
}

class _CommandmentCardPageState extends State<CommandmentCardPage> {
  List<CardModel> _cards = [];
  int _currentCardIndex = 0;
  TextEditingController memoController = TextEditingController();
  List<Map<String, dynamic>> memos = [];
  bool isLoading = true;
  String? errorMessage;

  /// 사용자가 선택한 언어 코드 (기본값: 'ko')
  String selectedLang = 'ko';

  Map<String, dynamic>? uiLabels;
  String detectedLang = 'ko';
  bool labelsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLabelsAndDetectLocale();
    fetchCardsFromSupabase();
    loadMemos();
  }

  Future<void> _loadLabelsAndDetectLocale() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/lucky_ten_ui_labels.json',
      );
      final Map<String, dynamic> labels = json.decode(jsonString);

      // 비동기 작업에서 BuildContext 사용을 피하기 위해
      // 컨텍스트가 여전히 유효한지 확인
      if (!mounted) return;

      // Locale 감지 (플랫폼 Locale, selectedLang, fallback)
      String lang = View.of(context).platformDispatcher.locale.languageCode;
      if (!labels.containsKey(lang)) {
        lang = 'ko';
      }

      setState(() {
        uiLabels = labels;
        detectedLang = lang;
        labelsLoaded = true;
        selectedLang = lang; // 앱 내 언어 선택도 동기화
      });
    } catch (e) {
      logger.e('Error loading labels: $e');
      if (mounted) {
        setState(() {
          labelsLoaded = true; // 에러가 있어도 로딩 완료 표시
          detectedLang = 'ko';
          selectedLang = 'ko';
        });
      }
    }
  }

  // 언어 변경 메서드는 나중에 사용할 예정이므로 주석 처리합니다
  /*
  void _changeLanguage(String lang) {
    setState(() {
      detectedLang = lang;
      selectedLang = lang;
    });
    fetchCardsFromSupabase();
  }
  */

  Future<void> fetchCardsFromSupabase() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final selectFields = [
        'id',
        'title_$selectedLang',
        'story_$selectedLang',
        'q1_$selectedLang',
        'q2_$selectedLang',
        'title_ko',
        'story_ko',
        'q1_ko',
        'q2_ko',
        'title_en',
        'story_en',
        'q1_en',
        'q2_en',
        'title_ja',
        'story_ja',
        'q1_ja',
        'q2_ja',
        'title_zh',
        'story_zh',
        'q1_zh',
        'q2_zh',
        'title_es',
        'story_es',
        'q1_es',
        'q2_es',
      ].join(', ');

      final response = await Supabase.instance.client
          .from('multilang_cards')
          .select(selectFields)
          .order('id')
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('서버 연결 시간이 초과되었습니다.');
            },
          );

      logger.i('Fetched ${response.length} cards from Supabase');
      final fetchedCards = List<Map<String, dynamic>>.from(response);
      final cardModels =
          fetchedCards.map((json) => CardModel.fromJson(json)).toList();

      if (cardModels.isNotEmpty) {
        final random = Random();
        final randomIndex = random.nextInt(cardModels.length);
        setState(() {
          _cards = cardModels;
          _currentCardIndex = randomIndex;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = '카드를 불러올 수 없습니다.\n잠시 후 다시 시도해주세요.';
          isLoading = false;
        });
        logger.w('No cards found in the response');
      }
    } catch (e) {
      setState(() {
        if (e is TimeoutException) {
          errorMessage = '서버 연결 시간이 초과되었습니다.\n네트워크 연결을 확인하고 다시 시도해주세요.';
        } else if (e.toString().contains('connection')) {
          errorMessage = '네트워크 연결을 확인해주세요.\n인터넷이 연결되어 있는지 확인 후 다시 시도해주세요.';
        } else {
          errorMessage = '오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
        }
        isLoading = false;
      });
      logger.e('Error fetching cards: $e');
    }
  }

  Future<void> saveMemo() async {
    final prefs = await SharedPreferences.getInstance();
    final memo = memoController.text.trim();
    if (memo.isNotEmpty && _cards.isNotEmpty) {
      final card = _cards[_currentCardIndex];
      final now = DateTime.now(); // ✅ 추가
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final newMemo = {
        'id': card.id,
        'title': card.getTitle(selectedLang),
        'memo': memo,
        'date': formattedDate,
      };
      memos.add(newMemo);
      await prefs.setString('memos', jsonEncode(memos));
      memoController.clear();
      setState(() {});
    }
  }

  Future<void> saveMemoAndShare(String content, int cardId) async {
    final timestamp = DateTime.now().toIso8601String();
    final prefs = await SharedPreferences.getInstance();

    // 1. 로컬 저장
    await prefs.setString('memo_$cardId', content);

    // 2. Supabase에 자동 업로드
    await Supabase.instance.client.from('community_memos').insert({
      'content': content,
      'created_at': timestamp,
      'card_id': cardId,
      'source': '행운십계명',
      'language': selectedLang,
    });

    // 알림
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiLabels?[selectedLang]?['memo_shared'] ?? '메모가 저장되고 공유되었습니다.',
          ),
        ),
      );
    }
  }

  Future<void> loadMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final memoString = prefs.getString('memos');
    if (memoString != null) {
      try {
        final decodedData = jsonDecode(memoString);
        if (decodedData is List) {
          setState(() {
            memos = List<Map<String, dynamic>>.from(
              decodedData.whereType<Map<String, dynamic>>(),
            );
          });
        }
      } catch (e) {
        logger.e('Error decoding memo data: $e');
      }
    }
  }

  void showAllMemos() {
    final labels = uiLabels?[detectedLang] as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(labels?['view_all_memo'] ?? ''),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: memos.length,
                itemBuilder: (context, index) {
                  final memo = memos.reversed.toList()[index];
                  final String title = memo['title'] ?? '';
                  final String content = memo['memo'] ?? '';
                  final String date =
                      memo['date']?.substring(0, 10) ??
                      labels?['date_none'] ??
                      '날짜 없음';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📝 $title',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(content, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '📅 $date',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const Divider(height: 20, thickness: 1),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  labels?['close'] ?? '',
                  style: const TextStyle(color: Colors.deepPurple),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!labelsLoaded || uiLabels == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final labels = uiLabels![selectedLang] as Map<String, dynamic>;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xffdcd0f7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(labels['loading_cards'] ?? '로딩 중...'),
              Text(
                labels['please_wait'] ?? '잠시만 기다려주세요.',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xffdcd0f7),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: fetchCardsFromSupabase,
                  icon: const Icon(Icons.refresh),
                  label: Text(labels['retry'] ?? '다시 시도'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xffdcd0f7),
        body: Center(
          child: Text(labels['no_cards'] ?? '카드를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.'),
        ),
      );
    }

    final card = _cards[_currentCardIndex];
    final questions = card.getQuestions(selectedLang);

    return Scaffold(
      backgroundColor: const Color(0xfffdf8ff),
      appBar: AppBar(
        title: Text(labels['page_title'] ?? ''),
        centerTitle: true,
        backgroundColor: const Color(0xffdcd0f7),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ReminderSettingPage(selectedLanguage: selectedLang),
                ),
              );
            },
            tooltip: '나의 십계명 기록',
          ),
          IconButton(
            icon: const Icon(Icons.forum),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          CommunityMemoPage(selectedLanguage: selectedLang),
                ),
              );
            },
            tooltip: '커뮤니티 메모',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// 언어 선택 드롭다운
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButton<String>(
                    value: selectedLang,
                    items:
                        supportedLanguages.entries
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedLang = value;
                          detectedLang = value;
                        });
                        fetchCardsFromSupabase();
                      }
                    },
                  ),
                ],
              ),
              Text(
                labels['today_theme'] ?? '🎯 오늘의 실천 제목',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.getTitle(selectedLang).isNotEmpty
                    ? card.getTitle(selectedLang)
                    : labels['no_cards'] ?? '제목 없음',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                labels['today_story'] ?? '오늘의 스토리',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.getStory(selectedLang).isNotEmpty
                    ? card.getStory(selectedLang)
                    : labels['no_cards'] ?? '스토리 없음',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                labels['today_question'] ?? '실천을 위한 질문',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...questions.map((q) => Text('• $q')),
              const SizedBox(height: 16),
              Text(
                labels['memo_title'] ?? '메모하기',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextField(
                controller: memoController,
                decoration: InputDecoration(
                  hintText: labels['memo_placeholder'] ?? '오늘의 실천을 기록해보세요',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final memoText = memoController.text.trim();
                  if (memoText.isNotEmpty && _cards.isNotEmpty) {
                    final cardId = _cards[_currentCardIndex].id;
                    saveMemo().then((_) {
                      saveMemoAndShare(memoText, cardId);
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text(labels['save_memo'] ?? '메모 저장'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            final random = Random();
                            _currentCardIndex = random.nextInt(_cards.length);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade100,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(labels['draw_new_card'] ?? '🔄 새 카드'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton(
                        onPressed: showAllMemos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade100,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(labels['view_my_memo'] ?? '📂 내 메모'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(180, 45), // 가로폭을 넉넉하게
                  backgroundColor: Colors.purple.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              CommunityMemoPage(selectedLanguage: selectedLang),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_alt, size: 20, color: Colors.black),
                    const SizedBox(width: 6),
                    Text(
                      labels['community_memos'] ?? '커뮤니티 메모',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardModel {
  final int id;
  final String? titleKo, storyKo, q1Ko, q2Ko;
  final String? titleEn, storyEn, q1En, q2En;
  final String? titleJa, storyJa, q1Ja, q2Ja;
  final String? titleZh, storyZh, q1Zh, q2Zh;
  final String? titleEs, storyEs, q1Es, q2Es;

  CardModel({
    required this.id,
    this.titleKo,
    this.storyKo,
    this.q1Ko,
    this.q2Ko,
    this.titleEn,
    this.storyEn,
    this.q1En,
    this.q2En,
    this.titleJa,
    this.storyJa,
    this.q1Ja,
    this.q2Ja,
    this.titleZh,
    this.storyZh,
    this.q1Zh,
    this.q2Zh,
    this.titleEs,
    this.storyEs,
    this.q1Es,
    this.q2Es,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as int,
      titleKo: json['title_ko']?.toString(),
      storyKo: json['story_ko']?.toString(),
      q1Ko: json['q1_ko']?.toString(),
      q2Ko: json['q2_ko']?.toString(),
      titleEn: json['title_en']?.toString(),
      storyEn: json['story_en']?.toString(),
      q1En: json['q1_en']?.toString(),
      q2En: json['q2_en']?.toString(),
      titleJa: json['title_ja']?.toString(),
      storyJa: json['story_ja']?.toString(),
      q1Ja: json['q1_ja']?.toString(),
      q2Ja: json['q2_ja']?.toString(),
      titleZh: json['title_zh']?.toString(),
      storyZh: json['story_zh']?.toString(),
      q1Zh: json['q1_zh']?.toString(),
      q2Zh: json['q2_zh']?.toString(),
      titleEs: json['title_es']?.toString(),
      storyEs: json['story_es']?.toString(),
      q1Es: json['q1_es']?.toString(),
      q2Es: json['q2_es']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title_ko': titleKo,
    'story_ko': storyKo,
    'q1_ko': q1Ko,
    'q2_ko': q2Ko,
    'title_en': titleEn,
    'story_en': storyEn,
    'q1_en': q1En,
    'q2_en': q2En,
    'title_ja': titleJa,
    'story_ja': storyJa,
    'q1_ja': q1Ja,
    'q2_ja': q2Ja,
    'title_zh': titleZh,
    'story_zh': storyZh,
    'q1_zh': q1Zh,
    'q2_zh': q2Zh,
    'title_es': titleEs,
    'story_es': storyEs,
    'q1_es': q1Es,
    'q2_es': q2Es,
  };

  String getTitle(String langCode) {
    switch (langCode) {
      case 'ko':
        return titleKo ?? '';
      case 'en':
        return titleEn ?? '';
      case 'ja':
        return titleJa ?? '';
      case 'zh':
        return titleZh ?? '';
      case 'es':
        return titleEs ?? '';
      default:
        return '';
    }
  }

  String getStory(String langCode) {
    switch (langCode) {
      case 'ko':
        return storyKo ?? '';
      case 'en':
        return storyEn ?? '';
      case 'ja':
        return storyJa ?? '';
      case 'zh':
        return storyZh ?? '';
      case 'es':
        return storyEs ?? '';
      default:
        return '';
    }
  }

  List<String> getQuestions(String langCode) {
    String? q1;
    String? q2;
    switch (langCode) {
      case 'ko':
        q1 = q1Ko;
        q2 = q2Ko;
        break;
      case 'en':
        q1 = q1En;
        q2 = q2En;
        break;
      case 'ja':
        q1 = q1Ja;
        q2 = q2Ja;
        break;
      case 'zh':
        q1 = q1Zh;
        q2 = q2Zh;
        break;
      case 'es':
        q1 = q1Es;
        q2 = q2Es;
        break;
      default:
        q1 = null;
        q2 = null;
    }
    return [q1, q2]
        .where((q) => q != null && q.toString().trim().isNotEmpty)
        .map((q) => q!.toString())
        .toList();
  }
}
