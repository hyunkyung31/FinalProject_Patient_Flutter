import 'package:flutter/material.dart';
import '../model/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});
  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onComplete();
    } catch (_) {
      if (mounted) setState(() => _error = '저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next(int index) {
    if (index == OnboardingPage.pages.length - 1) {
      _finish();
    } else {
      _controller.animateToPage(
        index + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF8FA),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    key: ValueKey('onboarding-skip-${_index + 1}'),
                    onPressed: _saving ? null : _finish,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(88, 48),
                    ),
                    child: const Text('건너뛰기'),
                  ),
                ),
              ),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _saving,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: OnboardingPage.pages.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) {
                      final page = OnboardingPage.pages[index];
                      return Semantics(
                        key: ValueKey('onboarding-page-${index + 1}'),
                        label:
                            '${index + 1} / ${OnboardingPage.pages.length}. ${page.title}. ${page.description}. 안내 이미지의 화면과 수치는 예시입니다.',
                        image: true,
                        child: Image.asset(
                          'assets/images/onboarding/${page.image}.png',
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      ),
                    FilledButton.icon(
                      key: ValueKey('onboarding-next-${_index + 1}'),
                      onPressed: _saving ? null : () => _next(_index),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded, size: 20),
                      iconAlignment: IconAlignment.end,
                      label: Text(
                        _saving
                            ? '저장 중…'
                            : _index == OnboardingPage.pages.length - 1
                            ? '시작하기'
                            : '다음',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
