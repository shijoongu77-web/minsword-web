import 'dart:convert';
import 'dart:html' as html; // <--- 이 줄이 반드시 있어야 'html.Blob'을 인식합니다.
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

// 기존 import들...
import 'main.dart';
import 'setting.dart';
import 'action.dart';

extension FileIOLogic on WordController {
  Future<void> createSampleBook() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> books = prefs.getStringList('available_books') ?? [];
    if (books.contains('샘플 단어장')) return;

    List<List<dynamic>> sampleData = [
      ['Day 01', 1, 1, 0, 'abstract', '추상적인'],
      ['Day 01', 2, 2, 0, 'comprehensive', '종합적인'],
      ['Day 01', 3, 3, 0, 'inevitable', '불가피한'],
      ['Day 01', 4, 4, 0, 'prominent', '저명한, 두드러진'],
      ['Day 01', 5, 5, 0, 'relevant', '관련된'],
      ['Day 02', 1, 1, 0, 'adequate', '적절한'],
      ['Day 02', 2, 2, 0, 'sequence', '순서, 연속'],
      ['Day 02', 3, 3, 0, 'revenue', '수익'],
      ['Day 02', 4, 4, 0, 'implement', '실행하다'],
      ['Day 02', 5, 5, 0, 'evaluate', '평가하다']
    ];

    String csvString = ListToCsvConverter().convert(sampleData);
    await prefs.setString('book_content_샘플 단어장', csvString);

    books.add('샘플 단어장');
    await prefs.setStringList('available_books', books);
  }

  Future<void> loadAvailableBooks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> books = prefs.getStringList('available_books') ?? [];

    if (books.isEmpty) {
      await createSampleBook();
      books = prefs.getStringList('available_books') ?? [];
    }

    availableBooks = books;
    updateUI();
  }

  Future<void> selectBook(BuildContext context, String bookName) async {
    final prefs = await SharedPreferences.getInstance();
    lastBookName = bookName;
    selectedChapter = prefs.getString('${lastBookName}_chapter') ?? "";
    currentIndex = prefs.getInt('${lastBookName}_index') ?? 0;

    await loadInternalCsv(lastBookName);
    await saveSettings();
  }

  Future<void> deleteBook(BuildContext context, String bookName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단어장 삭제'),
        content: Text('[$bookName] 단어장을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('book_content_$bookName');
      await prefs.remove('${bookName}_chapter');
      await prefs.remove('${bookName}_index');

      List<String> books = prefs.getStringList('available_books') ?? [];
      books.remove(bookName);
      await prefs.setStringList('available_books', books);

      if (lastBookName == bookName) {
        lastBookName = "";
        selectedChapter = "";
        currentIndex = 0;
        allWords = [];
        filteredWords = [];
        chapters = ["단어장을 불러오세요"];
        updateUI();
      }
      await saveSettings();
      await loadAvailableBooks();
    }
  }

  Future<void> loadInternalCsv(String bookName) async {
    if (bookName.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? csvString = prefs.getString('book_content_$bookName');

      if (csvString == null || csvString.isEmpty) return;

      final List<List<dynamic>> fields = const CsvToListConverter().convert(csvString);
      if (fields.isEmpty) return;

      allWords = fields;
      chapters = allWords.map((row) => row[0].toString()).toSet().toList();

      if (!chapters.contains(selectedChapter)) {
        selectedChapter = chapters.isNotEmpty ? chapters.first : "";
      }

      updateChapterWords();
    } catch (e) {
      debugPrint("CSV 로드 오류: $e");
    }
  }

  Future<void> importCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        final bytes = result.files.first.bytes!;

        // 1. 디코딩 에러 방지 처리 (UTF-8 기준)
        final rawCsvString = utf8.decode(bytes, allowMalformed: true);

        // 2. 줄바꿈 기호 호환성 처리 (\r\n을 \n으로 일괄 통일)
        final normalizedString = rawCsvString.replaceAll('\r\n', '\n');

        // 3. 정규화된 줄바꿈(\n)을 기준으로 CSV 데이터 파싱
        final List<List<dynamic>> fields = CsvToListConverter(eol: '\n').convert(normalizedString);

        if (fields.isEmpty) return;

        // 4. 앱 내부 렌더링 로직(6열)에 맞게 데이터 자동 변환
        List<List<dynamic>> normalizedFields = [];
        for (var row in fields) {
          if (row.length >= 6) {
            normalizedFields.add(row);
          } else if (row.length >= 3) {
            // 사용자가 3열(챕터, 단어, 뜻) 규격으로 올린 경우, 6열 구조로 데이터 확장
            // [챕터, 빈 숫자, 빈 숫자, 미암기(0), 단어, 뜻]
            normalizedFields.add([row[0], 0, 0, 0, row[1], row[2]]);
          }
        }

        if (normalizedFields.isEmpty) return;

        // 변환이 완료된 6열 데이터를 내부 저장용 단일 문자열로 재구성
        String finalCsvString = ListToCsvConverter().convert(normalizedFields);

        String fileName = result.files.first.name.replaceAll('.csv', '');

        final prefs = await SharedPreferences.getInstance();
        List<String> books = prefs.getStringList('available_books') ?? [];

        if (!books.contains(fileName)) {
          books.add(fileName);
          await prefs.setStringList('available_books', books);
        }

        // 변환된 최종 문자열을 스토리지에 저장
        await prefs.setString('book_content_$fileName', finalCsvString);
        await loadAvailableBooks();
        lastBookName = fileName;
        await loadInternalCsv(fileName);
        await saveSettings();
      }
    } catch (e) {
      debugPrint("가져오기 오류: $e");
    }
  }

  /// 단어장 내보내기 (웹 브라우저 다운로드)
  Future<void> exportCsv(BuildContext context) async {
    if (lastBookName.isEmpty || allWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내보낼 단어 데이터가 없습니다.')),
      );
      return;
    }

    try {
      // 1. 데이터 변환 (6열 구조 -> 3열 형식: Chapter, Word, Meaning)
      // 현재 앱 내부 구조: [row[0]=Day, row[1]=No, row[2]=No, row[3]=Status, row[4]=Word, row[5]=Meaning]
      // 내보내기 목표 구조: [Day, Word, Meaning]

      // 2. CSV 문자열 생성 (단어와 뜻에 따옴표 처리)
      String csvContent = allWords.map((row) {
        String day = row[0].toString();
        // 6열 데이터일 경우 row[4], row[5]가 단어와 뜻임
        String word = row.length >= 5 ? row[4].toString() : "";
        String meaning = row.length >= 6 ? row[5].toString() : "";

        // 요청하신 형식: Day N, "Word", "Meaning"
        return '$day, "$word", "$meaning"';
      }).join('\n');

      // 3. 한글 깨짐 방지를 위한 UTF-8 BOM 추가
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([
        [0xEF, 0xBB, 0xBF], // BOM
        bytes
      ], 'text/csv;charset=utf-8');

      // 4. 브라우저 다운로드 트리거
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "${lastBookName}_export.csv")
        ..click();

      // 5. 메모리 해제
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('[$lastBookName] 내보내기를 완료했습니다.')),
      );
    } catch (e) {
      debugPrint("내보내기 오류: $e");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('오류'),
          content: Text('파일을 내보내는 중 오류가 발생했습니다: $e'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
          ],
        ),
      );
    }
  }
}
