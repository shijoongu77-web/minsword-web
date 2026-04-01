import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도움말'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('학습 화면 조작법'),
          _buildHelpItem(Icons.swipe_left, '왼쪽 / 오른쪽으로 밀기', '다음 / 이전 단어로 이동합니다.'),
          _buildHelpItem(Icons.swipe_up, '아래에서 위로 밀기', '단어의 뜻을 보거나 숨깁니다.'),
          _buildHelpItem(Icons.swipe_down, '위에서 아래로 밀기', '해당 단어의 암기 완료 상태를 변경(토글)합니다.'),
          const Divider(height: 32),

          _buildSectionTitle('단어 필터 기능 (모아보기)'),
          _buildHelpItem(Icons.filter_list, '우측 상단 필터 버튼', '\'전체\', \'미암기\', \'암기완료\' 중 원하는 조건의 단어만 모아서 학습할 수 있습니다.'),
          // 목록 보기 기능 설명 추가
          _buildHelpItem(Icons.list_alt, '목록 보기 (현재 챕터)', '현재 챕터의 전체 단어를 리스트 형태로 한눈에 보며, 우측 체크박스로 빠르게 암기 상태를 관리할 수 있습니다.'),
          _buildHelpItem(Icons.auto_awesome, '자동 목록 갱신', '필터(미암기/암기완료)가 적용된 상태에서 암기 여부를 변경하면, 해당 단어는 현재 목록에서 즉시 제외되고 다음 단어로 넘어갑니다.'),
          const Divider(height: 32),

          _buildSectionTitle('단어장(CSV) 추가 방법'),
          _buildHelpItem(Icons.format_list_numbered, '파일 양식', '1열(챕터), 2열(단어), 3열(뜻) 순서로 작성된 CSV 파일만 지원합니다.'),
          _buildHelpItem(Icons.language, '인코딩', '한글 깨짐을 방지하기 위해 엑셀 등에서 \'UTF-8\' 형식으로 저장해야 합니다.'),
          _buildHelpItem(Icons.save_alt, '데이터 관리', '불러온 파일은 앱 내부 관리용으로 자동 변환되어 저장되며, 이후 \'단어장 선택\' 메뉴에서 로드할 수 있습니다.'),
          const Divider(height: 32),

          _buildSectionTitle('암기 상태 관리'),
          _buildHelpItem(Icons.check_circle_outline, '상태 기록', '우측 상단의 체크 아이콘을 누르거나 위에서 아래로 스와이프하면 암기 상태가 내부 파일에 즉시 기록됩니다.'),
          _buildHelpItem(Icons.import_export, '데이터 백업', '\'단어장 내보내기\'를 통해 현재 데이터에서 챕터, 단어, 뜻을 외부 CSV로 백업할 수 있습니다.'),

          // 하단 빈칸 추가
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return ListTile(
      leading: Icon(icon, size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(description),
      contentPadding: EdgeInsets.zero,
    );
  }
}