import 'package:flutter/material.dart';

class MedicationImage extends StatelessWidget {
  const MedicationImage({super.key, this.imageUrl, this.size = 76});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final scheme = Theme.of(context).colorScheme;
    final hasImage = url != null && url.isNotEmpty;

    final image = Container(
      width: size * 0.97,
      height: size * 0.68,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _fallback(context),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.zoom_in_rounded,
                      size: 17,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            )
          : _fallback(context),
    );

    if (!hasImage) {
      return image;
    }

    return Semantics(
      button: true,
      label: '\uc57d\ud488 \uc774\ubbf8\uc9c0 \ud655\ub300',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showImageViewer(context, url),
        child: image,
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Center(
      child: Icon(
        Icons.medication_outlined,
        size: size * 0.42,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showImageViewer(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 48,
          ),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                  maxHeight: 620,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Padding(
                        padding: const EdgeInsets.all(48),
                        child: _fallback(context),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton.filledTonal(
                  tooltip: '\ub2eb\uae30',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
