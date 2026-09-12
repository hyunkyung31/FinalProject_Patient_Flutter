import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../repository/reservation_repository.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({
    super.key,
    required this.reservationId,
    required this.repository,
  });
  final int reservationId;
  final ReservationRepository repository;
  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late final Future<List<dynamic>> forms = _load();
  Future<List<dynamic>> _load() async {
    final response = await widget.repository.client.dio.get<Object?>(
      '/api/patient/reservations/${widget.reservationId}/questionnaires/',
    );
    if (response.data is! List) throw const FormatException('문진표 응답 오류');
    return response.data as List;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('예약 문진표')),
    body: FutureBuilder<List<dynamic>>(
      future: forms,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('문진표를 불러오지 못했어요.\n뒤로 돌아간 후 다시 열어 주세요.'),
          );
        }
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                '현재 이 예약에 등록된 문진표가 없어요.\n예약 상세에서 나중에 다시 확인할 수 있어요.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('진료에 참고할 내용을 작성해 주세요. 문진표 제출은 예약 승인과 별개예요.'),
            for (final entry in snapshot.data!)
              _QuestionnaireForm(
                key: ValueKey((entry as Map)['template']['id']),
                entry: Map<String, dynamic>.from(entry),
                repository: widget.repository,
                reservationId: widget.reservationId,
              ),
          ],
        );
      },
    ),
  );
}

class _QuestionnaireForm extends StatefulWidget {
  const _QuestionnaireForm({
    super.key,
    required this.entry,
    required this.repository,
    required this.reservationId,
  });
  final Map<String, dynamic> entry;
  final ReservationRepository repository;
  final int reservationId;
  @override
  State<_QuestionnaireForm> createState() => _QuestionnaireFormState();
}

class _QuestionnaireFormState extends State<_QuestionnaireForm> {
  final answers = <int, Object>{};
  final formKey = GlobalKey<FormState>();
  final controllers = <int, TextEditingController>{};
  int stepIndex = 0;
  bool reviewing = false;
  List<int> get steps =>
      questions.map((q) => (q['step'] as int?) ?? 1).toSet().toList()..sort();
  bool visible(Map q) {
    final condition = q['condition_json'];
    if (condition is! Map || condition['source'] == 'previous_answer')
      return true;
    Object? actual;
    for (final source in questions) {
      if (source['question_code'] == condition['question_code'])
        actual = answers[source['id']];
    }
    return switch (condition['operator']) {
      'equals' => actual == condition['value'],
      'contains' => actual is List && actual.contains(condition['value']),
      'in' =>
        condition['value'] is List &&
            (condition['value'] as List).contains(actual),
      _ => true,
    };
  }

  void clearHidden() {
    for (var pass = 0; pass < questions.length; pass++) {
      bool removed = false;
      for (final q in questions) {
        if (!visible(q)) {
          removed = answers.remove(q['id']) != null || removed;
          controllers[q['id']]?.clear();
        }
      }
      if (!removed) break;
    }
  }

  bool missing(Map q) {
    final value = answers[q['id']];
    return q['is_required'] == true &&
        visible(q) &&
        (value == null || value == '' || (value is List && value.isEmpty));
  }

  String answerLabel(Map q) {
    final value = answers[q['id']];
    if (value == null || (value is List && value.isEmpty)) return '미작성';
    if (value is bool) return value ? '예' : '아니요';
    String label(Object? v) {
      for (final option in (q['options_json'] as List?) ?? []) {
        if (option['value'] == v) return option['label'] as String;
      }
      return '$v';
    }

    return value is List ? value.map(label).join(', ') : label(value);
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  late final Map template = widget.entry['template'] as Map;
  late final List<Map> questions =
      (template['questions'] as List).cast<Map>().toList()..sort(
        (a, b) =>
            (a['display_order'] as int).compareTo(b['display_order'] as int),
      );
  late String? status = widget.entry['response_status'] as String?;
  late final bool existing =
      status != null || widget.entry['response_id'] != null;
  bool busy = false;
  bool processing = false;
  bool uncertain = false;
  String? message;
  bool get supported => questions.every(
    (q) => [
      'TEXT',
      'SINGLE',
      'MULTI',
      'BOOLEAN',
      'NUMBER',
    ].contains(q['question_type']),
  );
  bool get locked =>
      existing ||
      uncertain ||
      !supported ||
      status == 'SUBMITTED' ||
      status == 'REVIEWED';
  String get path =>
      '/api/patient/reservations/${widget.reservationId}/questionnaire-responses/';

  Future<void> save(bool submit, {bool advance = false}) async {
    if (busy || locked) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    clearHidden();
    if ((submit || advance) &&
        questions.any(
          (q) =>
              (submit || ((q['step'] as int?) ?? 1) == steps[stepIndex]) &&
              missing(q),
        )) {
      setState(() => message = '필수 질문에 모두 답해 주세요.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    bool sent = false;
    try {
      if (submit) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('문진표를 제출할까요?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('제출한 뒤에는 수정할 수 없어요.'),
                  for (final q in questions.where(visible))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('${q['question_text']}\n${answerLabel(q)}'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('돌아가기'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('제출'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
      }
      sent = true;
      setState(() => processing = true);
      final saved = await widget.repository.client.dio
          .put<Map<String, dynamic>>(
            path,
            data: {
              'template_id': template['id'],
              'answers': [
                for (final a in answers.entries)
                  {'question_id': a.key, 'value': a.value},
              ],
            },
          );
      if (saved.data?['status'] != 'DRAFT')
        throw const FormatException('저장 응답 오류');
      if (!mounted) return;
      setState(() => status = 'DRAFT');
      if (submit) {
        final result = await widget.repository.client.dio
            .post<Map<String, dynamic>>(
              '${path}submit/',
              data: {'template_id': template['id']},
            );
        if (result.data?['status'] != 'SUBMITTED')
          throw const FormatException('제출 응답 오류');
        if (!mounted) return;
        setState(() {
          status = 'SUBMITTED';
          message = '문진표를 제출했어요.';
        });
      } else {
        setState(() {
          message = '임시 저장했어요. 이 화면에서는 계속 작성할 수 있어요.';
          if (advance) {
            if (stepIndex < steps.length - 1) {
              stepIndex++;
            } else {
              reviewing = true;
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      final response = e is DioException ? e.response : null;
      final data = response?.data;
      setState(() {
        uncertain =
            sent && (response == null || (response.statusCode ?? 500) >= 500);
        if (data is Map && data['detail'] == '이미 제출된 문진표입니다.') uncertain = true;
        message = uncertain
            ? '처리 결과를 확인해야 해요. 뒤로 돌아간 후 문진표를 다시 열어 상태를 확인해 주세요.'
            : data is Map && data['detail'] is String
            ? data['detail'] as String
            : '저장하지 못했어요. 다시 시도해 주세요.';
      });
    } finally {
      if (mounted)
        setState(() {
          busy = false;
          processing = false;
        });
    }
  }

  Widget question(Map q) {
    final id = q['id'] as int;
    final type = q['question_type'];
    final options = (q['options_json'] as List?) ?? [];
    final enabled = !busy && !locked;
    void update(Object? value) => setState(() {
      if (value == null || value == '') {
        answers.remove(id);
      } else {
        answers[id] = value;
      }
      clearHidden();
    });
    return Padding(
      key: ValueKey(id),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${q['question_text']}${q['is_required'] == true ? ' (필수)' : ''}',
          ),
          const SizedBox(height: 8),
          if (type == 'TEXT' || type == 'NUMBER')
            TextFormField(
              controller: controllers.putIfAbsent(
                id,
                () =>
                    TextEditingController(text: answers[id]?.toString() ?? ''),
              ),
              enabled: enabled,
              keyboardType: type == 'NUMBER'
                  ? const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    )
                  : TextInputType.multiline,
              maxLines: type == 'TEXT' ? 3 : 1,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: (value) {
                if (type == 'NUMBER' &&
                    value != null &&
                    value.trim().isNotEmpty) {
                  final n = num.tryParse(value.trim());
                  if (n == null || !n.isFinite) return '올바른 숫자를 입력해 주세요.';
                }
                return null;
              },
              onChanged: (value) => update(
                type == 'NUMBER' ? num.tryParse(value.trim()) : value.trim(),
              ),
            ),
          if (type == 'BOOLEAN')
            Wrap(
              spacing: 8,
              children: [
                for (final value in [true, false])
                  ChoiceChip(
                    label: Text(value ? '예' : '아니요'),
                    selected: answers[id] == value,
                    onSelected: enabled
                        ? (selected) => update(selected ? value : null)
                        : null,
                  ),
              ],
            ),
          if (type == 'SINGLE' || type == 'MULTI')
            Wrap(
              spacing: 8,
              children: [
                for (final option in options)
                  FilterChip(
                    label: Text(option['label'] as String),
                    selected: type == 'SINGLE'
                        ? answers[id] == option['value']
                        : ((answers[id] as List?) ?? []).contains(
                            option['value'],
                          ),
                    onSelected: !enabled
                        ? null
                        : (selected) {
                            if (type == 'SINGLE') {
                              update(selected ? option['value'] : null);
                            } else {
                              final values = List<Object>.from(
                                (answers[id] as List?) ?? [],
                              );
                              if (selected) {
                                final exclusive =
                                    (q['ui_config_json'] is Map
                                        ? q['ui_config_json']['exclusive_values']
                                              as List?
                                        : null) ??
                                    [];
                                if (exclusive.contains(option['value'])) {
                                  values.clear();
                                } else {
                                  values.removeWhere(exclusive.contains);
                                }
                                values.add(option['value']);
                              } else {
                                values.remove(option['value']);
                              }
                              update(values);
                            }
                          },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template['name'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(switch (status) {
              'DRAFT' => '임시 저장',
              'SUBMITTED' => '제출 완료',
              'REVIEWED' => '의료진 확인 완료',
              _ => '작성 전',
            }),
            if (existing)
              const Text(
                '기존 답변을 보호하기 위해 수정은 잠겨 있어요. 저장 상태는 확인했지만 서버에서 답변 내용을 아직 제공하지 않아 표시할 수 없어요.',
              )
            else if (!supported)
              const Text('아직 지원하지 않는 질문이 있어요. 병원에 문의해 주세요.')
            else ...[
              if (status == 'SUBMITTED' || status == 'REVIEWED') ...[
                const Text('제출한 내용이에요. 제출 후에는 수정할 수 없어요.'),
                for (final q in questions.where(visible)) ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(q['question_text'] as String),
                  subtitle: Text(answerLabel(q)),
                ),
              ] else ...[
              if (questions.any(
                (q) =>
                    q['condition_json'] is Map &&
                    q['condition_json']['source'] == 'previous_answer',
              ))
                const Text(
                  '이전 문진 답변을 불러올 수 없어 관련 질문도 함께 표시해요. 현재 상태에 맞게 답해 주세요.',
                ),
              if (steps.isNotEmpty)
                Text(
                  reviewing
                      ? '작성 내용 확인'
                      : '${stepIndex + 1} / ${steps.length}단계',
                ),
              if (reviewing)
                for (final q in questions.where(visible))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(q['question_text'] as String),
                    subtitle: Text(answerLabel(q)),
                  )
              else
                for (final q in questions.where(
                  (q) =>
                      visible(q) &&
                      ((q['step'] as int?) ?? 1) == steps[stepIndex],
                ))
                  question(q),
              if (message != null) Text(message!),
              if (processing) const LinearProgressIndicator(),
              Wrap(
                spacing: 8,
                children: [
                  if (stepIndex > 0 || reviewing)
                    TextButton(
                      onPressed: busy || locked
                          ? null
                          : () => setState(() {
                              if (reviewing) {
                                reviewing = false;
                              } else {
                                stepIndex--;
                              }
                              message = null;
                            }),
                      child: const Text('이전'),
                    ),
                  OutlinedButton(
                    onPressed: busy || locked ? null : () => save(false),
                    child: const Text('임시 저장'),
                  ),
                  if (steps.length > 1 && !reviewing)
                    FilledButton(
                      onPressed: busy || locked
                          ? null
                          : () => save(false, advance: true),
                      child: Text(
                        stepIndex == steps.length - 1 ? '작성 내용 확인' : '다음',
                      ),
                    ),
                  if (reviewing || steps.length <= 1)
                    FilledButton(
                      onPressed: busy || locked ? null : () => save(true),
                      child: const Text('최종 제출'),
                    ),
                ],
              ),
              ],
            ],
          ],
        ),
      ),
    ),
  );
}
