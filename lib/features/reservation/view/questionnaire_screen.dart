import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../repository/reservation_repository.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({
    super.key,
    required this.reservationId,
    required this.repository,
    this.onSubmitted,
  });

  final int reservationId;
  final ReservationRepository repository;
  final VoidCallback? onSubmitted;

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late final Future<List<Map<String, dynamic>>> _forms = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final response = await widget.repository.client.dio.get<Object?>(
      '/api/patient/reservations/${widget.reservationId}/questionnaires/',
    );
    if (response.data is! List) throw const FormatException('Invalid response');
    return (response.data as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBFF),
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: const Color(0xFF182438),
      title: const Text(
        '\uC608\uC57D \uBB38\uC9C4\uD45C',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _forms,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              '\uBB38\uC9C4\uD45C\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC5B4\uC694.',
            ),
          );
        }
        final forms = snapshot.data!;
        if (forms.isEmpty) {
          return const Center(
            child: Text(
              '\uB4F1\uB85D\uB41C \uBB38\uC9C4\uD45C\uAC00 \uC5C6\uC5B4\uC694.',
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              '\uC9C4\uB8CC\uC5D0 \uCC38\uACE0\uD560 \uB0B4\uC6A9\uC744 \uC791\uC131\uD574 \uC8FC\uC138\uC694.\n\uBB38\uC9C4\uD45C \uC81C\uCD9C\uC740 \uC608\uC57D \uC2B9\uC778\uACFC \uBCC4\uAC1C\uC608\uC694.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF7182A1),
              ),
            ),
            const SizedBox(height: 14),
            for (final entry in forms)
              _QuestionnaireForm(
                key: ValueKey((entry['template'] as Map?)?['id']),
                entry: entry,
                repository: widget.repository,
                reservationId: widget.reservationId,
                onCompleted: () => Navigator.of(context).pop(true),
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
    required this.onCompleted,
  });

  final Map<String, dynamic> entry;
  final ReservationRepository repository;
  final int reservationId;
  final VoidCallback onCompleted;

  @override
  State<_QuestionnaireForm> createState() => _QuestionnaireFormState();
}

class _QuestionnaireFormState extends State<_QuestionnaireForm> {
  final _formKey = GlobalKey<FormState>();
  final _answers = <int, Object>{};
  final _controllers = <int, TextEditingController>{};
  bool _busy = false;
  bool _reviewing = false;
  int _stepIndex = 0;
  String? _message;

  late final Map<String, dynamic> _template = Map<String, dynamic>.from(
    widget.entry['template'] as Map,
  );
  late final List<Map<String, dynamic>> _questions =
      ((_template['questions'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
        ..sort(
          (a, b) => ((a['display_order'] as int?) ?? 0).compareTo(
            (b['display_order'] as int?) ?? 0,
          ),
        );
  late String? _status = widget.entry['response_status'] as String?;

  @override
  void initState() {
    super.initState();
    final rows = widget.entry['answers'];
    if (rows is List) {
      for (final row in rows.whereType<Map>()) {
        if (row['question'] is! int) continue;
        final value =
            row['answer_text'] ??
            row['answer_numeric'] ??
            row['answer_boolean'] ??
            row['answer_json'];
        if (value != null) _answers[row['question'] as int] = value as Object;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<int> get _steps {
    final result =
        _questions.map((q) => (q['step'] as int?) ?? 1).toSet().toList()
          ..sort();
    return result.isEmpty ? [1] : result;
  }

  bool get _readOnly => _status == 'SUBMITTED' || _status == 'REVIEWED';

  bool _missing(Map<String, dynamic> question) {
    final value = _answers[question['id']];
    return question['is_required'] == true &&
        (value == null || value == '' || (value is List && value.isEmpty));
  }

  String _answerLabel(Map<String, dynamic> question) {
    final value = _answers[question['id']];
    if (value == null) return '\uBBF8\uC791\uC131';
    if (value is bool) return value ? '\uC608' : '\uC544\uB2C8\uC694';
    final options = (question['options_json'] as List?) ?? const [];
    String label(Object value) {
      for (final option in options.whereType<Map>()) {
        if (option['value'] == value) return '${option['label']}';
      }
      return '$value';
    }

    return value is List
        ? value.map((item) => label(item as Object)).join(', ')
        : label(value);
  }

  Future<void> _save(bool submit, {bool advance = false}) async {
    if (_busy || _readOnly || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final scope = submit
        ? _questions
        : _questions.where(
            (q) => ((q['step'] as int?) ?? 1) == _steps[_stepIndex],
          );
    if (scope.any(_missing)) {
      setState(
        () => _message =
            '\uD544\uC218 \uC9C8\uBB38\uC744 \uBAA8\uB450 \uC791\uC131\uD574 \uC8FC\uC138\uC694.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final path =
          '/api/patient/reservations/${widget.reservationId}/questionnaire-responses/';
      await widget.repository.client.dio.put<Map<String, dynamic>>(
        path,
        data: {
          'template_id': _template['id'],
          'answers': [
            for (final item in _answers.entries)
              {'question_id': item.key, 'value': item.value},
          ],
        },
      );
      if (!mounted) return;
      if (!submit) {
        setState(() {
          _status = 'DRAFT';
          _message = '\uC784\uC2DC \uC800\uC7A5\uD588\uC5B4\uC694.';
          if (advance) {
            if (_stepIndex < _steps.length - 1) {
              _stepIndex++;
            } else {
              _reviewing = true;
            }
          }
        });
        return;
      }
      final response = await widget.repository.client.dio
          .post<Map<String, dynamic>>(
            '${path}submit/',
            data: {'template_id': _template['id']},
          );
      if (response.data?['status'] != 'SUBMITTED') {
        throw const FormatException('Submit failed');
      }
      if (!mounted) return;
      setState(() => _status = 'SUBMITTED');
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFEAF3FF),
                child: Icon(
                  Icons.check_rounded,
                  size: 34,
                  color: Color(0xFF286BFF),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '\uBB38\uC9C4\uD45C\uAC00 \uC81C\uCD9C\uB418\uC5C8\uC2B5\uB2C8\uB2E4',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '\uC758\uB8CC\uC9C4\uC5D0\uAC8C \uC804\uB2EC\uB418\uC5C8\uC5B4\uC694.',
                style: TextStyle(fontSize: 13, color: Color(0xFF7182A1)),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('\uD655\uC778'),
            ),
          ],
        ),
      );
      if (mounted) widget.onCompleted();
    } on DioException catch (error) {
      if (mounted) setState(() => _message = reservationErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _question(Map<String, dynamic> question) {
    final id = question['id'] as int;
    final type = question['question_type'] as String? ?? 'TEXT';
    final options = (question['options_json'] as List?) ?? const [];
    final enabled = !_busy && !_readOnly;
    void update(Object? value) => setState(() {
      if (value == null || value == '') {
        _answers.remove(id);
      } else {
        _answers[id] = value;
      }
    });
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5ECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFFEAF3FF),
                child: Text(
                  '${_questions.indexOf(question) + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF286BFF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${question['question_text']}${question['is_required'] == true ? ' (\uD544\uC218)' : ''}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF182438),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (type == 'TEXT' || type == 'NUMBER')
            TextFormField(
              controller: _controllers.putIfAbsent(
                id,
                () =>
                    TextEditingController(text: _answers[id]?.toString() ?? ''),
              ),
              enabled: enabled,
              maxLines: type == 'TEXT' ? 3 : 1,
              decoration: const InputDecoration(
                hintText:
                    '\uB0B4\uC6A9\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694.',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  update(type == 'NUMBER' ? num.tryParse(value) : value.trim()),
            ),
          if (type == 'BOOLEAN')
            Wrap(
              spacing: 8,
              children: [
                for (final value in [true, false])
                  ChoiceChip(
                    label: Text(value ? '\uC608' : '\uC544\uB2C8\uC694'),
                    selected: _answers[id] == value,
                    onSelected: enabled
                        ? (selected) => update(selected ? value : null)
                        : null,
                  ),
              ],
            ),
          if (type == 'SINGLE' || type == 'MULTI')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options.whereType<Map>())
                  FilterChip(
                    label: Text(
                      '${option['label']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    selected: type == 'SINGLE'
                        ? _answers[id] == option['value']
                        : ((_answers[id] as List?) ?? const []).contains(
                            option['value'],
                          ),
                    selectedColor: const Color(0xFFEAF3FF),
                    onSelected: !enabled
                        ? null
                        : (selected) {
                            if (type == 'SINGLE') {
                              update(
                                selected ? option['value'] as Object : null,
                              );
                            } else {
                              final values = List<Object>.from(
                                (_answers[id] as List?) ?? const [],
                              );
                              if (selected) {
                                values.add(option['value'] as Object);
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
  Widget build(BuildContext context) {
    final current = _questions
        .where((q) => ((q['step'] as int?) ?? 1) == _steps[_stepIndex])
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09467BC0),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_template['name']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF182438),
                    ),
                  ),
                ),
                Text(
                  _readOnly
                      ? '\uC791\uC131 \uB0B4\uC6A9 \uD655\uC778'
                      : '${_stepIndex + 1} / ${_steps.length} \uB2E8\uACC4',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF286BFF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _readOnly ? 1 : (_stepIndex + 1) / _steps.length,
              minHeight: 4,
              color: const Color(0xFF286BFF),
              backgroundColor: const Color(0xFFE5ECF8),
            ),
            const SizedBox(height: 14),
            if (_readOnly || _reviewing)
              for (final question in _questions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${question['question_text']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _answerLabel(question),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7182A1),
                    ),
                  ),
                )
            else
              for (final question in current) _question(question),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _message!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF486DAE),
                  ),
                ),
              ),
            if (!_readOnly)
              Row(
                children: [
                  if (_stepIndex > 0 || _reviewing)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                if (_reviewing) {
                                  _reviewing = false;
                                } else {
                                  _stepIndex--;
                                }
                              }),
                        child: const Text('\uC774\uC804'),
                      ),
                    ),
                  if (_stepIndex > 0 || _reviewing) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _save(false),
                      child: const Text('\uC784\uC2DC \uC800\uC7A5'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy
                          ? null
                          : () => (_reviewing || _steps.length == 1
                                ? _save(true)
                                : _save(false, advance: true)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF286BFF),
                      ),
                      child: Text(
                        _busy
                            ? '\uCC98\uB9AC \uC911...'
                            : (_reviewing || _steps.length == 1
                                  ? '\uCD5C\uC885 \uC81C\uCD9C'
                                  : '\uB2E4\uC74C'),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
