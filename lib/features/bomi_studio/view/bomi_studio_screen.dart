import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../reward/model/reward.dart';
import '../../reward/repository/reward_repository.dart';
import '../repository/bomi_studio_repository.dart';
import '../widgets/bomi_fitted_painter.dart';

class BomiStudioScreen extends StatefulWidget {
  const BomiStudioScreen({
    super.key,
    required this.repository,
    required this.equipmentRepository,
  });

  final RewardRepository repository;
  final BomiStudioRepository equipmentRepository;

  @override
  State<BomiStudioScreen> createState() => _BomiStudioScreenState();
}

class _BomiStudioScreenState extends State<BomiStudioScreen> {
  static const _assetRoot = 'assets/images/bomi/studio/';

  static const _runtimeAssets = <String>[
    'bomi_base_default.png',
    'wear_outfit_basic_homewear.png',
    'wear_outfit_pink_training_set.png',
    'wear_outfit_blue_bunny_hoodie.png',
    'wear_outfit_yellow_raincoat.png',
    'acc_heart_ribbon.png',
    'acc_sprout_cap.png',
    'acc_heart_sunglasses.png',
    'acc_seed_hairpin_reward.png',
    'acc_shining_medal_reward.png',
    'acc_trophy_badge_reward.png',
    'bg_studio_default.png',
    'bg_park_lakeside.png',
    'bg_beach_pastel.png',
    'shop_outfit_pink_training_set.png',
    'shop_outfit_blue_bunny_hoodie.png',
    'shop_outfit_yellow_raincoat.png',
  ];

  static const _outfits = <_StudioItem>[
    _StudioItem(
      name: '기본 홈웨어',
      previewFile: 'wear_outfit_basic_homewear.png',
      painterFile: 'wear_outfit_basic_homewear.png',
      isDefault: true,
    ),
    _StudioItem(
      name: '핑크 운동복',
      previewFile: 'shop_outfit_pink_training_set.png',
      painterFile: 'wear_outfit_pink_training_set.png',
      rewardCode: 'BOMI_OUTFIT_PINK_TRAINING',
      growthThreshold: 0,
    ),
    _StudioItem(
      name: '토끼 후드티',
      previewFile: 'shop_outfit_blue_bunny_hoodie.png',
      painterFile: 'wear_outfit_blue_bunny_hoodie.png',
      rewardCode: 'BOMI_OUTFIT_BLUE_BUNNY_HOODIE',
      growthThreshold: 40,
    ),
    _StudioItem(
      name: '노란 레인코트',
      previewFile: 'shop_outfit_yellow_raincoat.png',
      painterFile: 'wear_outfit_yellow_raincoat.png',
      rewardCode: 'BOMI_OUTFIT_YELLOW_RAINCOAT',
      growthThreshold: 80,
    ),
  ];

  static const _accessories = <_StudioItem>[
    _StudioItem(name: '착용 안 함', isDefault: true),
    _StudioItem(
      name: '하트 리본',
      previewFile: 'acc_heart_ribbon.png',
      painterFile: 'acc_heart_ribbon.png',
      rewardCode: 'BOMI_ACC_HEART_RIBBON',
      growthThreshold: 0,
    ),
    _StudioItem(
      name: '새싹 모자',
      previewFile: 'acc_sprout_cap.png',
      painterFile: 'acc_sprout_cap.png',
      rewardCode: 'BOMI_ACC_SPROUT_CAP',
      growthThreshold: 20,
    ),
    _StudioItem(
      name: '하트 선글라스',
      previewFile: 'acc_heart_sunglasses.png',
      painterFile: 'acc_heart_sunglasses.png',
      rewardCode: 'BOMI_ACC_HEART_SUNGLASSES',
      growthThreshold: 60,
    ),
    _StudioItem(
      name: '새싹 머리핀',
      previewFile: 'acc_seed_hairpin_reward.png',
      painterFile: 'acc_seed_hairpin_reward.png',
      rewardCode: 'BOMI_ACC_GROWTH_SEED_HAIRPIN',
      growthThreshold: 200,
    ),
    _StudioItem(
      name: '반짝 메달',
      previewFile: 'acc_shining_medal_reward.png',
      painterFile: 'acc_shining_medal_reward.png',
      rewardCode: 'BOMI_ACC_GROWTH_SHINING_MEDAL',
      growthThreshold: 600,
    ),
    _StudioItem(
      name: '두근 마스터 배지',
      previewFile: 'acc_trophy_badge_reward.png',
      painterFile: 'acc_trophy_badge_reward.png',
      rewardCode: 'BOMI_ACC_GROWTH_TROPHY_BADGE',
      growthThreshold: 3000,
    ),
  ];

  static const _backgrounds = <_StudioItem>[
    _StudioItem(
      name: '햇살 스튜디오',
      previewFile: 'bg_studio_default.png',
      painterFile: 'bg_studio_default.png',
      isDefault: true,
    ),
    _StudioItem(
      name: '호숫가 공원',
      previewFile: 'bg_park_lakeside.png',
      painterFile: 'bg_park_lakeside.png',
      rewardCode: 'BOMI_BG_PARK_LAKESIDE',
      growthThreshold: 100,
    ),
    _StudioItem(
      name: '두근 비치',
      previewFile: 'bg_beach_pastel.png',
      painterFile: 'bg_beach_pastel.png',
      rewardCode: 'BOMI_BG_BEACH_PASTEL',
      growthThreshold: 150,
    ),
  ];

  Map<String, dynamic>? _manifest;
  Map<String, ui.Image>? _images;

  PointAccount? _account;
  RewardOverview? _overview;

  bool _equipmentSyncAvailable = true;
  bool _savingEquipment = false;

  bool _loading = true;
  String? _error;
  String? _rewardLoadError;

  var _category = _StudioCategory.outfit;

  String _outfit = 'wear_outfit_basic_homewear.png';
  String? _accessory;
  String _background = 'bg_studio_default.png';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _rewardLoadError = null;
    });

    try {
      final manifestText = await rootBundle.loadString(
        '${_assetRoot}bomi_asset_manifest.json',
      );

      final manifest = Map<String, dynamic>.from(
        jsonDecode(manifestText) as Map,
      );

      final imageEntries = await Future.wait(
        _runtimeAssets.map((name) async {
          return MapEntry(name, await _loadImage(name));
        }),
      );

      if (!mounted) return;

      setState(() {
        _manifest = manifest;
        _images = Map<String, ui.Image>.fromEntries(imageEntries);
      });

      await _reloadRewardData();
      await _loadEquipment();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = '보미 꾸미기를 불러오지 못했어요.\n$error';
      });
    }
  }

  Future<void> _reloadRewardData() async {
    PointAccount? account;
    RewardOverview? overview;
    String? rewardLoadError;

    try {
      account = await widget.repository.getPointAccount();
    } catch (error) {
      rewardLoadError = rewardErrorMessage(error);
    }

    try {
      overview = await widget.repository.getRewards();
    } catch (error) {
      rewardLoadError ??= rewardErrorMessage(error);
    }

    if (!mounted) return;

    setState(() {
      _account = account;
      _overview = overview;
      _rewardLoadError = rewardLoadError;
    });
  }

  Future<void> _loadEquipment() async {
    try {
      final equipment = await widget.equipmentRepository.getEquipment();

      if (!mounted) return;

      setState(() {
        _equipmentSyncAvailable = true;

        _outfit = _outfitFileFor(equipment.outfitRewardCode);
        _accessory = _accessoryFileFor(equipment.accessoryRewardCode);
        _background = _backgroundFileFor(equipment.backgroundRewardCode);
      });
    } catch (_) {
      if (!mounted) return;

      // 배포 서버에 API가 아직 없어도 스튜디오 미리보기는 유지한다.
      setState(() {
        _equipmentSyncAvailable = false;
      });
    }
  }

  String _outfitFileFor(String? rewardCode) {
    return switch (rewardCode) {
      'BOMI_OUTFIT_PINK_TRAINING' => 'wear_outfit_pink_training_set.png',
      'BOMI_OUTFIT_BLUE_BUNNY_HOODIE' => 'wear_outfit_blue_bunny_hoodie.png',
      'BOMI_OUTFIT_YELLOW_RAINCOAT' => 'wear_outfit_yellow_raincoat.png',
      _ => 'wear_outfit_basic_homewear.png',
    };
  }

  String? _accessoryFileFor(String? rewardCode) {
    return switch (rewardCode) {
      'BOMI_ACC_HEART_RIBBON' => 'acc_heart_ribbon.png',
      'BOMI_ACC_SPROUT_CAP' => 'acc_sprout_cap.png',
      'BOMI_ACC_HEART_SUNGLASSES' => 'acc_heart_sunglasses.png',
      'BOMI_ACC_GROWTH_SEED_HAIRPIN' => 'acc_seed_hairpin_reward.png',
      'BOMI_ACC_GROWTH_SHINING_MEDAL' => 'acc_shining_medal_reward.png',
      'BOMI_ACC_GROWTH_TROPHY_BADGE' => 'acc_trophy_badge_reward.png',
      _ => null,
    };
  }

  String _backgroundFileFor(String? rewardCode) {
    return switch (rewardCode) {
      'BOMI_BG_PARK_LAKESIDE' => 'bg_park_lakeside.png',
      'BOMI_BG_BEACH_PASTEL' => 'bg_beach_pastel.png',
      _ => 'bg_studio_default.png',
    };
  }

  Future<void> _selectItem(_StudioItem item) async {
    final owned = _isOwned(item);

    // 성장 보상은 달성 전에는 미리 착용하지 않는다.
    if (item.growthThreshold != null && !owned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '누적 ${_points(item.growthThreshold!)}P를 달성하면 '
            '무료로 받을 수 있어요.',
          ),
        ),
      );
      return;
    }

    _preview(item);

    // 해금되지 않은 아이템은 장착하지 않는다.
    if (!owned) {
      return;
    }

    // 배포 서버에 아직 장착 API가 없으면 로컬 미리보기만 유지한다.
    if (!_equipmentSyncAvailable) {
      return;
    }

    await _saveEquipmentSelection(item);
  }

  Future<void> _saveEquipmentSelection(_StudioItem item) async {
    if (_savingEquipment) return;

    final changes = <String, dynamic>{};

    switch (_category) {
      case _StudioCategory.outfit:
        changes['outfit_reward_code'] = item.isDefault ? null : item.rewardCode;

      case _StudioCategory.accessory:
        changes['accessory_reward_code'] = item.isDefault
            ? null
            : item.rewardCode;

      case _StudioCategory.background:
        changes['background_reward_code'] = item.isDefault
            ? null
            : item.rewardCode;
    }

    setState(() {
      _savingEquipment = true;
    });

    try {
      final equipment = await widget.equipmentRepository.updateEquipment(
        changes,
      );

      if (!mounted) return;

      // 서버가 반환한 최종 상태를 다시 화면에 반영한다.
      setState(() {
        _equipmentSyncAvailable = true;

        _outfit = _outfitFileFor(equipment.outfitRewardCode);
        _accessory = _accessoryFileFor(equipment.accessoryRewardCode);
        _background = _backgroundFileFor(equipment.backgroundRewardCode);
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(bomiStudioErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _savingEquipment = false;
        });
      }
    }
  }

  Future<ui.Image> _loadImage(String name) async {
    final data = await rootBundle.load('$_assetRoot$name');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  BomiLevel get _level {
    return BomiLevel.fromTotalEarned(_account?.totalEarned ?? 0);
  }

  List<_StudioItem> get _currentItems {
    return switch (_category) {
      _StudioCategory.outfit => _outfits,
      _StudioCategory.accessory => _accessories,
      _StudioCategory.background => _backgrounds,
    };
  }

  String? get _currentSelection {
    return switch (_category) {
      _StudioCategory.outfit => _outfit,
      _StudioCategory.accessory => _accessory,
      _StudioCategory.background => _background,
    };
  }

  PatientReward? _acquiredRewardFor(_StudioItem item) {
    final rewardCode = item.rewardCode;
    if (rewardCode == null) return null;

    for (final reward in _overview?.acquired ?? const <PatientReward>[]) {
      if (reward.status.toUpperCase() == 'EXPIRED') {
        continue;
      }

      if (reward.reward?.rewardCode == rewardCode) {
        return reward;
      }
    }

    return null;
  }

  bool _isOwned(_StudioItem item) {
    if (item.isDefault || _acquiredRewardFor(item) != null) {
      return true;
    }

    final threshold = item.growthThreshold;
    if (threshold == null) {
      return false;
    }

    // 포인트를 소비하지 않고 누적 건강활동 포인트로 아이템을 해금한다.
    return (_account?.totalEarned ?? 0) >= threshold;
  }

  void _preview(_StudioItem item) {
    setState(() {
      switch (_category) {
        case _StudioCategory.outfit:
          _outfit = item.painterFile ?? _outfit;

        case _StudioCategory.accessory:
          _accessory = item.painterFile;

        case _StudioCategory.background:
          _background = item.painterFile ?? _background;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FB),
      appBar: AppBar(
        title: const Text(
          '보미 꾸미기',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFFFFF9FB),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _manifest == null || _images == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 48,
                color: AppColors.mutedText,
              ),
              const SizedBox(height: 12),
              Text(
                _error ?? '스튜디오 데이터를 확인할 수 없어요.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, textScale >= 1.45 ? 36 : 24),
        children: [
          _buildGrowthCard(),
          if (_rewardLoadError != null) ...[
            const SizedBox(height: 10),
            _buildRewardWarning(),
          ],
          const SizedBox(height: 14),
          _buildStudioStage(),
          const SizedBox(height: 16),
          _buildCategoryTabs(),
          const SizedBox(height: 14),
          _buildItemGrid(),
          const SizedBox(height: 12),
          _buildGuideCard(),
        ],
      ),
    );
  }

  Widget _buildRewardWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFB26A26),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _rewardLoadError!,
              style: const TextStyle(
                color: Color(0xFF8B5A2B),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthCard() {
    final level = _level;
    final balance = _account?.balance;
    final totalEarned = _account?.totalEarned;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEAF0), Color(0xFFFFF5E9), Color(0xFFF0EBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD7E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lv.${level.level} ${level.title}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalEarned == null
                          ? '포인트 정보를 불러오면 성장 상태가 표시돼요.'
                          : '누적 ${_points(totalEarned)}P로 보미가 성장해요.',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 17,
                      color: Color(0xFFFF6E9C),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      balance == null ? '-- P' : '${_points(balance)} P',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: level.progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.82),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF7EA7)),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              level.nextLabel,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioStage() {
    final totalEarned = _account?.totalEarned ?? 0;

    final allItems = <_StudioItem>[
      ..._outfits,
      ..._accessories,
      ..._backgrounds,
    ];

    final upcomingItems =
        allItems
            .where(
              (item) =>
                  !item.isDefault &&
                  item.growthThreshold != null &&
                  item.growthThreshold! > totalEarned,
            )
            .toList()
          ..sort((a, b) => a.growthThreshold!.compareTo(b.growthThreshold!));

    final nextItem = upcomingItems.isEmpty ? null : upcomingItems.first;

    final nextThreshold = nextItem?.growthThreshold;
    final remainingPoints = nextThreshold == null
        ? 0
        : (nextThreshold - totalEarned).clamp(0, nextThreshold);

    final nextProgress = nextThreshold == null || nextThreshold == 0
        ? 1.0
        : (totalEarned / nextThreshold).clamp(0.0, 1.0).toDouble();

    String? selectedItemName;

    for (final item in _currentItems) {
      final selected =
          item.painterFile == _currentSelection ||
          (_category == _StudioCategory.accessory &&
              item.painterFile == null &&
              _currentSelection == null);

      if (selected) {
        selectedItemName = item.name;
        break;
      }
    }

    String speechText;

    // 첫 진입과 선택한 아이템에 따라 보미가 직접 반응한다.
    if (totalEarned == 0 && selectedItemName == '기본 홈웨어') {
      speechText = '오늘도 만나서 반가워요! 같이 꾸며볼까요? 💗';
    } else if (selectedItemName == '핑크 운동복') {
      speechText = '핑크 운동복 어때요? 산뜻하죠? 💕';
    } else if (selectedItemName == '토끼 후드티') {
      speechText = '토끼 후드라니! 오늘 더 귀여워졌어요 🐰';
    } else if (selectedItemName == '노란 레인코트') {
      speechText = '노란 레인코트 입고 같이 산책하고 싶어요 ☔';
    } else if (selectedItemName == '하트 리본') {
      speechText = '하트 리본이 정말 마음에 들어요! 🎀';
    } else if (selectedItemName == '새싹 모자') {
      speechText = '새싹이 쏙! 보미가 한 뼘 더 자란 것 같아요 🌱';
    } else if (selectedItemName == '하트 선글라스') {
      speechText = '짜잔! 오늘 보미 조금 멋져 보이나요? 😎';
    } else if (selectedItemName == '호숫가 공원') {
      speechText = '공원 바람이 좋아요. 같이 걸어볼까요? 🌿';
    } else if (selectedItemName == '두근 비치') {
      speechText = '바다다! 오늘은 여기서 쉬어가요 🏖️';
    } else if (nextItem != null &&
        remainingPoints > 0 &&
        remainingPoints <= 20 &&
        totalEarned > 0) {
      speechText = '조금만 더 하면 ${nextItem.name}도 만날 수 있어요 ✨';
    } else {
      switch (_category) {
        case _StudioCategory.outfit:
          speechText = '오늘은 어떤 옷을 입어볼까요?';

        case _StudioCategory.accessory:
          speechText = '보미에게 어울리는 소품을 골라주세요!';

        case _StudioCategory.background:
          speechText = '오늘은 어디에서 함께할까요?';
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFAFC), Color(0xFFF8F5FF), Color(0xFFF4FAFF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFDDE7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 13,
                        color: Color(0xFFFF6E9C),
                      ),
                      SizedBox(width: 5),
                      Text(
                        '오늘의 보미',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0D8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '🎁 스타터 선물 2개',
                    style: TextStyle(
                      color: Color(0xFF8A6530),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 보미와 말풍선을 같은 화면 안에 배치한다.
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: BomiFittedPainter(
                      images: _images!,
                      manifest: _manifest!,
                      outfit: _outfit,
                      accessory: _accessory,
                      background: _background,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),

                const Positioned(
                  left: 18,
                  bottom: 54,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 17,
                    color: Color(0x55FF87AA),
                  ),
                ),

                const Positioned(
                  right: 24,
                  bottom: 80,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: Color(0x669783D5),
                  ),
                ),

                Positioned(
                  top: 28,
                  right: 12,
                  width: 190,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.96,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      key: ValueKey(speechText),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(color: const Color(0xFFFFD9E5)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            speechText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 11.5,
                              height: 1.4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(27, -2),
                          child: Transform.rotate(
                            angle: 0.78,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  right: BorderSide(color: Color(0xFFFFD9E5)),
                                  bottom: BorderSide(color: Color(0xFFFFD9E5)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEFE7F5)),
            ),
            child: nextItem == null
                ? const Row(
                    children: [
                      Icon(
                        Icons.celebration_rounded,
                        size: 18,
                        color: Color(0xFFFF7EA7),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '현재 준비된 꾸미기 보상을 모두 만났어요!',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard_rounded,
                            size: 17,
                            color: Color(0xFF8B72C9),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '다음 선물 · ${nextItem.name}',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${_points(totalEarned)} / '
                            '${_points(nextThreshold!)}P',
                            style: const TextStyle(
                              color: Color(0xFF7158A8),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: nextProgress,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFF1ECF8),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFA38AD7),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Row(
      children: [
        Expanded(
          child: _CategoryButton(
            icon: Icons.checkroom_rounded,
            label: '의상',
            selected: _category == _StudioCategory.outfit,
            onTap: () {
              setState(() => _category = _StudioCategory.outfit);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CategoryButton(
            icon: Icons.face_retouching_natural_rounded,
            label: '액세서리',
            selected: _category == _StudioCategory.accessory,
            onTap: () {
              setState(() => _category = _StudioCategory.accessory);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CategoryButton(
            icon: Icons.landscape_rounded,
            label: '배경',
            selected: _category == _StudioCategory.background,
            onTap: () {
              setState(() => _category = _StudioCategory.background);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemGrid() {
    final items = _currentItems;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: textScale >= 1.45 ? 0.78 : 0.92,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final owned = _isOwned(item);

        final selected =
            item.painterFile == _currentSelection ||
            (_category == _StudioCategory.accessory &&
                item.painterFile == null &&
                _accessory == null);

        return _StudioItemCard(
          item: item,
          selected: selected,
          owned: owned,
          onTap: () => _selectItem(item),
        );
      },
    );
  }

  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 19, color: Color(0xFF7D67B5)),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              '모든 꾸미기 아이템은 건강 활동으로 누적 포인트를 달성하면 자동으로 해금돼요. '
              '누적 포인트는 소모되지 않고 보미 성장과 아이템 해금 기준으로 사용돼요. '
              '해금된 아이템을 선택하면 장착 상태가 저장되어 다음에도 그대로 유지됩니다.',
              style: TextStyle(
                color: AppColors.mutedText,
                height: 1.45,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StudioCategory { outfit, accessory, background }

class _StudioItem {
  const _StudioItem({
    required this.name,
    this.previewFile,
    this.painterFile,
    this.rewardCode,
    this.growthThreshold,
    this.isDefault = false,
  });

  final String name;
  final String? previewFile;
  final String? painterFile;
  final String? rewardCode;
  final int? growthThreshold;
  final bool isDefault;
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFE4EC) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFF9AB7)
                  : const Color(0xFFE7EAF0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: selected ? const Color(0xFFE95F8A) : AppColors.mutedText,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? const Color(0xFFD84E7A) : AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudioItemCard extends StatelessWidget {
  const _StudioItemCard({
    required this.item,
    required this.selected,
    required this.owned,
    required this.onTap,
  });

  final _StudioItem item;
  final bool selected;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final starterGift = !item.isDefault && item.growthThreshold == 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: selected && owned ? 2 : 1,
              color: selected && owned
                  ? const Color(0xFFFF84A8)
                  : const Color(0xFFE9EBF0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: owned ? 1 : 0.45,
                        child: item.previewFile == null
                            ? const Center(
                                child: Icon(
                                  Icons.block_rounded,
                                  size: 34,
                                  color: Color(0xFFB9BBC5),
                                ),
                              )
                            : Image.asset(
                                'assets/images/bomi/studio/'
                                '${item.previewFile}',
                                fit: BoxFit.contain,
                              ),
                      ),
                      if (starterGift)
                        Positioned(
                          left: 7,
                          top: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0CF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '🎁 선물',
                              style: TextStyle(
                                color: Color(0xFF8A6530),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      if (!owned)
                        const Positioned(
                          right: 8,
                          top: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: Color(0xFF8B7DA8),
                              ),
                            ),
                          ),
                        ),
                      if (selected && owned)
                        const Positioned(
                          right: 7,
                          bottom: 7,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFFF84A8),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              if (selected && owned)
                _statusRow(label: '장착 중', color: const Color(0xFFE95F8A))
              else if (item.isDefault)
                _statusRow(label: '기본 지급', color: const Color(0xFF4D9A72))
              else if (starterGift)
                _statusRow(label: '스타터 선물', color: const Color(0xFFB7792D))
              else if (owned)
                _statusRow(label: '해금 완료', color: const Color(0xFF4D9A72))
              else
                _unlockStatus(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unlockStatus(_StudioItem item) {
    final threshold = item.growthThreshold;

    if (threshold == null) {
      return const Text(
        '아직 준비 중이에요',
        style: TextStyle(
          color: Color(0xFF8B7DA8),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    final longTermReward = threshold >= 200;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          longTermReward
              ? Icons.workspace_premium_rounded
              : Icons.card_giftcard_rounded,
          size: 12,
          color: const Color(0xFF7158A8),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            longTermReward
                ? '성장 보상 · ${_points(threshold)}P'
                : '${_points(threshold)}P에 자동 선물',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7158A8),
              fontSize: 9,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusRow({required String label, required Color color}) {
    return Row(
      children: [
        Icon(
          label == '장착 중'
              ? Icons.check_circle_rounded
              : label == '스타터 선물'
              ? Icons.card_giftcard_rounded
              : Icons.auto_awesome_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class BomiLevel {
  const BomiLevel({
    required this.level,
    required this.title,
    required this.progress,
    required this.nextLabel,
  });

  final int level;
  final String title;
  final double progress;
  final String nextLabel;

  factory BomiLevel.fromTotalEarned(int total) {
    if (total >= 3000) {
      return const BomiLevel(
        level: 5,
        title: '두근 마스터 보미',
        progress: 1,
        nextLabel: '최고 레벨 달성!',
      );
    }

    if (total >= 1400) {
      return BomiLevel(
        level: 4,
        title: '건강지킴이 보미',
        progress: (total - 1400) / (3000 - 1400),
        nextLabel: '${_points(total)} / 3,000P',
      );
    }

    if (total >= 600) {
      return BomiLevel(
        level: 3,
        title: '활기찬 보미',
        progress: (total - 600) / (1400 - 600),
        nextLabel: '${_points(total)} / 1,400P',
      );
    }

    if (total >= 200) {
      return BomiLevel(
        level: 2,
        title: '씩씩한 보미',
        progress: (total - 200) / (600 - 200),
        nextLabel: '${_points(total)} / 600P',
      );
    }

    return BomiLevel(
      level: 1,
      title: '새싹 보미',
      progress: total / 200,
      nextLabel: '${_points(total)} / 200P',
    );
  }
}

String _points(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}
