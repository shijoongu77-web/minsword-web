import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:csv/csv.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'help_page.dart';
import 'file_io.dart';
import 'action.dart';
import 'setting.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

void main() {
  runApp(const MinsWordsApp());
}

class WordController extends ChangeNotifier {
  double fontSize = 17.0;
  String lastBookName = "";
  String selectedChapter = "";
  int currentIndex = 0;
  String currentFilter = 'all';

  List<List<dynamic>> allWords = [];
  List<List<dynamic>> filteredWords = [];
  List<String> chapters = ["단어장을 불러오세요"];
  List<String> availableBooks = [];
  bool showFullContent = false;

  final FlutterTts tts = FlutterTts();

  Future<void> saveInternalCsvFile(String bookName) async {
    if (bookName.isEmpty || allWords.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      String csv = ListToCsvConverter().convert(allWords);
      await prefs.setString('book_content_$bookName', csv);
      debugPrint("저장 성공: $bookName");
    } catch (e) {
      debugPrint("저장 실패: $e");
    }
  }

  Future<void> speak(String text) async {
    await tts.setLanguage("en-US");
    await tts.setPitch(1.0);
    await tts.speak(text);
  }

  void updateUI() {
    notifyListeners();
  }
}

class MinsWordsApp extends StatelessWidget {
  const MinsWordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: '민쌤 단어장',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: const MainStudyPage(),
        );
      },
    );
  }
}

class MainStudyPage extends StatefulWidget {
  const MainStudyPage({super.key});

  @override
  State<MainStudyPage> createState() => _MainStudyPageState();
}

class _MainStudyPageState extends State<MainStudyPage> with WidgetsBindingObserver {
  final WordController controller = WordController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      controller.saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        String filterName = '전체 (현재 챕터)';
        if (controller.currentFilter == 'none') filterName = '미암기 (현재 챕터)';
        else if (controller.currentFilter == 'done') filterName = '암기완료 (현재 챕터)';
        else if (controller.currentFilter == 'list') filterName = '목록보기 (현재 챕터)';
        else if (controller.currentFilter == 'all_none') filterName = '미암기 전체';
        else if (controller.currentFilter == 'all_done') filterName = '암기 전체';

        String word = "조건에 맞는 단어가 없습니다.";
        String meaning = "[현재 상태: $filterName]\n필터를 변경하거나 다른 챕터를 선택하세요.";
        bool isMemorized = false;

        if (controller.filteredWords.isNotEmpty && controller.filteredWords[controller.currentIndex].length >= 6) {
          word = controller.filteredWords[controller.currentIndex][4].toString();
          meaning = controller.filteredWords[controller.currentIndex][5].toString();
          isMemorized = (controller.filteredWords[controller.currentIndex][3].toString() == "1");
        }

        String currentBookName = controller.lastBookName.isEmpty ? "단어장이 선택되지 않았습니다." : controller.lastBookName;
        bool displayFullContent = controller.showFullContent || controller.filteredWords.isEmpty;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton<String>(
                value: controller.chapters.contains(controller.selectedChapter) ? controller.selectedChapter : controller.chapters.first,
                underline: const SizedBox(),
                items: controller.chapters.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    controller.changeChapter(val);
                  }
                },
              ),
            ),
            centerTitle: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                initialValue: controller.currentFilter,
                onSelected: (val) {
                  controller.currentFilter = val;
                  controller.currentIndex = 0;
                  controller.updateChapterWords();
                  controller.saveSettings();
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(value: 'all', child: Text('전체 (현재 챕터)')),
                  const PopupMenuItem<String>(value: 'none', child: Text('미암기 (현재 챕터)')),
                  const PopupMenuItem<String>(value: 'done', child: Text('암기완료 (현재 챕터)')),
                  const PopupMenuItem<String>(value: 'list', child: Text('목록 보기')),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(value: 'all_none', child: Text('미암기 전체')),
                  const PopupMenuItem<String>(value: 'all_done', child: Text('암기 전체')),
                ],
              ),
            ],
          ),
          drawer: Drawer(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: DrawerHeader(
                      decoration: const BoxDecoration(color: Colors.deepPurple),
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      child: const Center(
                        child: Text(
                          '민쌤 단어장',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        ExpansionTile(
                          leading: const Icon(Icons.library_books),
                          title: const Text('단어장 선택'),
                          initiallyExpanded: true,
                          children: controller.availableBooks.isEmpty
                              ? [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 12.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('단어장 없음', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          ]
                              : [
                            ReorderableListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              onReorder: (oldIndex, newIndex) async {
                                if (newIndex > oldIndex) {
                                  newIndex -= 1;
                                }
                                final item = controller.availableBooks.removeAt(oldIndex);
                                controller.availableBooks.insert(newIndex, item);
                                controller.updateUI();

                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setStringList('available_books', controller.availableBooks);
                              },
                              children: controller.availableBooks.map((String bookName) {
                                bool isSelected = bookName == controller.lastBookName;
                                return ListTile(
                                  key: ValueKey(bookName),
                                  dense: true,
                                  visualDensity: const VisualDensity(vertical: -2),
                                  contentPadding: const EdgeInsets.only(left: 40.0, right: 8.0),
                                  title: Text(
                                    bookName,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.deepPurple : null,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                        onPressed: () => controller.deleteBook(context, bookName),
                                      ),
                                      const Icon(Icons.drag_handle, color: Colors.grey),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    controller.selectBook(context, bookName);
                                  },
                                );
                              }).toList(),
                            )
                          ],
                        ),
                        ListTile(
                          leading: const Icon(Icons.file_download),
                          title: const Text('단어장 가져오기'),
                          onTap: () { Navigator.pop(context); controller.importCsv(); },
                        ),
                        /*
                        ListTile(
                          leading: const Icon(Icons.file_upload),
                          title: const Text('단어장 내보내기'),
                          onTap: () { Navigator.pop(context); controller.exportCsv(context); },
                        ),
                         */
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('도움말'),
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('설정'),
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    onTap: () {
                      Navigator.pop(context);
                      controller.showSettingsDialog(context);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                color: isDarkModeNotifier.value ? Colors.grey[800] : Colors.grey[200],
                child: Text(
                  currentBookName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: controller.currentFilter == 'list'
                    ? ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.filteredWords.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    var wordData = controller.filteredWords[index];
                    String wordText = wordData[4].toString();
                    String meaningText = wordData[5].toString();
                    bool isDone = wordData[3].toString() == "1";

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            wordText,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          GestureDetector(
                            onTap: () => controller.toggleMemorizedAtIndex(index),
                            child: Icon(
                              isDone ? Icons.check_box : Icons.check_box_outline_blank,
                              color: isDone ? Colors.green : Colors.grey,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        " $meaningText",
                        style: TextStyle(
                            fontSize: 15,
                            color: isDarkModeNotifier.value ? Colors.grey[400] : Colors.blueGrey
                        ),
                      ),
                    );
                  },
                )
                    : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.filteredWords.isEmpty ? "0 / 0" : '${controller.currentIndex + 1} / ${controller.filteredWords.length}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(isMemorized ? Icons.check_circle : Icons.check_circle_outline,
                                color: isMemorized ? Colors.green : Colors.grey),
                            onPressed: controller.toggleMemorized,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity == null) return;
                          if (details.primaryVelocity! > 500) controller.prevWord();
                          else if (details.primaryVelocity! < -500) controller.nextWord();
                        },
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity == null) return;
                          if (details.primaryVelocity! > 500) {
                            controller.toggleMemorized();
                          } else if (details.primaryVelocity! < -500) {
                            controller.showFullContent = !controller.showFullContent;
                            controller.updateUI();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    word,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: controller.fontSize * 2, fontWeight: FontWeight.bold),
                                  ),
                                  if (displayFullContent) ...[
                                    const SizedBox(height: 20),
                                    Text(
                                      meaning,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: controller.fontSize * 1.5, color: isDarkModeNotifier.value ? Colors.grey[400] : Colors.blueGrey),
                                    ),
                                  ],
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                          icon: const Icon(Icons.volume_up, size: 40),
                                          onPressed: () {
                                            if (controller.filteredWords.isNotEmpty) controller.speak(word);
                                          }
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}