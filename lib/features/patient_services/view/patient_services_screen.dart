import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_preferences.dart';
import '../../reservation/model/booking_options.dart';
import '../../reservation/repository/reservation_repository.dart';
import '../../verification/view/phone_verification_screen.dart';
import '../repository/patient_services_repository.dart';

class PatientServicesScreen extends StatefulWidget {
  const PatientServicesScreen({
    super.key,
    required this.repository,
    this.section = 'menu',
  });
  final ReservationRepository repository;
  final String section;
  @override
  State<PatientServicesScreen> createState() => _PatientServicesScreenState();
}

class _PatientServicesScreenState extends State<PatientServicesScreen> {
  late final api = PatientServicesRepository(widget.repository.client);
  final value = TextEditingController();
  final reason = TextEditingController();
  final form = GlobalKey<FormState>();
  Map<String, dynamic>? data;
  List<Map<String, dynamic>> rows = [];
  int page = 1;
  bool more = false;
  bool loading = false;
  bool saving = false;
  bool uncertain = false;
  bool linkRequested = false;
  String? error;
  String field = 'name';
  static const fields = {
    'name': '이름',
    'birth_date': '생년월일',
    'gender': '성별',
    'contact': '연락처',
  };
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    value.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> _load({bool next = false}) async {
    if (loading) return;
    if (widget.section == 'menu' || widget.section == 'settings') return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final requested = next ? page + 1 : 1;
      PatientPage? result;
      Map<String, dynamic>? object;
      switch (widget.section) {
        case 'profile':
          object = await api.profile();
        case 'link':
          object = await api.linkStatus();
        case 'changes':
          result = await api.changes(requested);
        case 'documents':
          result = await api.documents(requested);
        case 'consents':
          result = await api.consents(requested);
      }
      if (!mounted) return;
      setState(() {
        data = object;
        if (result != null) {
          rows = next ? [...rows, ...result.items] : result.items;
          more = result.hasNext;
          page = requested;
        }
      });
    } catch (e) {
      if (mounted) setState(() => error = patientServiceError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void open(String section) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => PatientServicesScreen(
        repository: widget.repository,
        section: section,
      ),
    ),
  );
  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<bool> confirm(String title, String detail) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(detail),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('돌아가기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('확인'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> write(Future<void> Function() action, String success) async {
    if (saving || uncertain) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await action();
      if (!mounted) return;
      message(success);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        uncertain =
            e is DioException &&
            (e.response == null || (e.response?.statusCode ?? 500) >= 500);
        error = uncertain
            ? '처리 결과를 확인하지 못했어요. 중복 요청하지 말고 새로고침으로 반영 여부를 확인해 주세요.'
            : patientServiceError(e);
      });
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> link() async {
    if (saving || uncertain) return;
    setState(() => saving = true);
    try {
      var verification = await widget.repository.getVerification();
      if (!mounted) return;
      if (verification?.isValid(DateTime.now()) != true ||
          verification?.verifiedPhoneNumber == null) {
        verification = await Navigator.of(context).push<BookingVerification>(
          MaterialPageRoute(
            builder: (_) =>
                PhoneVerificationScreen(repository: widget.repository),
          ),
        );
      }
      if (!mounted || verification == null) return;
      if (!verification.isValid(DateTime.now())) {
        message('인증이 만료됐어요. 다시 진행해 주세요.');
        return;
      }
      if (!await confirm(
        '병원기록 연결을 요청할까요?',
        '병원 담당자가 확인한 뒤 연결됩니다. 휴대폰 인증만으로 자동 연결되지 않아요.',
      )) {
        return;
      }
      if (!mounted) return;
      setState(() => saving = false);
      await write(
        () async {
          await api.requestLink(verification!.id);
          linkRequested = true;
        },
        '연결 요청이 접수됐어요. 연결 상태를 다시 확인해 주세요.',
      );
    } catch (e) {
      if (mounted) setState(() => error = patientServiceError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String text(Map<String, dynamic> row, String key) =>
      row[key]?.toString() ?? '정보 없음';
  String status(Object? value) => switch (value) {
    'PENDING' => '승인 대기',
    'APPROVED' => '승인',
    'REJECTED' => '반려',
    'CONSENTED' => '동의',
    'WITHDRAWN' => '철회',
    _ => value?.toString() ?? '상태 확인 필요',
  };
  Widget tile(String title, String sub, IconData icon, VoidCallback action) =>
      Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: action,
        ),
      );

  @override
  Widget build(BuildContext context) {
    const titles = {
      'menu': '내 정보 · 서비스',
      'profile': '환자정보',
      'link': '병원기록 연결',
      'changes': '정보 변경 요청',
      'documents': '약관 · 동의 문서',
      'consents': '내 동의 내역',
      'settings': '화면 · 접근성 설정',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[widget.section] ?? '내 정보'),
        actions: [
          if (widget.section != 'menu' && widget.section != 'settings')
            IconButton(
              tooltip: '새로고침',
              onPressed: loading || saving ? null : () => _load(),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ...body(),
            if (more)
              TextButton(
                onPressed: loading ? null : () => _load(next: true),
                child: const Text('더 보기'),
              ),
            if (saving) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  List<Widget> body() {
    final disabled = saving || loading || uncertain;
    switch (widget.section) {
      case 'menu':
        return [
          tile(
            '내 환자정보',
            '병원에 등록된 정보 조회 · 변경 요청',
            Icons.person_outline,
            () => open('profile'),
          ),
          tile(
            '병원기록 연결',
            '휴대폰 인증 후 연결 요청',
            Icons.folder_shared_outlined,
            () => open('link'),
          ),
          tile(
            '약관 · 개인정보 동의',
            '문서 확인과 동의',
            Icons.description_outlined,
            () => open('documents'),
          ),
          tile(
            '내 동의 내역',
            '동의 내역 확인 · 철회',
            Icons.privacy_tip_outlined,
            () => open('consents'),
          ),
          tile(
            '화면 · 접근성',
            '글자 크기 · 테마 · 대비 · 모션',
            Icons.settings_accessibility,
            () => open('settings'),
          ),
        ];
      case 'profile':
        return [
          if (data != null) ...[
            for (final entry in {
              'name': '이름',
              'birth_date': '생년월일',
              'gender': '성별',
              'contact': '연락처',
              'medical_record_no': '환자번호',
            }.entries)
              ListTile(
                title: Text(entry.value),
                subtitle: Text(text(data!, entry.key)),
              ),
            const Text('병원에 등록된 정보입니다. 수정 내용은 병원 담당자의 승인 후 반영됩니다.'),
            FilledButton(
              onPressed: () => open('changes'),
              child: const Text('정보 변경 요청'),
            ),
          ],
          if (!loading && data == null)
            OutlinedButton(
              onPressed: () => open('link'),
              child: const Text('병원기록 연결 확인'),
            ),
        ];
      case 'changes':
        return [
          Form(
            key: form,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: field,
                  decoration: const InputDecoration(labelText: '변경할 항목'),
                  items: fields.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: disabled
                      ? null
                      : (v) => setState(() {
                          field = v!;
                          value.clear();
                        }),
                ),
                const SizedBox(height: 16),
                if (field == 'gender')
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: '변경할 성별'),
                    items: const [
                      DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                      DropdownMenuItem(value: 'MALE', child: Text('남성')),
                    ],
                    onChanged: disabled ? null : (v) => value.text = v!,
                    validator: (_) =>
                        value.text.isEmpty ? '성별을 선택해 주세요.' : null,
                  )
                else
                  TextFormField(
                    controller: value,
                    enabled: !disabled,
                    maxLength: 255,
                    decoration: InputDecoration(
                      labelText: '변경할 ${fields[field]}',
                      hintText: field == 'birth_date' ? '1995-04-20' : null,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return '변경할 내용을 입력해 주세요.';
                      }
                      if (field == 'birth_date') {
                        final parsed = DateTime.tryParse(v);
                        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) ||
                            parsed == null ||
                            parsed.toIso8601String().substring(0, 10) != v ||
                            parsed.isAfter(DateTime.now())) {
                          return '올바른 날짜를 YYYY-MM-DD로 입력해 주세요.';
                        }
                      }
                      if (field == 'contact' &&
                          !RegExp(
                            r'^0\d{8,10}$',
                          ).hasMatch(v.replaceAll('-', '').trim())) {
                        return '연락처를 확인해 주세요.';
                      }
                      return null;
                    },
                  ),
                TextFormField(
                  controller: reason,
                  enabled: !disabled,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: '변경 사유 (선택)'),
                ),
                FilledButton(
                  onPressed: disabled
                      ? null
                      : () async {
                          if (!form.currentState!.validate()) return;
                          if (await confirm(
                                '정보 변경을 요청할까요?',
                                '${fields[field]}: ${value.text}\n승인 후 병원정보에 반영됩니다.',
                              ) &&
                              mounted) {
                            await write(
                              () => api.requestChange(
                                field,
                                value.text.trim(),
                                reason.text.trim(),
                              ),
                              '변경 요청이 접수됐어요.',
                            );
                          }
                        },
                  child: const Text('변경 요청 보내기'),
                ),
              ],
            ),
          ),
          const Divider(),
          const Text('변경 요청 내역'),
          if (!loading && error == null && rows.isEmpty)
            const Text('변경 요청 내역이 없어요.'),
          for (final row in rows)
            ListTile(
              title: Text(
                '${fields[row['field_name']] ?? row['field_name']} · ${status(row['status'])}',
              ),
              subtitle: Text(
                '${text(row, 'requested_value_masked')}\n${text(row, 'requested_at')}${row['rejection_reason'] == null ? '' : '\n${row['rejection_reason']}'}',
              ),
            ),
        ];
      case 'link':
        final linked = data?['linked'] == true;
        final request = data?['link_request'];
        final pending = linkRequested || (request is Map && request['status'] == 'PENDING');
        return [
          if (data != null) ...[
            Icon(
              linked
                  ? Icons.check_circle_outline
                  : Icons.folder_shared_outlined,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              linked
                  ? '병원기록이 연결되어 있어요.'
                  : pending
                  ? '병원에서 연결 요청을 확인하고 있어요.'
                  : '연결된 병원기록이 없어요.',
              textAlign: TextAlign.center,
            ),
            if (request is Map)
              ListTile(
                title: const Text('최근 연결 요청'),
                subtitle: Text(status(request['status'])),
              ),
            if (!linked && !pending)
              FilledButton(
                onPressed: disabled ? null : link,
                child: const Text('휴대폰 인증 후 연결 요청'),
              ),
            if (linked)
              TextButton(
                onPressed: () => open('profile'),
                child: const Text('연결된 환자정보 보기'),
              ),
          ],
        ];
      case 'documents':
        return [
          if (!loading && error == null && rows.isEmpty)
            const Text('등록된 동의 문서가 없어요.'),
          for (final row in rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      text(row, 'title'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '버전 ${text(row, 'version')} · ${row['consent_type'] == 'REQUIRED' ? '필수' : '선택'}',
                    ),
                    const SizedBox(height: 12),
                    SelectableText(text(row, 'content_text')),
                    FilledButton(
                      onPressed:
                          disabled ||
                              row['is_active'] != true ||
                              row['id'] is! int
                          ? null
                          : () async {
                              if (await confirm(
                                    '이 문서에 동의할까요?',
                                    '${text(row, 'title')} · 버전 ${text(row, 'version')}\n동의 내역이 계정에 저장됩니다.',
                                  ) &&
                                  mounted) {
                                await write(
                                  () => api.consent(row['id'] as int),
                                  '동의가 저장됐어요. 내 동의 내역에서 확인할 수 있어요.',
                                );
                              }
                            },
                      child: const Text('내용 확인 후 동의'),
                    ),
                  ],
                ),
              ),
            ),
          TextButton(
            onPressed: () => open('consents'),
            child: const Text('내 동의 내역 보기'),
          ),
        ];
      case 'consents':
        return [
          if (!loading && error == null && rows.isEmpty)
            const Text('저장된 동의 내역이 없어요.'),
          for (final row in rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      row['consent_document'] is Map
                          ? '${row['consent_document']['title']}'
                          : '동의 문서',
                    ),
                    Text(
                      '${status(row['status'])} · ${row['consented_at'] ?? ''}',
                    ),
                    if (row['withdrawn_at'] != null)
                      Text('철회 일시 ${row['withdrawn_at']}'),
                    if (row['status'] == 'CONSENTED' && row['id'] is int)
                      OutlinedButton(
                        onPressed: disabled
                            ? null
                            : () async {
                                reason.clear();
                                final accepted = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('동의를 철회할까요?'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '필수 동의를 철회하면 일부 서비스 이용이 제한될 수 있어요.',
                                        ),
                                        TextField(
                                          controller: reason,
                                          maxLength: 500,
                                          decoration: const InputDecoration(
                                            labelText: '철회 사유',
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('돌아가기'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          if (reason.text.trim().isNotEmpty) {
                                            Navigator.pop(c, true);
                                          }
                                        },
                                        child: const Text('철회'),
                                      ),
                                    ],
                                  ),
                                );
                                if (accepted == true && mounted) {
                                  await write(
                                    () => api.withdraw(
                                      row['id'] as int,
                                      reason.text,
                                    ),
                                    '동의가 철회됐어요.',
                                  );
                                }
                              },
                        child: const Text('동의 철회'),
                      ),
                  ],
                ),
              ),
            ),
        ];
      case 'settings':
        return [
          ListenableBuilder(
            listenable: AppPreferences.instance,
            builder: (context, _) {
              final settings = AppPreferences.instance;
              Future<void> save(Future<void> Function() action) async {
                setState(() => saving = true);
                try {
                  await action();
                } catch (_) {
                  if (mounted) message('화면 설정을 저장하지 못했어요.');
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              }

              return Column(
                children: [
                  if (settings.error != null) Text(settings.error!),
                  SwitchListTile(
                    title: const Text('다크 모드'),
                    value: settings.dark,
                    onChanged: saving
                        ? null
                        : (v) => save(() => settings.save(dark: v)),
                  ),
                  SwitchListTile(
                    title: const Text('높은 대비'),
                    value: settings.highContrast,
                    onChanged: saving
                        ? null
                        : (v) => save(() => settings.save(highContrast: v)),
                  ),
                  SwitchListTile(
                    title: const Text('모션 줄이기'),
                    value: settings.reduceMotion,
                    onChanged: saving
                        ? null
                        : (v) => save(() => settings.save(reduceMotion: v)),
                  ),
                  const Text('글자 크기'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final scale in [1.0, 1.2, 1.5])
                        ChoiceChip(
                          label: Text('${(scale * 100).round()}%'),
                          selected: settings.textScale == scale,
                          onSelected: saving
                              ? null
                              : (_) =>
                                    save(() => settings.save(textScale: scale)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('설정은 이 기기에 저장돼요. 휴대폰의 글자 크기 설정도 함께 적용됩니다.'),
                ],
              );
            },
          ),
        ];
      default:
        return [];
    }
  }
}
