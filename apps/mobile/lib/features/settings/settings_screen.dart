import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../services/local_data_lifecycle.dart';
import '../../services/monetization_service.dart';
import '../../theme.dart';
import '../../widgets/cabinet_index_components.dart';
import '../../widgets/privacy_safe_banner_slot.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<String?> _passwordDialog(
    BuildContext context, {
    required String title,
    required String action,
  }) async {
    var input = '';
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          autofocus: true,
          obscureText: true,
          onChanged: (value) => input = value,
          decoration: const InputDecoration(
            labelText: '암호',
            helperText: '10자 이상 입력해 주세요.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input),
            child: Text(action),
          ),
        ],
      ),
    );
    return value;
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final password = await _passwordDialog(
      context,
      title: '암호화 내보내기',
      action: '내보내기',
    );
    if (password == null || !context.mounted) return;
    try {
      final file = await ref.read(exportServiceProvider).createExport(password);
      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/octet-stream')],
          subject: '우리집 구급키트 암호화 백업',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내보내기에 실패했어요. 암호는 10자 이상이어야 해요.')),
        );
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['medicalbox'],
      withData: true,
    );
    if (result == null || !context.mounted) return;
    final password = await _passwordDialog(
      context,
      title: '암호화 백업 가져오기',
      action: '가져오기',
    );
    if (password == null) return;
    final selected = result.files.single;
    final bytes =
        selected.bytes ??
        (selected.path == null
            ? null
            : await File(selected.path!).readAsBytes());
    if (bytes == null) return;
    try {
      await ref.read(localDataLifecycleProvider).importExport(bytes, password);
      ref.invalidate(appSettingsProvider);
      final importedSettings = await ref.read(databaseProvider).getSettings();
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('암호화 백업을 이 기기에 가져왔어요.')),
        );
        if (!importedSettings.onboardingCompleted) {
          context.go('/onboarding');
        }
      }
    } on LocalDataImportPartialFailure {
      ref.invalidate(appSettingsProvider);
      final importedSettings = await ref.read(databaseProvider).getSettings();
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('백업 데이터는 가져왔지만 알림 재예약을 마치지 못했어요. 알림을 다시 확인해 주세요.'),
          ),
        );
        if (!importedSettings.onboardingCompleted) {
          context.go('/onboarding');
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 또는 암호를 확인해 주세요. 기존 데이터는 유지됐어요.')),
        );
      }
    }
  }

  Future<void> _deleteLocalData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기기 데이터를 삭제할까요?'),
        content: const Text(
          '가족·보유약·방문 준비·알림과 앱이 만든 임시 백업을 이 기기에서 삭제해요. '
          '저장하거나 공유한 .medicalbox 복사본은 앱에서 지울 수 없으므로 별도로 삭제해야 해요. '
          '서버 계정은 삭제되지 않아요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('기기 데이터 삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(localDataLifecycleProvider).deleteAllLocalData();
      ref.invalidate(appSettingsProvider);
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        context.go('/onboarding');
        messenger.showSnackBar(
          const SnackBar(content: Text('기기 데이터를 삭제했어요. 서버 계정은 그대로예요.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기기 데이터 삭제를 마치지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  Future<void> _open(String path) {
    return launchUrl(
      Uri.parse('https://medicalbox.outoftokens.ai$path'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MedicalBoxSpacing.screen,
          MedicalBoxSpacing.x1,
          MedicalBoxSpacing.screen,
          MedicalBoxSpacing.x8,
        ),
        children: [
          const CabinetSectionLabel('계정'),
          CabinetSectionList(
            showDividers: false,
            children: [
              _SettingsRow(
                icon: PhosphorIconsRegular.userCircle,
                title: '계정 관리·삭제',
                subtitle: Text(
                  ref.watch(authSessionProvider).valueOrNull?.email ??
                      ref.read(authRepositoryProvider).account?.email ??
                      '앱 사용에는 로그인이 필요함',
                ),
                onTap: () => context.push('/login'),
              ),
            ],
          ),
          const CabinetSectionLabel('개인정보와 공유'),
          CabinetSectionList(
            children: [
              SwitchListTile(
                minTileHeight: 64,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: const PhosphorIcon(
                  PhosphorIconsRegular.bellSlash,
                  size: 22,
                ),
                title: const Text('잠금화면에서 의약품명 숨기기'),
                subtitle: const Text('알림에는 일반적인 확인 문구만 표시'),
                value:
                    ref
                        .watch(appSettingsProvider)
                        .valueOrNull
                        ?.notificationPrivacy ??
                    true,
                onChanged: (value) async {
                  await ref
                      .read(localDataLifecycleProvider)
                      .setNotificationPrivacy(value);
                  ref.invalidate(appSettingsProvider);
                },
              ),
              const _SettingsRow(
                icon: PhosphorIconsRegular.shareNetwork,
                title: '공유 전 항상 미리보기',
                subtitle: Text('개인 메모는 기본적으로 포함하지 않음'),
                trailing: PhosphorIcon(
                  PhosphorIconsRegular.checkCircle,
                  color: MedicalBoxColors.official,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: MedicalBoxSpacing.x4),
          const PrivacySafeBannerSlot(
            placement: BannerAdPlacement.settingsGeneralFooter,
          ),
          const CabinetSectionLabel('암호화 백업'),
          CabinetSectionList(
            children: [
              _SettingsRow(
                icon: PhosphorIconsRegular.uploadSimple,
                title: '내보내기',
                subtitle: const Text('Argon2id + AES-256-GCM'),
                onTap: () => _export(context, ref),
              ),
              _SettingsRow(
                icon: PhosphorIconsRegular.downloadSimple,
                title: '가져오기',
                subtitle: const Text('.medicalbox 파일만 지원'),
                onTap: () => _import(context, ref),
              ),
            ],
          ),
          const CabinetSectionLabel('법적 문서와 지원'),
          CabinetSectionList(
            children: [
              _SettingsRow(
                icon: PhosphorIconsRegular.shieldCheck,
                title: '개인정보 처리방침',
                onTap: () => _open('/privacy'),
              ),
              _SettingsRow(
                icon: PhosphorIconsRegular.fileText,
                title: '이용약관',
                onTap: () => _open('/terms'),
              ),
              _SettingsRow(
                icon: PhosphorIconsRegular.lifebuoy,
                title: '지원',
                onTap: () => _open('/support'),
              ),
              _SettingsRow(
                icon: PhosphorIconsRegular.userMinus,
                title: '계정 삭제 안내',
                onTap: () => _open('/account-deletion'),
              ),
            ],
          ),
          const CabinetSectionLabel('기기 데이터'),
          CabinetSectionList(
            showDividers: false,
            children: [
              _SettingsRow(
                icon: PhosphorIconsRegular.trash,
                iconColor: MedicalBoxColors.accent,
                title: '이 기기의 모든 데이터 삭제',
                titleColor: MedicalBoxColors.accent,
                subtitle: const Text('서버 계정은 유지 · 외부 저장/공유 복사본은 별도 삭제'),
                onTap: () => _deleteLocalData(context, ref),
              ),
            ],
          ),
          const SizedBox(height: MedicalBoxSpacing.x6),
          const Text(
            '의약품 정보는 건강 관리 참고용입니다. 응급 상황이나 의학적 판단이 필요한 경우 의료기관 또는 약사에게 문의하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MedicalBoxColors.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  final Object icon;
  final String title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: PhosphorIcon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: titleColor),
      ),
      subtitle: subtitle,
      trailing:
          trailing ??
          (onTap == null
              ? null
              : const PhosphorIcon(
                  PhosphorIconsRegular.caretRight,
                  size: 18,
                  color: MedicalBoxColors.faint,
                )),
      onTap: onTap,
    );
  }
}
