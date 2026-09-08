import 'package:flutter/material.dart';
import '../model/onboarding_page.dart';
import '../widgets/onboarding_scene.dart';
import '../../../core/theme/app_colors.dart';

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
                      return AnimatedBuilder(
                        animation: _controller,
                        child: OnboardingScene(
                          key: ValueKey('onboarding-page-${index + 1}'),
                          index: index,
                          active: _index == index && !_saving,
                        ),
                        builder: (context, child) {
                          final current =
                              _controller.hasClients &&
                                  _controller.position.haveDimensions
                              ? (_controller.page ?? _index.toDouble())
                              : _index.toDouble();
                          final distance = (current - index).abs().clamp(
                            0.0,
                            1.0,
                          );
                          final reduced = MediaQuery.disableAnimationsOf(
                            context,
                          );
                          return Opacity(
                            opacity: reduced ? 1 : 1 - distance * 0.7,
                            child: Transform.translate(
                              offset: Offset(0, reduced ? 0 : distance * 16),
                              child: child,
                            ),
                          );
                        },
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
                    Semantics(
                      label: '전체 7단계 중 ${_index + 1}단계',
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (
                              var i = 0;
                              i < OnboardingPage.pages.length;
                              i++
                            )
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: i == _index ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: i == _index
                                      ? AppColors.navy
                                      : AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
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
