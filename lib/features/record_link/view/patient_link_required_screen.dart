import 'package:flutter/material.dart';
import '../../reservation/view/reservation_screen.dart';
import '../../reservation/repository/reservation_repository.dart';

class PatientLinkRequiredScreen extends StatelessWidget {
  const PatientLinkRequiredScreen({
    super.key,
    this.onRefresh,
    this.reservationRepository,
    this.onLogout,
  });
  final ReservationRepository? reservationRepository;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('병원기록 연결'),
        actions: [
          if (onLogout != null)
            IconButton(
              tooltip: '로그아웃',
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.folder_shared_outlined,
                  size: 72,
                  color: Color(0xFF1E3A8A),
                ),
                const SizedBox(height: 24),
                const Text(
                  '아직 연결된 병원기록이 없어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '카카오 로그인은 완료됐어요.\n'
                  '병원기록을 연결하면 내 환자정보와\n'
                  '연결된 의료기록을 확인할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '진료가 필요하신가요?\n'
                    '아래 버튼에서 진료 예약 화면을 확인해 주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.5, color: Color(0xFF1E3A8A)),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFF1E3A8A),
                  ),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ReservationScreen(repository: reservationRepository),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('진료 예약'),
                ),
                if (onRefresh != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: onRefresh,
                    child: const Text('연결 상태 다시 확인'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
