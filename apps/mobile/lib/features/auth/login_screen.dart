import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/auth/auth_repository.dart';
import '../../providers.dart';
import '../../theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _working = false;
  bool _termsAccepted = false;
  String? _message;

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
        setState(() {
          _termsAccepted = false;
          _message = account.canReadCatalog
              ? '${account.displayName ?? account.email ?? '계정'}으로 로그인했고 의약품 검색 권한이 확인됐어요.'
              : '로그인했지만 이 계정에는 아직 의약품 검색 권한이 없어요.';
        });
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
      appBar: AppBar(title: const Text('로그인 및 검색 권한')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PhosphorIcon(
            PhosphorIconsDuotone.userCircleCheck,
            size: 70,
            color: MedicalBoxColors.skyDeep,
          ),
          const SizedBox(height: 18),
          Text(
            account == null
                ? '공식 의약품 검색은 로그인이 필요해요'
                : account.canReadCatalog
                ? '검색 권한이 확인됐어요'
                : '검색 권한 승인 대기 중이에요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            account == null
                ? '승인된 계정으로 로그인하면 공공데이터 기반 의약품 검색·상세·DUR 정보를 조회할 수 있어요. 가족·보유약·알림 데이터는 서버로 동기화되지 않아요.'
                : account.canReadCatalog
                ? '이 계정은 공공데이터 기반 의약품 정보를 조회할 수 있어요. 기기 데이터는 계속 이 기기에만 저장돼요.'
                : '로그인은 완료됐지만 서버의 catalog:read 권한이 아직 부여되지 않았어요. 베타 운영자에게 계정 승인을 요청해 주세요.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: MedicalBoxColors.muted, height: 1.5),
          ),
          if (account == null) ...[
            const SizedBox(height: 26),
            if (restoring)
              const Center(child: CircularProgressIndicator())
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
                title: const Text('현재 이용약관과 개인정보 처리방침을 확인했고 로그인 처리에 동의합니다.'),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
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
              const SizedBox(height: 10),
              for (final provider in supportedProviders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: _working || !_termsAccepted
                        ? null
                        : () => _signIn(provider),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _providerLabel(provider),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ],
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 24),
          if (account != null)
            TextButton.icon(
              onPressed: _working ? null : _signOut,
              icon: Icon(PhosphorIconsRegular.signOut),
              label: const Text('로그아웃'),
            ),
          if (account != null)
            TextButton.icon(
              onPressed: _working ? null : _deleteAccount,
              icon: Icon(PhosphorIconsRegular.trash),
              label: const Text('서버 계정 삭제'),
            ),
          if (!Navigator.of(context).canPop())
            TextButton(
              onPressed: _working ? null : () => context.go('/'),
              child: const Text('구급키트로 돌아가기'),
            ),
        ],
      ),
    );
  }
}

enum _AccountDeletionScope { accountOnly, accountAndDevice }
