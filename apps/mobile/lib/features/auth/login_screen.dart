import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/auth/auth_repository.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../widgets/cabinet_index_components.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    this.returnLocation,
    this.restoreFailed = false,
    super.key,
  });

  final String? returnLocation;
  final bool restoreFailed;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _working = false;
  bool _termsAccepted = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.restoreFailed) {
      _message = '로그인 상태를 확인하지 못했어요. 다시 로그인해 주세요.';
    }
  }

  Future<void> _signIn(LoginProvider provider) async {
    if (!_termsAccepted) {
      setState(() => _message = '로그인 전에 이용약관과 개인정보 처리방침을 확인해 주세요.');
      return;
    }
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final account = await ref
          .read(authRepositoryProvider)
          .signIn(provider, termsAccepted: _termsAccepted);
      ref.invalidate(authSessionProvider);
      if (mounted) {
        if (widget.returnLocation != null) {
          context.go(widget.returnLocation!);
          return;
        }
        setState(() {
          _termsAccepted = false;
          _message = account.canReadCatalog
              ? '${account.displayName ?? account.email ?? '계정'}으로 시작할 준비가 됐어요.'
              : '로그인했어요. 공식 의약품 검색 권한은 아직 승인 대기 중이에요.';
        });
        context.go('/');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = '로그인하지 못했어요. 공급자 설정과 네트워크를 확인해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.invalidate(authSessionProvider);
      if (mounted) {
        setState(() {
          _termsAccepted = false;
          _message = '로그아웃했어요.';
        });
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openLegalDocument(String path) async {
    final opened = await launchUrl(
      Uri.parse('https://medicalbox.outoftokens.ai$path'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() => _message = '문서를 열지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> _deleteAccount() async {
    final repository = ref.read(authRepositoryProvider);
    final account = repository.account;
    if (account == null) {
      setState(() => _message = '먼저 삭제할 계정으로 로그인해 주세요.');
      return;
    }
    final provider = account.providers.length == 1
        ? LoginProvider.values.firstWhere(
            (value) => value.apiName == account.providers.first,
          )
        : await showDialog<LoginProvider>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('다시 인증할 공급자'),
              children: account.providers.map((providerName) {
                final candidate = LoginProvider.values.firstWhere(
                  (value) => value.apiName == providerName,
                );
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, candidate),
                  child: Text(_providerLabel(candidate)),
                );
              }).toList(),
            ),
          );
    if (provider == null) return;
    if (!mounted) return;
    final scope = await showDialog<_AccountDeletionScope>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('무엇을 삭제할까요?'),
        content: const Text(
          '공급자 재인증 후 서버 계정을 삭제해요. 이 기기의 가족·보유약 데이터와 앱이 만든 임시 백업도 '
          '함께 삭제할지 선택할 수 있어요. 저장하거나 공유한 .medicalbox 복사본은 별도로 삭제해야 해요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _AccountDeletionScope.accountOnly),
            child: const Text('계정만 삭제'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _AccountDeletionScope.accountAndDevice),
            child: const Text('계정과 기기 데이터 삭제'),
          ),
        ],
      ),
    );
    if (scope == null) return;
    setState(() => _working = true);
    var accountDeleted = false;
    AccountDeletionResult? deletionResult;
    try {
      await ref
          .read(accountDeletionCoordinatorProvider)
          .delete(
            deleteAccount: () async {
              deletionResult = await repository.deleteAccount(provider);
              ref.invalidate(authSessionProvider);
              accountDeleted = true;
            },
            deleteDeviceData: scope == _AccountDeletionScope.accountAndDevice,
          );
      if (mounted) {
        final providerWarning =
            deletionResult?.requiresProviderCleanupAttention == true
            ? ' 서버 계정은 삭제됐지만 ${_providerLabel(provider)} 연결 해제를 완료하지 못했어요. 공급자 계정 설정에서 연결 상태를 확인해 주세요.'
            : '';
        final localSessionWarning =
            deletionResult?.requiresLocalSessionCleanupAttention == true
            ? ' 서버 계정은 삭제됐지만 이 기기의 로그인 정보 정리를 완료하지 못했어요. 앱을 다시 시작한 뒤 로그인 상태를 확인해 주세요.'
            : '';
        _termsAccepted = false;
        if (scope == _AccountDeletionScope.accountAndDevice) {
          final messenger = ScaffoldMessenger.of(context);
          context.go('/onboarding');
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '서버 계정, 이 기기의 데이터와 앱 임시 백업을 삭제했어요. '
                '외부에 저장하거나 공유한 백업은 별도로 삭제해 주세요.'
                '$providerWarning$localSessionWarning',
              ),
            ),
          );
        } else {
          setState(
            () => _message =
                '서버 계정을 삭제했어요. 기기 데이터는 남아 있어요.'
                '$providerWarning$localSessionWarning',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        if (accountDeleted) _termsAccepted = false;
        setState(
          () => _message = accountDeleted
              ? '서버 계정은 삭제했지만 기기 데이터 또는 앱 임시 백업 삭제를 마치지 못했어요.'
              : '계정을 삭제하지 못했어요. 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _providerLabel(LoginProvider provider) => switch (provider) {
    LoginProvider.kakao => '카카오로 계속',
    LoginProvider.apple => 'Apple로 계속',
    LoginProvider.google => 'Google로 계속',
  };

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final repository = ref.read(authRepositoryProvider);
    final account = repository.account ?? session.asData?.value;
    final restoring = session.isLoading && account == null;
    final supportedProviders = LoginProvider.values.where(
      repository.supportsProvider,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MedicalBoxSpacing.screen,
          MedicalBoxSpacing.x6,
          MedicalBoxSpacing.screen,
          MedicalBoxSpacing.x8,
        ),
        children: [
          _LoginHeader(
            icon: account == null
                ? PhosphorIconsRegular.lockKeyOpen
                : account.canReadCatalog
                ? PhosphorIconsRegular.checkCircle
                : PhosphorIconsRegular.clockCountdown,
            iconColor: account?.canReadCatalog == false
                ? MedicalBoxColors.warning
                : MedicalBoxColors.official,
            title: account == null
                ? '로그인하고 구급키트를 시작하세요'
                : account.canReadCatalog
                ? '공식 의약품 검색이 준비됐어요'
                : '검색 권한을 확인하고 있어요',
            description: account == null
                ? '공식 의약품을 검색하고, 가족과 보관함 정보는 이 기기에 안전하게 보관해요.'
                : account.canReadCatalog
                ? '공공데이터 기반 의약품 정보를 조회할 수 있어요. 가족과 보관함 정보는 서버로 보내지 않아요.'
                : '보관함은 사용할 수 있어요. 공식 검색과 사진 자동인식은 권한 승인 후 열립니다.',
          ),
          if (account == null) ...[
            const SizedBox(height: MedicalBoxSpacing.x7),
            if (restoring)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: MedicalBoxSpacing.x10),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              CheckboxListTile(
                value: _termsAccepted,
                onChanged: _working
                    ? null
                    : (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                          _message = null;
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                minTileHeight: 48,
                title: const Text('이용약관과 개인정보 처리방침에 동의합니다.'),
              ),
              Wrap(
                spacing: MedicalBoxSpacing.x2,
                runSpacing: MedicalBoxSpacing.x1,
                children: [
                  TextButton(
                    onPressed: _working
                        ? null
                        : () => _openLegalDocument('/terms'),
                    child: const Text('이용약관 보기'),
                  ),
                  TextButton(
                    onPressed: _working
                        ? null
                        : () => _openLegalDocument('/privacy'),
                    child: const Text('개인정보 처리방침 보기'),
                  ),
                ],
              ),
              const SizedBox(height: MedicalBoxSpacing.x4),
              for (final provider in supportedProviders)
                Padding(
                  padding: const EdgeInsets.only(bottom: MedicalBoxSpacing.x3),
                  child: OutlinedButton.icon(
                    onPressed: _working || !_termsAccepted
                        ? null
                        : () => _signIn(provider),
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.signIn,
                      size: 20,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    label: Text(_providerLabel(provider)),
                  ),
                ),
            ],
          ],
          if (_message != null) ...[
            const SizedBox(height: MedicalBoxSpacing.x3),
            _LoginMessage(_message!),
          ],
          if (account != null) ...[
            const CabinetSectionLabel('계정'),
            CabinetSectionList(
              children: [
                _AccountActionRow(
                  icon: PhosphorIconsRegular.signOut,
                  label: '로그아웃',
                  onTap: _working ? null : _signOut,
                ),
                _AccountActionRow(
                  icon: PhosphorIconsRegular.trash,
                  label: '서버 계정 삭제',
                  color: MedicalBoxColors.accent,
                  onTap: _working ? null : _deleteAccount,
                ),
              ],
            ),
            if (!Navigator.of(context).canPop()) ...[
              const SizedBox(height: MedicalBoxSpacing.x4),
              OutlinedButton(
                onPressed: _working ? null : () => context.go('/'),
                child: const Text('구급키트로 돌아가기'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final Object icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: MedicalBoxSpacing.touchTarget,
          height: MedicalBoxSpacing.touchTarget,
          child: Align(
            alignment: Alignment.centerLeft,
            child: PhosphorIcon(icon, size: 30, color: iconColor),
          ),
        ),
        const SizedBox(height: MedicalBoxSpacing.x4),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: MedicalBoxSpacing.x2),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: MedicalBoxColors.muted),
        ),
      ],
    );
  }
}

class _LoginMessage extends StatelessWidget {
  const _LoginMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: MedicalBoxSpacing.touchTarget,
            height: MedicalBoxSpacing.touchTarget,
            child: Center(
              child: PhosphorIcon(
                PhosphorIconsRegular.info,
                size: 20,
                color: MedicalBoxColors.warning,
              ),
            ),
          ),
          const SizedBox(width: MedicalBoxSpacing.x2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                message,
                style: const TextStyle(
                  color: MedicalBoxColors.muted,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final Object icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: PhosphorIcon(icon, size: 22, color: color),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
      trailing: const PhosphorIcon(
        PhosphorIconsRegular.caretRight,
        size: 18,
        color: MedicalBoxColors.faint,
      ),
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}

enum _AccountDeletionScope { accountOnly, accountAndDevice }
