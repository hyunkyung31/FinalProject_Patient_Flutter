import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../repository/patient_report_repository.dart';

class PatientCctaImage extends StatefulWidget {
  const PatientCctaImage({
    super.key,
    required this.repository,
    required this.resultId,
  });

  final PatientReportRepository repository;
  final int resultId;

  @override
  State<PatientCctaImage> createState() => _PatientCctaImageState();
}

class _PatientCctaImageState extends State<PatientCctaImage> {
  late Future<_CctaImages> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant PatientCctaImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.resultId != widget.resultId) {
      _future = _load();
    }
  }

  Future<_CctaImages> _load() async {
    Future<Uint8List?> loadImage(String kind) async {
      try {
        return await widget.repository.getProtectedImage(
          '/api/patient/results/${widget.resultId}/ccta/$kind/',
        );
      } catch (_) {
        return null;
      }
    }

    final overlay = await loadImage('overlay');

    return _CctaImages(overlay: overlay);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CctaImages>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final images = snapshot.data;

        if (images == null || images.overlay == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.025),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.image_not_supported_outlined, size: 19),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '공개된 CT 이미지를 불러올 수 없습니다.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }

        return _CctaImageCard(title: '석회화 의심 위치', bytes: images.overlay!);
      },
    );
  }
}

class _CctaImageCard extends StatelessWidget {
  const _CctaImageCard({required this.title, required this.bytes});

  final String title;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _CctaImages {
  const _CctaImages({this.overlay});

  final Uint8List? overlay;
}
