import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'file_io.dart';

extension SettingLogic on WordController {
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    fontSize = prefs.getDouble('fontSize') ?? 17.0;
    lastBookName = prefs.getString('lastBookName') ?? "";
    currentFilter = prefs.getString('currentFilter') ?? 'all';
    isDarkModeNotifier.value = prefs.getBool('isDarkMode') ?? false;

    await loadAvailableBooks();

    if (lastBookName.isEmpty && availableBooks.isNotEmpty) {
      lastBookName = availableBooks.first;
    }

    if (lastBookName.isNotEmpty) {
      selectedChapter = prefs.getString('${lastBookName}_chapter') ?? "";
      currentIndex = prefs.getInt('${lastBookName}_index') ?? 0;
      await loadInternalCsv(lastBookName);
    }
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', fontSize);
    await prefs.setString('lastBookName', lastBookName);
    await prefs.setBool('isDarkMode', isDarkModeNotifier.value);
    await prefs.setString('currentFilter', currentFilter);
    if (lastBookName.isNotEmpty) {
      await prefs.setString('${lastBookName}_chapter', selectedChapter);
      await prefs.setInt('${lastBookName}_index', currentIndex);
    }
  }

  void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('폰트 크기: ${fontSize.toInt()}'),
                  Slider(
                    value: fontSize,
                    min: 10.0,
                    max: 40.0,
                    divisions: 30,
                    onChanged: (val) {
                      setDialogState(() => fontSize = val);
                      updateUI();
                      saveSettings();
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('다크모드 설정'),
                      Checkbox(
                        value: isDarkModeNotifier.value,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => isDarkModeNotifier.value = val);
                            saveSettings();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}