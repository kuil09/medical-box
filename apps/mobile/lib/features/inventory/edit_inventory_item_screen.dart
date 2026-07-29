import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/api/api_client.dart';
import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../services/medicine_ocr_service.dart';
import '../../theme.dart';
import 'drug_catalog_projection_sections.dart';

class EditInventoryItemScreen extends ConsumerStatefulWidget {
  const EditInventoryItemScreen({this.itemId, this.containerId, super.key});

  final String? itemId;
  final String? containerId;

  @override
  ConsumerState<EditInventoryItemScreen> createState() =>
      _EditInventoryItemScreenState();
}

class _EditInventoryItemScreenState
    extends ConsumerState<EditInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _makerController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _storageController = TextEditingController();
  final _notesController = TextEditingController();
  Timer? _searchTimer;
  List<DrugSummary> _results = const [];
  String? _itemSeq;
  String? _ingredientSummary;
  String? _identificationVariantKey;
  String? _officialImageUrl;
  String? _appearanceSummary;
  DateTime? _expiresOn;
  String? _containerId;
  bool _searching = false;
  bool _scanning = false;
  bool _saving = false;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _containerId = widget.containerId;
    if (widget.itemId != null) {
      Future<void>(_loadItem);
    }
  }

  Future<void> _loadItem() async {
    final database = ref.read(databaseProvider);
    final item = await (database.select(
      database.inventoryItems,
    )..where((row) => row.id.equals(widget.itemId!))).getSingleOrNull();
    if (item == null || !mounted) return;
    setState(() {
      _nameController.text = item.productName;
      _makerController.text = item.manufacturer ?? '';
      _quantityController.text = item.quantity.toString();
      _storageController.text = item.storageNote ?? '';
      _notesController.text = item.privateNote ?? '';
      _itemSeq = item.itemSeq;
      _ingredientSummary = item.ingredientSummary;
      _identificationVariantKey = item.identificationVariantKey;
      _officialImageUrl = item.officialImageUrl;
      _appearanceSummary = item.appearanceSummary;
      _expiresOn = item.expiresOn;
      _containerId = item.containerId;
    });
  }

  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    final generation = ++_searchGeneration;
    final normalizedQuery = query.trim();
    setState(() {
      _itemSeq = null;
      _ingredientSummary = null;
      _identificationVariantKey = null;
      _officialImageUrl = null;
      _appearanceSummary = null;
      _results = const [];
      _searching = false;
    });
    if (normalizedQuery.length < 2) return;

    _searchTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted ||
          generation != _searchGeneration ||
          _nameController.text.trim() != normalizedQuery) {
        return;
      }
      setState(() => _searching = true);
      try {
        final results = await ref
            .read(catalogRepositoryProvider)
            .search(normalizedQuery);
        if (mounted &&
            generation == _searchGeneration &&
            _nameController.text.trim() == normalizedQuery) {
          setState(() => _results = results);
        }
      } catch (error) {
        if (mounted &&
            generation == _searchGeneration &&
            _nameController.text.trim() == normalizedQuery) {
          setState(() => _results = const []);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_catalogErrorMessage(error)),
              action: _isCatalogAccessError(error)
                  ? SnackBarAction(
                      label: '계정 확인',
                      onPressed: () => context.push('/login'),
                    )
                  : null,
            ),
          );
        }
      } finally {
        if (mounted &&
            generation == _searchGeneration &&
            _nameController.text.trim() == normalizedQuery) {
          setState(() => _searching = false);
        }
      }
    });
  }

  Future<void> _scanMedicine() async {
    final repository = ref.read(authRepositoryProvider);
    var account = repository.account;
    if (account == null) {
      try {
        account = await ref.read(authSessionProvider.future);
      } catch (_) {
        account = null;
      }
    }
    if (!mounted) return;
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진 자동인식은 가입 또는 로그인이 필요해요.')),
      );
      await context.push(_loginLocation());
      return;
    }
    if (!account.canReadCatalog) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진 자동인식은 의약품 검색 권한 승인 후 사용할 수 있어요.')),
      );
      await context.push('/login');
      return;
    }

    _searchTimer?.cancel();
    ++_searchGeneration;
    setState(() {
      _scanning = true;
      _results = const [];
    });
    try {
      final scan = await ref.read(medicineScannerProvider).scan();
      if (scan == null || !mounted) return;
      final terms = const MedicineSearchTermExtractor().extract(scan.lines);
      if (terms.isEmpty) {
        await _showNoRecognizedMedicine();
        return;
      }

      final candidates = <String, DrugSummary>{};
      for (final term in terms.take(4)) {
        final matches = await ref.read(catalogRepositoryProvider).search(term);
        for (final match in matches) {
          candidates.putIfAbsent(match.itemSeq, () => match);
          if (candidates.length >= 10) break;
        }
        if (candidates.length >= 10) break;
      }
      if (!mounted) return;
      if (candidates.isEmpty) {
        await _showNoCatalogCandidates(terms);
        return;
      }

      final selected = await showModalBottomSheet<DrugSummary>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => _PhotoCandidateSheet(
          terms: terms,
          candidates: candidates.values.toList(growable: false),
        ),
      );
      if (selected != null && mounted) await _openDrugDetail(selected);
    } on MedicineScanException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_scanErrorMessage(error.failure))));
    } catch (error) {
      if (!mounted) return;
      final message = _isCatalogAccessError(error)
          ? _catalogErrorMessage(error)
          : '사진에서 의약품 후보를 찾지 못했어요. 다시 촬영하거나 직접 검색해 주세요.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  String _loginLocation() {
    final returnLocation = widget.itemId == null
        ? Uri(
            path: '/inventory/new',
            queryParameters: {'containerId': ?widget.containerId},
          ).toString()
        : '/inventory/${Uri.encodeComponent(widget.itemId!)}/edit';
    return Uri(
      path: '/login',
      queryParameters: {'from': returnLocation},
    ).toString();
  }

  Future<void> _showNoRecognizedMedicine() async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('제품명을 읽지 못했어요'),
        content: const Text('상자나 포장의 제품명이 화면을 크게 채우도록 밝은 곳에서 정면으로 다시 촬영해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('직접 검색'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('다시 촬영'),
          ),
        ],
      ),
    );
    if (retry == true && mounted) await _scanMedicine();
  }

  Future<void> _showNoCatalogCandidates(List<String> terms) async {
    final selectedTerm = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => _NoPhotoCandidateSheet(terms: terms),
    );
    if (selectedTerm == null || !mounted) return;
    _nameController.text = selectedTerm;
    _onSearchChanged(selectedTerm);
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _expiresOn ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: '사용기한 선택',
    );
    if (result != null) setState(() => _expiresOn = result);
  }

  Future<void> _openDrugDetail(DrugSummary summary) async {
    setState(() => _searching = true);
    try {
      final detail = await ref
          .read(catalogRepositoryProvider)
          .detail(summary.itemSeq);
      if (!mounted) return;
      final selected = await showModalBottomSheet<_DrugSelectionResult>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => _DrugDetailSheet(
          detail: detail,
          initialVariantKey: _identificationVariantKey,
        ),
      );
      if (selected != null && mounted) {
        final variant = selected.variant;
        setState(() {
          _nameController.text = detail.itemName;
          _makerController.text = detail.manufacturer ?? '';
          if (_storageController.text.trim().isEmpty) {
            _storageController.text = detail.storageMethod ?? '';
          }
          _itemSeq = detail.itemSeq;
          _ingredientSummary = detail.ingredients.isEmpty
              ? null
              : detail.ingredients.join(', ');
          _identificationVariantKey = variant?.variantKey;
          _officialImageUrl = variant?.imageUrl ?? detail.imageUrl;
          _appearanceSummary = _appearanceLabel(
            variant ?? detail.identification,
            fallback: detail.appearance,
          );
          _results = const [];
        });
      }
    } catch (error) {
      if (!mounted) return;
      if (_isCatalogAccessError(error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_catalogErrorMessage(error)),
            action: SnackBarAction(
              label: '계정 확인',
              onPressed: () => context.push('/login'),
            ),
          ),
        );
        return;
      }
      setState(() {
        _nameController.text = summary.itemName;
        _makerController.text = summary.manufacturer ?? '';
        _itemSeq = summary.itemSeq;
        _ingredientSummary = null;
        _identificationVariantKey = null;
        _officialImageUrl = null;
        _appearanceSummary = null;
        _results = const [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상세 정보는 불러오지 못했지만 제품을 선택했어요.')),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _openConnectedDrugDetail() async {
    final itemSeq = _itemSeq;
    if (itemSeq == null) return;
    await _openDrugDetail(
      DrugSummary(
        itemSeq: itemSeq,
        itemName: _nameController.text.trim(),
        manufacturer: _makerController.text.trim().isEmpty
            ? null
            : _makerController.text.trim(),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final database = ref.read(databaseProvider);
    var containerId = _containerId;
    if (containerId == null) {
      final containers = await database
          .select(database.inventoryContainers)
          .get();
      if (containers.isEmpty) {
        throw StateError('No local inventory container exists.');
      }
      containerId = containers.first.id;
    }
    final now = DateTime.now();
    await database.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        id: widget.itemId ?? const Uuid().v4(),
        containerId: containerId,
        productName: _nameController.text.trim(),
        itemSeq: Value(_itemSeq),
        manufacturer: Value(
          _makerController.text.trim().isEmpty
              ? null
              : _makerController.text.trim(),
        ),
        ingredientSummary: Value(_ingredientSummary),
        identificationVariantKey: Value(_identificationVariantKey),
        officialImageUrl: Value(_officialImageUrl),
        appearanceSummary: Value(_appearanceSummary),
        quantity: Value(int.parse(_quantityController.text)),
        expiresOn: Value(_expiresOn),
        storageNote: Value(
          _storageController.text.trim().isEmpty
              ? null
              : _storageController.text.trim(),
        ),
        privateNote: Value(
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
        updatedAt: Value(now),
      ),
    );
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보유약을 삭제할까요?'),
        content: const Text('이 기기의 보관함에서만 삭제되며 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.itemId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(localDataLifecycleProvider)
          .deleteInventoryItem(widget.itemId!);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보유약 삭제를 마치지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _nameController.dispose();
    _makerController.dispose();
    _quantityController.dispose();
    _storageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? '의약품 등록' : '보유약 수정'),
        actions: [
          if (widget.itemId != null)
            IconButton(
              onPressed: _delete,
              icon: Icon(PhosphorIconsRegular.trash),
              tooltip: '삭제',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _PrivacyNote(),
            const SizedBox(height: 12),
            _PhotoRecognitionCard(
              scanning: _scanning,
              onPressed: _scanMedicine,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: '제품명',
                hintText: '예: 타이레놀정',
                prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '제품명을 입력해 주세요.'
                  : null,
            ),
            if (_results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: MedicalBoxColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: _results.take(5).map((result) {
                      return ListTile(
                        dense: true,
                        title: Text(result.itemName),
                        subtitle: Text(
                          [
                            result.manufacturer ?? '제조사 정보 없음',
                            if (result.status?.isNotEmpty ?? false)
                              result.status!,
                          ].join(' · '),
                        ),
                        onTap: () => _openDrugDetail(result),
                      );
                    }).toList(),
                  ),
                ),
              ),
            if (_itemSeq != null && _results.isEmpty) ...[
              const SizedBox(height: 8),
              _ConnectedCatalogCard(
                itemSeq: _itemSeq!,
                appearanceSummary: _appearanceSummary,
                imageUrl: _officialImageUrl,
                onOpen: _openConnectedDrugDetail,
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _makerController,
              decoration: const InputDecoration(labelText: '제조사 (선택)'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '수량',
                suffixText: '개',
              ),
              validator: (value) {
                final quantity = int.tryParse(value ?? '');
                if (quantity == null || quantity < 0 || quantity > 9999) {
                  return '0~9999 사이 수량을 입력해 주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '사용기한 (선택)',
                  suffixIcon: Icon(PhosphorIconsRegular.calendarBlank),
                ),
                child: Text(
                  _expiresOn == null
                      ? '날짜 선택'
                      : DateFormat('yyyy년 M월 d일').format(_expiresOn!),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _storageController,
              decoration: const InputDecoration(
                labelText: '보관 위치·방법 (선택)',
                hintText: '예: 공용 트레이 오른쪽 칸',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '개인 메모 (기기 안에만 저장)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '저장 중…' : '보관함에 저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MedicalBoxColors.sky.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsFill.lockKey, color: MedicalBoxColors.skyDeep),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '로그인 후 검색어만 공식 카탈로그 조회에 사용하고, 사진·수량·사용기한·메모는 서버로 보내지 않아요.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoRecognitionCard extends StatelessWidget {
  const _PhotoRecognitionCard({
    required this.scanning,
    required this.onPressed,
  });

  final bool scanning;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MedicalBoxColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(15),
            ),
            child: PhosphorIcon(
              PhosphorIconsDuotone.camera,
              color: MedicalBoxColors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '사진으로 의약품 찾기',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  '상자·포장 앞면의 제품명을 기기에서 읽어요. 사진은 인식 직후 삭제돼요.',
                  style: TextStyle(
                    color: MedicalBoxColors.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 11),
                FilledButton.icon(
                  onPressed: scanning ? null : onPressed,
                  icon: scanning
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(PhosphorIconsRegular.camera),
                  label: Text(scanning ? '기기에서 읽는 중…' : '제품명 촬영'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCandidateSheet extends StatelessWidget {
  const _PhotoCandidateSheet({required this.terms, required this.candidates});

  final List<String> terms;
  final List<DrugSummary> candidates;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.48,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: MedicalBoxColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsDuotone.scan,
                color: MedicalBoxColors.skyDeep,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '사진에서 찾은 등록 후보',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            '사진 인식은 틀릴 수 있어요. 실제 포장과 제품명·제조사를 확인한 뒤 선택하세요.',
            style: TextStyle(color: MedicalBoxColors.muted, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final term in terms)
                Chip(
                  avatar: Icon(PhosphorIconsRegular.textT, size: 15),
                  label: Text(term),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final candidate in candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: MedicalBoxColors.line),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: ListTile(
                  title: Text(
                    candidate.itemName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    [
                      candidate.manufacturer ?? '제조사 정보 없음',
                      if (candidate.status?.isNotEmpty ?? false)
                        candidate.status!,
                    ].join(' · '),
                  ),
                  trailing: Icon(PhosphorIconsRegular.caretRight),
                  onTap: () => Navigator.pop(context, candidate),
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('직접 검색할게요'),
          ),
        ],
      ),
    );
  }
}

class _NoPhotoCandidateSheet extends StatelessWidget {
  const _NoPhotoCandidateSheet({required this.terms});

  final List<String> terms;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('공식 등록 후보가 없어요', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            '읽힌 검색어가 맞다면 선택해 다시 검색하거나, 제품명을 직접 입력해 주세요.',
            style: TextStyle(color: MedicalBoxColors.muted, height: 1.45),
          ),
          const SizedBox(height: 14),
          for (final term in terms)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(PhosphorIconsRegular.magnifyingGlass),
              title: Text(term),
              onTap: () => Navigator.pop(context, term),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrugSelectionResult {
  const _DrugSelectionResult({required this.detail, this.variant});

  final DrugDetail detail;
  final DrugAppearanceInfo? variant;
}

class _ConnectedCatalogCard extends StatelessWidget {
  const _ConnectedCatalogCard({
    required this.itemSeq,
    required this.onOpen,
    this.appearanceSummary,
    this.imageUrl,
  });

  final String itemSeq;
  final String? appearanceSummary;
  final String? imageUrl;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final imageUri = Uri.tryParse(imageUrl ?? '');
    final canLoadImage =
        imageUri != null &&
        imageUri.scheme == 'https' &&
        imageUri.host.isNotEmpty;
    return Material(
      color: MedicalBoxColors.sky.withValues(alpha: 0.34),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: canLoadImage
                    ? Image.network(
                        imageUri.toString(),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => PhosphorIcon(
                          PhosphorIconsDuotone.scan,
                          color: MedicalBoxColors.skyDeep,
                        ),
                      )
                    : PhosphorIcon(
                        PhosphorIconsDuotone.scan,
                        color: MedicalBoxColors.skyDeep,
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '공식 제품 정보 연결됨',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appearanceSummary?.isNotEmpty == true
                          ? appearanceSummary!
                          : '품목기준코드 $itemSeq · 외형·복용·안전·가격·코드 정보 보기',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MedicalBoxColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(PhosphorIconsRegular.caretRight),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrugDetailSheet extends ConsumerStatefulWidget {
  const _DrugDetailSheet({required this.detail, this.initialVariantKey});

  final DrugDetail detail;
  final String? initialVariantKey;

  @override
  ConsumerState<_DrugDetailSheet> createState() => _DrugDetailSheetState();
}

class _DrugDetailSheetState extends ConsumerState<_DrugDetailSheet> {
  DrugAppearanceInfo? _selectedVariant;

  DrugDetail get detail => widget.detail;

  @override
  void initState() {
    super.initState();
    final variants = detail.identificationVariants;
    for (final variant in variants) {
      if (variant.variantKey == widget.initialVariantKey) {
        _selectedVariant = variant;
        return;
      }
    }
    _selectedVariant = variants.isNotEmpty
        ? variants.first
        : detail.identification;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.97,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: MedicalBoxColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            detail.itemName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (detail.manufacturer != null) detail.manufacturer!,
              if (detail.status != null) detail.status!,
            ].join(' · '),
            style: const TextStyle(color: MedicalBoxColors.muted),
          ),
          if (_hasAppearance(detail)) ...[
            const SizedBox(height: 18),
            _OfficialAppearanceCard(
              detail: detail,
              selectedVariant: _selectedVariant,
              onSelected: (variant) {
                setState(() => _selectedVariant = variant);
              },
            ),
          ],
          _DetailSection(
            title: '성분',
            body: detail.ingredients.isEmpty
                ? '등록된 성분 정보가 없어요.'
                : detail.ingredients.join(', '),
          ),
          if (detail.safetyOverview.totalCount > 0) ...[
            const SizedBox(height: 18),
            _SafetyOverviewCard(
              itemSeq: detail.itemSeq,
              overview: detail.safetyOverview,
            ),
          ],
          DrugCatalogProjectionSections(detail: detail),
          _DetailSection(title: '보관 방법', body: detail.storageMethod),
          _DetailSection(title: '소비자 설명', body: detail.efficacy),
          _DetailSection(title: '사용 방법', body: detail.useMethod),
          _DetailSection(title: '주의사항', body: detail.warning),
          _DetailSection(title: '기타 주의', body: detail.precautions),
          _DetailSection(title: '상호작용', body: detail.interactions),
          _DetailSection(title: '이상반응', body: detail.sideEffects),
          const SizedBox(height: 12),
          const Text(
            '이 정보는 제품 확인을 위한 공식 카탈로그 자료이며 진단, 복용량 계산, 대체약 또는 치료 추천이 아닙니다.',
            style: TextStyle(
              color: MedicalBoxColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (detail.sources.isNotEmpty) ...[
            const Text('출처', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            for (final source in detail.sources)
              Text(
                [
                  source.source,
                  if (source.licenseName != null) source.licenseName!,
                ].join(' · '),
                style: const TextStyle(
                  color: MedicalBoxColors.muted,
                  fontSize: 12,
                ),
              ),
            if (detail.sourceUpdatedAt != null)
              Text(
                '자료 갱신: ${detail.sourceUpdatedAt}',
                style: const TextStyle(
                  color: MedicalBoxColors.muted,
                  fontSize: 12,
                ),
              ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _DrugSelectionResult(detail: detail, variant: _selectedVariant),
            ),
            child: Text(
              detail.identificationVariants.length > 1
                  ? '선택한 외형으로 제품 연결'
                  : '이 제품 선택',
            ),
          ),
        ],
      ),
    );
  }
}

bool _hasAppearance(DrugDetail detail) {
  final identification = detail.identification;
  return detail.identificationVariants.isNotEmpty ||
      (detail.imageUrl?.isNotEmpty ?? false) ||
      (detail.appearance?.isNotEmpty ?? false) ||
      (identification?.shape?.isNotEmpty ?? false) ||
      (identification?.color?.isNotEmpty ?? false) ||
      (identification?.imprintFront?.isNotEmpty ?? false) ||
      (identification?.imprintBack?.isNotEmpty ?? false);
}

class _OfficialAppearanceCard extends StatelessWidget {
  const _OfficialAppearanceCard({
    required this.detail,
    required this.selectedVariant,
    required this.onSelected,
  });

  final DrugDetail detail;
  final DrugAppearanceInfo? selectedVariant;
  final ValueChanged<DrugAppearanceInfo> onSelected;

  @override
  Widget build(BuildContext context) {
    final identification = selectedVariant ?? detail.identification;
    final imageUri = Uri.tryParse(
      identification?.imageUrl ?? detail.imageUrl ?? '',
    );
    final canLoadImage =
        imageUri != null &&
        imageUri.scheme == 'https' &&
        imageUri.host.isNotEmpty;
    final labels = <String>[
      if (identification?.shape?.isNotEmpty ?? false)
        '모양 ${identification!.shape}',
      if (identification?.color?.isNotEmpty ?? false)
        '색상 ${identification!.color}',
      if (identification?.imprintFront?.isNotEmpty ?? false)
        '앞면 ${identification!.imprintFront}',
      if (identification?.imprintBack?.isNotEmpty ?? false)
        '뒷면 ${identification!.imprintBack}',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MedicalBoxColors.sky.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MedicalBoxColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsDuotone.scan,
                color: MedicalBoxColors.skyDeep,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '공식 외형·낱알 식별 정보',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (detail.identificationVariants.length > 1)
                Text(
                  '${detail.identificationVariants.indexOf(identification!) + 1}/${detail.identificationVariants.length}',
                  style: const TextStyle(
                    color: MedicalBoxColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (detail.identificationVariants.length > 1) ...[
            const SizedBox(height: 10),
            const Text(
              '실제 보유한 알약과 같은 외형을 선택하세요.',
              style: TextStyle(color: MedicalBoxColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (
                  var index = 0;
                  index < detail.identificationVariants.length;
                  index++
                )
                  ChoiceChip(
                    label: Text(
                      _compactVariantLabel(
                        detail.identificationVariants[index],
                        index,
                      ),
                    ),
                    selected:
                        detail.identificationVariants[index].variantKey ==
                        identification?.variantKey,
                    onSelected: (_) =>
                        onSelected(detail.identificationVariants[index]),
                  ),
              ],
            ),
          ],
          if (canLoadImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.78),
                  child: Image.network(
                    imageUri.toString(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const _ImageUnavailable(),
                  ),
                ),
              ),
            ),
          ],
          if (detail.appearance?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(detail.appearance!, style: const TextStyle(height: 1.45)),
          ],
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final label in labels)
                  Chip(
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            '이미지는 공식 원본 URL에서 표시하며 앱 저장소에 복제하지 않아요.',
            style: TextStyle(color: MedicalBoxColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SafetyOverviewCard extends StatelessWidget {
  const _SafetyOverviewCard({required this.itemSeq, required this.overview});

  final String itemSeq;
  final DrugSafetyOverview overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MedicalBoxColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  PhosphorIconsDuotone.shieldWarning,
                  color: MedicalBoxColors.orange,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DUR 공식 안전 참고정보',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${overview.totalCount}개 규칙 · 유형을 열어 원문을 확인하세요.',
                        style: const TextStyle(
                          color: MedicalBoxColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final category in overview.categories)
            _SafetyCategoryTile(itemSeq: itemSeq, category: category),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Text(
              '현재 사용자에게 해당한다는 자동 판단이 아니에요. 실제 복용 여부는 의사·약사에게 확인하세요.',
              style: TextStyle(
                color: MedicalBoxColors.muted,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyCategoryTile extends ConsumerStatefulWidget {
  const _SafetyCategoryTile({required this.itemSeq, required this.category});

  final String itemSeq;
  final DrugSafetyCategory category;

  @override
  ConsumerState<_SafetyCategoryTile> createState() =>
      _SafetyCategoryTileState();
}

class _SafetyCategoryTileState extends ConsumerState<_SafetyCategoryTile> {
  final List<DrugSafetyRule> _rules = [];
  String? _nextCursor;
  bool _loaded = false;
  bool _loading = false;
  bool _accessError = false;
  String? _error;

  Future<void> _load({bool more = false}) async {
    if (_loading || (_loaded && !more)) return;
    setState(() {
      _loading = true;
      _accessError = false;
      _error = null;
    });
    try {
      final page = await ref
          .read(catalogRepositoryProvider)
          .safetyRules(
            widget.itemSeq,
            ruleType: widget.category.ruleType,
            cursor: more ? _nextCursor : null,
          );
      if (!mounted) return;
      setState(() {
        if (!more) _rules.clear();
        _rules.addAll(page.items);
        _nextCursor = page.nextCursor;
        _loaded = true;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _accessError = _isCatalogAccessError(error);
          _error = _catalogErrorMessage(
            error,
            fallback: '공식 DUR 정보를 불러오지 못했어요.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      title: Text(
        _safetyCategoryLabel(widget.category.ruleType),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      trailing: Text(
        '${widget.category.count}',
        semanticsLabel: '${widget.category.count}개',
        style: const TextStyle(
          color: MedicalBoxColors.orange,
          fontWeight: FontWeight.w900,
        ),
      ),
      onExpansionChanged: (expanded) {
        if (expanded) _load();
      },
      children: [
        if (_loading && _rules.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(_error!, style: const TextStyle(fontSize: 12)),
                TextButton(
                  onPressed: _accessError
                      ? () => context.push('/login')
                      : _load,
                  child: Text(_accessError ? '계정 확인' : '다시 시도'),
                ),
              ],
            ),
          ),
        for (final rule in _rules) _SafetyRuleCard(rule: rule),
        if (_nextCursor != null)
          TextButton.icon(
            onPressed: _loading ? null : () => _load(more: true),
            icon: _loading
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(PhosphorIconsRegular.arrowDown),
            label: const Text('다음 20개 보기'),
          ),
      ],
    );
  }
}

class _SafetyRuleCard extends StatelessWidget {
  const _SafetyRuleCard({required this.rule});

  final DrugSafetyRule rule;

  @override
  Widget build(BuildContext context) {
    final counterpart = [
      if (rule.counterpartItemName?.isNotEmpty ?? false)
        rule.counterpartItemName!,
      if (rule.counterpartIngredientName?.isNotEmpty ?? false)
        rule.counterpartIngredientName!,
    ].join(' · ');
    final title = counterpart.isNotEmpty
        ? counterpart
        : (rule.ingredientName?.isNotEmpty ?? false)
        ? rule.ingredientName!
        : rule.typeName ?? '공식 DUR 규칙';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MedicalBoxColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          if ((rule.typeName?.isNotEmpty ?? false) ||
              (rule.notificationDate?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (rule.typeName?.isNotEmpty ?? false) rule.typeName!,
                if (rule.notificationDate?.isNotEmpty ?? false)
                  '공고 ${_formatSafetyDate(rule.notificationDate!)}',
              ].join(' · '),
              style: const TextStyle(
                color: MedicalBoxColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (rule.prohibitionContent?.isNotEmpty ?? false) ...[
            const SizedBox(height: 5),
            Text(
              rule.prohibitionContent!,
              style: const TextStyle(height: 1.45),
            ),
          ],
          if (rule.remark?.isNotEmpty ?? false) ...[
            const SizedBox(height: 5),
            Text(
              rule.remark!,
              style: const TextStyle(
                color: MedicalBoxColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (!(rule.prohibitionContent?.isNotEmpty ?? false) &&
              !(rule.remark?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 5),
            const Text(
              '식약처 DUR 등록 규칙이에요. 해당 여부와 의미는 의사·약사에게 확인하세요.',
              style: TextStyle(
                color: MedicalBoxColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatSafetyDate(String value) {
  if (value.length != 8) return value;
  return '${value.substring(0, 4)}.${value.substring(4, 6)}.${value.substring(6, 8)}';
}

bool _isCatalogAccessError(Object error) {
  return error is ApiException &&
      (error.statusCode == 401 || error.statusCode == 403);
}

String _catalogErrorMessage(
  Object error, {
  String fallback = '공식 의약품 검색에 연결할 수 없어요. 직접 입력할 수 있어요.',
}) {
  if (error is ApiException && error.statusCode == 401) {
    return '공식 의약품 정보는 로그인 후 검색할 수 있어요.';
  }
  if (error is ApiException && error.statusCode == 403) {
    return '현재 계정에는 의약품 검색 권한이 없어요. 베타 승인을 확인해 주세요.';
  }
  return fallback;
}

String _scanErrorMessage(MedicineScanFailure failure) {
  return switch (failure) {
    MedicineScanFailure.cameraDenied =>
      '카메라 권한이 필요해요. 기기 설정에서 우리집 구급키트의 카메라 접근을 허용해 주세요.',
    MedicineScanFailure.cameraUnavailable =>
      '이 기기에서 카메라를 열 수 없어요. 잠시 후 다시 시도해 주세요.',
    MedicineScanFailure.recognitionUnavailable =>
      '이 기기에서는 한글 사진 인식을 사용할 수 없어요. 제품명을 직접 검색해 주세요.',
    MedicineScanFailure.recognitionFailed =>
      '사진의 글자를 읽지 못했어요. 밝은 곳에서 제품명을 크게 촬영해 주세요.',
  };
}

String _safetyCategoryLabel(String ruleType) {
  return switch (ruleType) {
    'concomitant_contraindication' => '병용금기',
    'pregnancy_contraindication' => '임부금기',
    'efficacy_group_duplication' => '효능군 중복',
    'dose_caution' => '용량주의',
    'age_contraindication' => '특정연령 금기',
    'extended_release_split_caution' => '서방정 분할주의',
    'elderly_caution' => '노인주의',
    'duration_caution' => '투여기간주의',
    _ => '기타 DUR',
  };
}

String _compactVariantLabel(DrugAppearanceInfo variant, int index) {
  final parts = [
    if (variant.color?.isNotEmpty ?? false) variant.color!,
    if (variant.imprintFront?.isNotEmpty ?? false) variant.imprintFront!,
  ];
  return parts.isEmpty ? '외형 ${index + 1}' : parts.take(2).join(' · ');
}

String? _appearanceLabel(DrugAppearanceInfo? appearance, {String? fallback}) {
  final parts = [
    if (appearance?.shape?.isNotEmpty ?? false) appearance!.shape!,
    if (appearance?.color?.isNotEmpty ?? false) appearance!.color!,
    if (appearance?.imprintFront?.isNotEmpty ?? false)
      '앞 ${appearance!.imprintFront}',
    if (appearance?.imprintBack?.isNotEmpty ?? false)
      '뒤 ${appearance!.imprintBack}',
  ];
  if (parts.isNotEmpty) return parts.join(' · ');
  return fallback?.trim().isEmpty == false ? fallback!.trim() : null;
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.7),
      child: const Center(
        child: Text(
          '공식 이미지를 불러올 수 없어요',
          style: TextStyle(color: MedicalBoxColors.muted),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    if (body == null || body!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(body!, style: const TextStyle(height: 1.55)),
        ],
      ),
    );
  }
}
