import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../theme.dart';

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
      await ref.read(exportServiceProvider).importExport(bytes, password);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('암호화 백업을 이 기기에 가져왔어요.')));
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
          '가족·보유약·수량·방문 준비·알림을 이 기기에서 삭제해요. 서버 계정은 삭제되지 않아요.',
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
    await ref.read(databaseProvider).deleteAllLocalData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기기 데이터를 삭제했어요. 서버 계정은 그대로예요.')),
      );
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const _SectionLabel('계정'),
          Card(
            child: ListTile(
              leading: PhosphorIcon(PhosphorIconsDuotone.userCircle),
              title: const Text('로그인 및 검색 권한'),
              subtitle: const Text('공식 의약품 검색에는 승인된 계정이 필요함'),
              trailing: Icon(PhosphorIconsRegular.caretRight),
              onTap: () => context.push('/login'),
            ),
          ),
          const _SectionLabel('개인정보와 공유'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: PhosphorIcon(PhosphorIconsDuotone.bellSlash),
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
                        .read(databaseProvider)
                        .setNotificationPrivacy(value);
                    ref.invalidate(appSettingsProvider);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: PhosphorIcon(PhosphorIconsDuotone.shareNetwork),
                  title: const Text('공유 전 항상 미리보기'),
                  subtitle: const Text('개인 메모는 기본적으로 포함하지 않음'),
                  trailing: Icon(
                    PhosphorIconsFill.checkCircle,
                    color: MedicalBoxColors.skyDeep,
                  ),
                ),
              ],
            ),
          ),
          const _SectionLabel('암호화 백업'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(PhosphorIconsRegular.uploadSimple),
                  title: const Text('내보내기'),
                  subtitle: const Text('Argon2id + XChaCha20-Poly1305'),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(PhosphorIconsRegular.downloadSimple),
                  title: const Text('가져오기'),
                  subtitle: const Text('.medicalbox 파일만 지원'),
                  onTap: () => _import(context, ref),
                ),
              ],
            ),
          ),
          const _SectionLabel('법적 문서와 지원'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('개인정보 처리방침'),
                  onTap: () => _open('/privacy'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('이용약관'),
                  onTap: () => _open('/terms'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('지원'),
                  onTap: () => _open('/support'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('계정 삭제 안내'),
                  onTap: () => _open('/account-deletion'),
                ),
              ],
            ),
          ),
          const _SectionLabel('데이터 삭제'),
          Card(
            child: ListTile(
              leading: Icon(
                PhosphorIconsRegular.trash,
                color: MedicalBoxColors.orange,
              ),
              title: const Text('이 기기의 모든 데이터 삭제'),
              subtitle: const Text('서버 계정과는 별도로 처리'),
              onTap: () => _deleteLocalData(context, ref),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '의약품 정보는 건강 관리 참고용입니다. 응급 상황이나 의학적 판단이 필요한 경우 의료기관 또는 약사에게 문의하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MedicalBoxColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: MedicalBoxColors.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
