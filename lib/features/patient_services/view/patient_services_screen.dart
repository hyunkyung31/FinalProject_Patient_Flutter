import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../reservation/model/booking_options.dart';
import '../../reservation/repository/reservation_repository.dart';
import '../../verification/view/phone_verification_screen.dart';
import '../repository/patient_services_repository.dart';

class PatientServicesScreen extends StatefulWidget {
  const PatientServicesScreen({
    super.key,
    required this.repository,
    this.section = 'menu',
    this.embedded = false,
    this.patientName,
    this.onLogout,
  });
  final ReservationRepository repository;
  final String section;
  final bool embedded;
  final String? patientName;
  final Future<void> Function()? onLogout;
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
    if (widget.section == 'menu' ||
        widget.section == 'settings' ||
        widget.section == 'app_settings') {
      return;
    }
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
        onLogout: widget.onLogout,
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
      await write(() async {
        await api.requestLink(verification!.id);
        linkRequested = true;
      }, '연결 요청이 접수됐어요. 연결 상태를 다시 확인해 주세요.');
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
  Widget tile(String title, String sub, IconData icon, VoidCallback action) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: dark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x0A1E3A8A),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            sub,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: scheme.primary),
        onTap: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = {
      'menu': '내 정보 · 서비스',
      'profile': '환자정보',
      'link': '병원기록 연결',
      'changes': '정보 변경 요청',
      'documents': '약관 · 동의 문서',
      'consents': '내 동의 내역',
      'settings': '내 정보 · 설정',
    };
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(titles[widget.section] ?? '내 정보'),
              actions: [
                if (widget.section != 'menu' &&
                    widget.section != 'settings' &&
                    widget.section != 'app_settings')
                  IconButton(
                    tooltip: '새로고침',
                    onPressed: loading || saving ? null : () => _load(),
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
      body: SafeArea(
        top: !widget.embedded,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, widget.embedded ? 10 : 20, 20, 20),
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

  // 기존 '내 정보 · 서비스' 내용을 재사용 가능한 섹션으로 분리한다.
  // 하단 탭을 다시 분리하더라도 이 섹션을 그대로 사용할 수 있다.
  List<Widget> _buildMyInfoSection({
    bool includeSettingsShortcut = true,
    String summarySubtitle = '필요한 정보를 확인하고 관리해요.',
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return [
      Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? const [Color(0xFF1C3154), Color(0xFF17263E)]
                : const [Color(0xFFE8F2FF), Color(0xFFF5F8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.blue,
                size: 31,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName?.trim().isNotEmpty == true
                        ? '${widget.patientName!.trim()}님'
                        : '내 정보',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summarySubtitle,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      if (includeSettingsShortcut)
        tile(
          '\uC571 \uC124\uC815',
          '\uB2E4\uD06C \uBAA8\uB4DC \u00B7 \uB300\uBE44 \u00B7 \uAE00\uC790 \uD06C\uAE30',
          Icons.settings_outlined,
          () => open('app_settings'),
        ),
    ];
  }

  // 기존 화면 · 접근성 설정 기능도 독립 위젯으로 보존한다.
  // 추후 별도 설정 화면으로 다시 분리해도 이 위젯을 그대로 재사용할 수 있다.
  Widget _buildAccessibilitySettingsPanel() {
    return ListenableBuilder(
      listenable: AppPreferences.instance,
      builder: (context, _) {
        final settings = AppPreferences.instance;
        final scheme = Theme.of(context).colorScheme;

        Future<void> save(Future<void> Function() action) async {
          setState(() => saving = true);
          try {
            await action();
          } catch (_) {
            if (mounted) {
              message(
                '\uD654\uBA74 \uC124\uC815\uC744 \uC800\uC7A5\uD558\uC9C0 \uBABB\uD588\uC5B4\uC694.',
              );
            }
          } finally {
            if (mounted) setState(() => saving = false);
          }
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(
                  '\uD654\uBA74 \uC124\uC815',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SwitchListTile(
                secondary: Icon(
                  Icons.dark_mode_outlined,
                  color: scheme.primary,
                ),
                title: Text(
                  '\uB2E4\uD06C \uBAA8\uB4DC',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '\uB0AE\uC5D0\uB294 \uBC1D\uAC8C, \uBC24\uC5D0\uB294 \uC5B4\uB461\uAC8C \uD45C\uC2DC\uD574\uC694.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                value: settings.dark,
                onChanged: saving
                    ? null
                    : (value) => save(() => settings.save(dark: value)),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              SwitchListTile(
                secondary: Icon(Icons.contrast_outlined, color: scheme.primary),
                title: Text(
                  '\uB192\uC740 \uB300\uBE44',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '\uAE00\uC790\uC640 \uBC84\uD2BC\uC758 \uB300\uBE44\uB97C \uB192\uC5EC\uC694.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                value: settings.highContrast,
                onChanged: saving
                    ? null
                    : (value) => save(() => settings.save(highContrast: value)),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              SwitchListTile(
                secondary: Icon(
                  Icons.motion_photos_off_outlined,
                  color: scheme.primary,
                ),
                title: Text(
                  '\uBAA8\uC158 \uC904\uC774\uAE30',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '\uD654\uBA74 \uC804\uD658 \uD6A8\uACFC\uB97C \uC904\uC5EC\uC694.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                value: settings.reduceMotion,
                onChanged: saving
                    ? null
                    : (value) => save(() => settings.save(reduceMotion: value)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  '\uAE00\uC790 \uD06C\uAE30',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
              ),
              if (settings.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    settings.error!,
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> body() {
    final disabled = saving || loading || uncertain;
    switch (widget.section) {
      case 'menu':
        return _buildMyInfoSection();
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
        final pending =
            linkRequested || (request is Map && request['status'] == 'PENDING');
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
        return _buildMyInfoSection(
          summarySubtitle:
              '\uB0B4 \uC815\uBCF4\uC640 \uC571 \uC0AC\uC6A9 \uD658\uACBD\uC744 \uAD00\uB9AC\uD574\uC694.',
        );
      case 'app_settings':
        final scheme = Theme.of(context).colorScheme;
        return [
          _buildAccessibilitySettingsPanel(),
          const SizedBox(height: 24),
          if (widget.onLogout != null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      final accepted = await confirm(
                        '\uB85C\uADF8\uC544\uC6C3\uD560\uAE4C\uC694?',
                        '\uD604\uC7AC \uACC4\uC815\uC5D0\uC11C \uB85C\uADF8\uC544\uC6C3\uB429\uB2C8\uB2E4.',
                      );
                      if (accepted && mounted) {
                        await widget.onLogout!.call();
                      }
                    },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('\uB85C\uADF8\uC544\uC6C3'),
            ),
        ];
      default:
        return [];
    }
  }
}
