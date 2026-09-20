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
      price: 0,
      isDefault: true,
    ),
    _StudioItem(
      name: '핑크 운동복',
      previewFile: 'shop_outfit_pink_training_set.png',
      painterFile: 'wear_outfit_pink_training_set.png',
      price: 250,
      rewardCode: 'BOMI_OUTFIT_PINK_TRAINING',
    ),
    _StudioItem(
      name: '토끼 후드티',
      previewFile: 'shop_outfit_blue_bunny_hoodie.png',
      painterFile: 'wear_outfit_blue_bunny_hoodie.png',
      price: 350,
      rewardCode: 'BOMI_OUTFIT_BLUE_BUNNY_HOODIE',
    ),
    _StudioItem(
      name: '노란 레인코트',
      previewFile: 'shop_outfit_yellow_raincoat.png',
      painterFile: 'wear_outfit_yellow_raincoat.png',
      price: 450,
      rewardCode: 'BOMI_OUTFIT_YELLOW_RAINCOAT',
    ),
  ];

  static const _accessories = <_StudioItem>[
    _StudioItem(name: '착용 안 함', price: 0, isDefault: true),
    _StudioItem(
      name: '하트 리본',
      previewFile: 'acc_heart_ribbon.png',
      painterFile: 'acc_heart_ribbon.png',
      price: 100,
      rewardCode: 'BOMI_ACC_HEART_RIBBON',
    ),
    _StudioItem(
      name: '새싹 모자',
      previewFile: 'acc_sprout_cap.png',
      painterFile: 'acc_sprout_cap.png',
      price: 180,
      rewardCode: 'BOMI_ACC_SPROUT_CAP',
    ),
    _StudioItem(
      name: '하트 선글라스',
      previewFile: 'acc_heart_sunglasses.png',
      painterFile: 'acc_heart_sunglasses.png',
      price: 250,
      rewardCode: 'BOMI_ACC_HEART_SUNGLASSES',
    ),
    _StudioItem(
      name: '새싹 머리핀',
      previewFile: 'acc_seed_hairpin_reward.png',
      painterFile: 'acc_seed_hairpin_reward.png',
      price: 0,
      rewardCode: 'BOMI_ACC_GROWTH_SEED_HAIRPIN',
      growthThreshold: 200,
    ),
    _StudioItem(
      name: '반짝 메달',
      previewFile: 'acc_shining_medal_reward.png',
      painterFile: 'acc_shining_medal_reward.png',
      price: 0,
      rewardCode: 'BOMI_ACC_GROWTH_SHINING_MEDAL',
      growthThreshold: 600,
    ),
    _StudioItem(
      name: '두근 마스터 배지',
      previewFile: 'acc_trophy_badge_reward.png',
      painterFile: 'acc_trophy_badge_reward.png',
      price: 0,
      rewardCode: 'BOMI_ACC_GROWTH_TROPHY_BADGE',
      growthThreshold: 3000,
    ),
  ];

  static const _backgrounds = <_StudioItem>[
    _StudioItem(
      name: '햇살 스튜디오',
      previewFile: 'bg_studio_default.png',
      painterFile: 'bg_studio_default.png',
      price: 0,
      isDefault: true,
    ),
    _StudioItem(
      name: '호숫가 공원',
      previewFile: 'bg_park_lakeside.png',
      painterFile: 'bg_park_lakeside.png',
      price: 500,
      rewardCode: 'BOMI_BG_PARK_LAKESIDE',
    ),
    _StudioItem(
      name: '두근 비치',
      previewFile: 'bg_beach_pastel.png',
      painterFile: 'bg_beach_pastel.png',
      price: 700,
      rewardCode: 'BOMI_BG_BEACH_PASTEL',
    ),
  ];

  Map<String, dynamic>? _manifest;
  Map<String, ui.Image>? _images;

  PointAccount? _account;
  RewardOverview? _overview;

  final Set<int> _redeemingRewardIds = {};

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
        _error = '보미 스튜디오를 불러오지 못했어요.\n$error';
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

    // 일반 구매 상품은 구매 전 미리보기까지만 허용한다.
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

  RewardCatalog? _availableRewardFor(_StudioItem item) {
    final rewardCode = item.rewardCode;
    if (rewardCode == null) return null;

    for (final reward in _overview?.available ?? const <RewardCatalog>[]) {
      if (reward.rewardCode == rewardCode) {
        return reward;
      }
    }

    return null;
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
    return item.isDefault || _acquiredRewardFor(item) != null;
  }

  int _displayPrice(_StudioItem item) {
    return _availableRewardFor(item)?.requiredPoints ?? item.price;
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

  Future<void> _purchase(_StudioItem item) async {
    final reward = _availableRewardFor(item);
    final account = _account;

    if (reward == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 아이템은 서버 배포가 완료된 뒤 구매할 수 있어요.')),
      );
      return;
    }

    if (account == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('포인트 정보를 확인할 수 없어요.')));
      return;
    }

    if (account.balance < reward.requiredPoints) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('보유 포인트가 부족해요.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('아이템 구매'),
          content: Text(
            '${reward.rewardName}\n\n'
            '${_points(reward.requiredPoints)}P를 사용해 구매할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('구매'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _redeemingRewardIds.add(reward.id);
    });

    try {
      final result = await widget.repository.redeemReward(
        rewardId: reward.id,
        idempotencyKey:
            'bomi-${reward.id}-${DateTime.now().microsecondsSinceEpoch}',
      );

      if (!mounted) return;

      _preview(item);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyProcessed
                ? '이미 보유하고 있는 아이템이에요.'
                : '${reward.rewardName} 구매가 완료됐어요!',
          ),
        ),
      );

      await _reloadRewardData();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(rewardErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _redeemingRewardIds.remove(reward.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FB),
      appBar: AppBar(
        title: const Text(
          '보미 스튜디오',
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
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
          AspectRatio(
            aspectRatio: 1,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 13),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: Color(0xFFFF789D),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${_level.title}와 함께 오늘도 건강한 하루를 만들어봐요.',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
        childAspectRatio: textScale >= 1.45 ? 0.70 : 0.80,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final availableReward = _availableRewardFor(item);
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
          catalogAvailable: item.isDefault || availableReward != null || owned,
          price: _displayPrice(item),
          purchasing:
              availableReward != null &&
              _redeemingRewardIds.contains(availableReward.id),
          onTap: () {
            _selectItem(item);
          },
          onPurchase: owned || item.isDefault || item.growthThreshold != null
              ? null
              : () => _purchase(item),
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
              '구매 아이템은 구매 전 미리보기로 확인할 수 있어요. '
              '성장 보상은 누적 포인트를 달성하면 무료로 자동 지급돼요. '
              '보유 아이템을 선택하면 장착 상태가 저장되어 다음에 '
              '스튜디오를 열 때 그대로 복원됩니다.',
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
    required this.price,
    this.previewFile,
    this.painterFile,
    this.rewardCode,
    this.growthThreshold,
    this.isDefault = false,
  });

  final String name;
  final int price;
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
    required this.catalogAvailable,
    required this.price,
    required this.purchasing,
    required this.onTap,
    this.onPurchase,
  });

  final _StudioItem item;
  final bool selected;
  final bool owned;
  final bool catalogAvailable;
  final int price;
  final bool purchasing;
  final VoidCallback onTap;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
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
              width: selected ? 2 : 1,
              color: selected
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
              if (item.isDefault)
                _statusRow(label: '기본 지급', color: const Color(0xFF4D9A72))
              else if (owned)
                _statusRow(
                  label: selected ? '보유 · 미리보기 중' : '보유 중',
                  color: const Color(0xFF4D9A72),
                )
              else if (item.growthThreshold != null)
                _growthRewardStatus(item)
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_points(price)} P',
                        style: const TextStyle(
                          color: Color(0xFFE85F88),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (!catalogAvailable)
                      const Text(
                        '배포 대기',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: FilledButton(
                    onPressed: !catalogAvailable || purchasing
                        ? null
                        : onPurchase,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: purchasing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(catalogAvailable ? '구매하기' : '준비 중'),
                  ),
                ),
              ],
              if (selected &&
                  !owned &&
                  !item.isDefault &&
                  item.growthThreshold == null) ...[
                const SizedBox(height: 5),
                const Text(
                  '미리보기 중',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE95F8A),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _growthRewardStatus(_StudioItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EBFF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '성장 보상',
            style: TextStyle(
              color: Color(0xFF7158A8),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 5),
        const Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: Color(0xFF7864AA),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            '${_points(item.growthThreshold!)}P 달성 시 무료',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7864AA),
              fontSize: 9,
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
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (selected)
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: Color(0xFFE95F8A),
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
