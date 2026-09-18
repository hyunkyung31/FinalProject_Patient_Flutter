import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../repository/patient_services_repository.dart';

class RequiredConsentScreen extends StatefulWidget {
  const RequiredConsentScreen({
    super.key,
    required this.documents,
    required this.repository,
    required this.onCompleted,
    required this.onLogout,
  });

  final List<Map<String, dynamic>> documents;
  final PatientServicesRepository repository;
  final Future<void> Function() onCompleted;
  final VoidCallback onLogout;

  @override
  State<RequiredConsentScreen> createState() => _RequiredConsentScreenState();
}

class _RequiredConsentScreenState extends State<RequiredConsentScreen> {
  final selected = <int>{};
  final _uuid = const Uuid();
  final _idempotencyKeys = <int, String>{};
  bool saving = false;
  String? error;

  Future<void> submit() async {
    if (saving || selected.length != widget.documents.length) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      for (final document in widget.documents) {
        final documentId = document['id'] as int;
        await widget.repository.consentWithIdempotency(
          documentId,
          idempotencyKey: _idempotencyKeys.putIfAbsent(documentId, _uuid.v4),
        );
      }
      if (!mounted) return;
      await widget.onCompleted();
    } catch (e) {
      if (mounted) setState(() => error = patientServiceError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('필수 약관 동의'),
      actions: [
        TextButton(
          onPressed: saving ? null : widget.onLogout,
          child: const Text('로그아웃'),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '서비스 이용을 위해 필수 약관에 동의해 주세요.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            '예약·진료 관련 안내는 서비스 이용에 필요한 알림입니다. 마케팅 정보 수신 동의와는 별도로 관리됩니다.',
          ),
          const SizedBox(height: 16),
          for (final document in widget.documents)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      document['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('버전 ${document['version'] ?? '-'} · 필수'),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          document['content_text'] as String,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selected.contains(document['id']),
                      onChanged: saving
                          ? null
                          : (checked) => setState(() {
                              if (checked == true) {
                                selected.add(document['id'] as int);
                              } else {
                                selected.remove(document['id']);
                              }
                            }),
                      title: const Text('내용을 확인했고 동의합니다.'),
                    ),
                  ],
                ),
              ),
            ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: saving || selected.length != widget.documents.length
                ? null
                : submit,
            child: saving
                ? const CircularProgressIndicator()
                : const Text('필수 약관에 동의하고 시작하기'),
          ),
        ],
      ),
    ),
  );
}
