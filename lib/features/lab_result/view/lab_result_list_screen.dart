import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../chatbot/repository/chatbot_repository.dart';
import '../model/lab_result.dart';
import '../repository/lab_result_repository.dart';
import 'lab_result_detail_screen.dart';

class LabResultListScreen extends StatefulWidget {
  const LabResultListScreen({
    super.key,
    this.repository,
    this.embedded = false,
  });

  final LabResultRepository? repository;
  final bool embedded;

  @override
  State<LabResultListScreen> createState() => _LabResultListScreenState();
}

class _LabResultListScreenState extends State<LabResultListScreen> {
  Future<List<LabResult>>? _results;

  @override
  void initState() {
    super.initState();
    final repository = widget.repository;
    if (repository != null) {
      _results = repository.getLabResults();
    }
  }

  Future<void> _reload() async {
    final repository = widget.repository;
    if (repository == null) {
      return;
    }

    final future = repository.getLabResults();

    setState(() {
      _results = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder에서 오류 상태를 표시합니다.
    }
  }

  void _openDetail(LabResult result) {
    final repository = widget.repository;
    LabResultDetailRepository? detailRepository;
    ChatbotRepository? chatbotRepository;

    if (repository is LabResultDetailRepository) {
      detailRepository = repository as LabResultDetailRepository;
    }

    if (repository is PatientLabResultRepository) {
      chatbotRepository = ChatbotRepository(repository.client);
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LabResultDetailScreen(
          result: result,
          repository: detailRepository,
          chatbotRepository: chatbotRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(
              primary: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                '혈액검사',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: '새로고침',
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
      body: widget.repository == null
          ? const _PendingView()
          : FutureBuilder<List<LabResult>>(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _ErrorView(onRetry: _reload);
                }

                final results = snapshot.data ?? const <LabResult>[];

                if (results.isEmpty) {
                  return _EmptyView(onRefresh: _reload);
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: results.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFDCEBFF), Color(0xFFE9E5FF)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.fact_check_outlined,
                                color: AppColors.navy,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '최근 혈액검사 결과',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '검사일을 선택하면 수치와 이전 변화를 함께 확인할 수 있어요.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final result = results[index - 1];

                      return Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFE4E9F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openDetail(result),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0F6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.science_outlined,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        result.displayTitle,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _dateText(result.collectedAt),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF2FF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusLabel(result.status),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.mutedText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _PendingView extends StatelessWidget {
  const _PendingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 56, color: AppColors.mutedText),
            SizedBox(height: 18),
            Text(
              '검사결과 데이터 연동을 준비 중입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              '검사결과 화면은 이용할 수 있으며 실제 결과는 연동 후 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.science_outlined, size: 56, color: AppColors.mutedText),
          SizedBox(height: 18),
          Text(
            '확인할 검사결과가 없어요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 16),
            const Text('검사결과를 불러오지 못했어요.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status.toUpperCase()) {
    'FINAL' => '확정',
    'CORRECTED' => '수정됨',
    'DRAFT' => '작성 중',
    _ => status,
  };
}

String _dateText(DateTime date) {
  final kst = date.toUtc().add(const Duration(hours: 9));

  String two(int value) => value.toString().padLeft(2, '0');

  return '${kst.year}.${two(kst.month)}.${two(kst.day)}';
}
