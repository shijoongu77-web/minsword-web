import 'main.dart';
import 'file_io.dart';
import 'setting.dart';

extension ActionLogic on WordController {
  void _syncChapterWithCurrentWord() {
    if (filteredWords.isNotEmpty) {
      String currentWordChapter = filteredWords[currentIndex][0].toString();
      if (selectedChapter != currentWordChapter) {
        selectedChapter = currentWordChapter;
      }
    }
  }

  void updateChapterWords() {
    if (currentFilter == 'all_none' || currentFilter == 'all_done') {
      var tempWords = allWords.toList();
      if (currentFilter == 'all_none') {
        tempWords = tempWords.where((row) => row[3].toString() == "0").toList();
      } else {
        tempWords = tempWords.where((row) => row[3].toString() == "1").toList();
      }
      filteredWords = tempWords;
    } else if (currentFilter == 'list') {
      filteredWords = allWords.where((row) => row[0].toString() == selectedChapter).toList();
    } else {
      var tempWords = allWords.where((row) => row[0].toString() == selectedChapter).toList();
      if (currentFilter == 'none') {
        tempWords = tempWords.where((row) => row[3].toString() == "0").toList();
      } else if (currentFilter == 'done') {
        tempWords = tempWords.where((row) => row[3].toString() == "1").toList();
      }
      filteredWords = tempWords;
    }
    updateUI();
  }

  void changeChapter(String newChapter) {
    if (currentFilter == 'all_none' || currentFilter == 'all_done') {
      int idx = filteredWords.indexWhere((row) => row[0].toString() == newChapter);
      if (idx != -1) {
        currentIndex = idx;
      } else {
        selectedChapter = newChapter;
      }
    } else {
      selectedChapter = newChapter;
      currentIndex = 0;
      updateChapterWords();
    }
    _syncChapterWithCurrentWord();
    showFullContent = false;
    updateUI();
    saveSettings();
  }

  void toggleMemorizedAtIndex(int index) {
    if (filteredWords.isEmpty || index >= filteredWords.length) return;

    int currentState = int.tryParse(filteredWords[index][3].toString()) ?? 0;
    filteredWords[index][3] = (currentState == 1) ? 0 : 1;

    saveInternalCsvFile(lastBookName);
    updateUI();
  }

  void toggleMemorized() {
    if (filteredWords.isEmpty) return;
    toggleMemorizedAtIndex(currentIndex);

    if (currentFilter == 'none' || currentFilter == 'done') {
      updateChapterWords();
      if (currentIndex >= filteredWords.length) {
        currentIndex = 0;
      }
    }
    updateUI();
  }

  void nextWord() {
    if (filteredWords.isEmpty) return;
    currentIndex = (currentIndex + 1) % filteredWords.length;
    _syncChapterWithCurrentWord();
    showFullContent = false;
    updateUI();
    saveSettings();
  }

  void prevWord() {
    if (filteredWords.isEmpty) return;
    currentIndex = (currentIndex - 1 + filteredWords.length) % filteredWords.length;
    _syncChapterWithCurrentWord();
    showFullContent = false;
    updateUI();
    saveSettings();
  }
}