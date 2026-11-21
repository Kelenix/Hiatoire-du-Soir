import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../core/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../../session/data/google_identity.dart';
import '../../session/data/session_repository.dart';

/// Code envoyé, en attente de saisie. Il survit à la fermeture de l'Espace Parents quand le parent
/// quitte l'app pour lire l'e-mail (H22) : au retour, il n'a qu'à saisir le code.
final pendingEmailCodeProvider = StateProvider<({String email, EmailCodePurpose purpose})?>((ref) => null);

/// Compte parent (US-20) et suppression du compte (US-21), maquette P4.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final email = user == null || user.isAnonymous ? null : user.email;
    return NightScaffold(
      title: 'Compte',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (email == null) const _EmailSignIn() else _SignedIn(email: email),
          const SizedBox(height: 40),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => _confirmDeletion(context, ref),
            child: const Text('Supprimer le compte et les données'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletion(BuildContext context, WidgetRef ref) async {
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer définitivement ?'),
        content: const Text(
          'Les histoires, favoris et personnages de ce compte seront effacés, sans retour possible. '
          'Un abonnement en cours ne s’arrête pas tout seul : il s’annule depuis le store.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (isConfirmed != true || !context.mounted) return;
    await _run(context, ref.read(sessionRepositoryProvider).deleteAccount, done: 'Compte supprimé.');
  }
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn({required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Connecté avec', style: textTheme.bodySmall),
        Text(email, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Histoires, favoris et achats sont rattachés à ce compte.', style: textTheme.bodySmall),
        const SizedBox(height: 24),
        OutlinePillButton(
          label: 'Se déconnecter',
          onPressed: () => _run(context, ref.read(sessionRepositoryProvider).signOut, done: 'Déconnecté.'),
        ),
      ],
    );
  }
}

/// Création du compte ou connexion par code à 6 chiffres reçu par e-mail.
class _EmailSignIn extends ConsumerStatefulWidget {
  const _EmailSignIn();

  @override
  ConsumerState<_EmailSignIn> createState() => _EmailSignInState();
}

class _EmailSignInState extends ConsumerState<_EmailSignIn> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  EmailCodePurpose? _purpose;
  String? _error;
  var _isBusy = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    final pending = ref.read(pendingEmailCodeProvider);
    _email.text = pending?.email ?? '';
    _purpose = pending?.purpose;
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = 'Adresse e-mail invalide.');
      return;
    }
    await _busy(() async {
      final purpose = await ref.read(sessionRepositoryProvider).sendEmailCode(email);
      ref.read(pendingEmailCodeProvider.notifier).state = (email: email, purpose: purpose);
      setState(() => _purpose = purpose);
    });
  }

  /// Une fois le code validé, l'écran passe au compte connecté : rien n'est lu après l'attente.
  Future<void> _verify() {
    final pending = ref.read(pendingEmailCodeProvider.notifier);
    return _busy(() async {
      await ref.read(sessionRepositoryProvider).verifyEmailCode(_email.text.trim(), _code.text.trim(), _purpose!);
      pending.state = null;
    });
  }

  Future<void> _signInWithGoogle() {
    final pending = ref.read(pendingEmailCodeProvider.notifier);
    return _busy(() async {
      if (await ref.read(sessionRepositoryProvider).signInWithGoogle()) pending.state = null;
    });
  }

  void _changeEmail() {
    ref.read(pendingEmailCodeProvider.notifier).state = null;
    setState(() {
      _purpose = null;
      _code.clear();
    });
  }

  Future<void> _busy(Future<void> Function() action) async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await action();
    } on Failure catch (failure) {
      if (mounted) setState(() => _error = _messageFor(failure));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasCodeBeenSent = _purpose != null;
    final canUseGoogle = ref.watch(googleIdentityProvider).isAvailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Créer un compte ou se connecter', style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Un compte garde vos histoires et vos achats, et les retrouve sur un autre appareil.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        if (canUseGoogle) ...[
          OutlinePillButton(label: 'Continuer avec Google', onPressed: _isBusy ? null : _signInWithGoogle),
          const SizedBox(height: 24),
        ],
        if (!AppConfig.emailCodeEnabled) ...[
          if (!canUseGoogle) Text('La création de compte arrive bientôt sur cet appareil.', style: textTheme.bodySmall),
          if (_error != null) Text(_error!, style: textTheme.bodySmall!.copyWith(color: AppColors.error)),
        ] else ...[
          Text(
            canUseGoogle
                ? 'Ou avec un code à 6 chiffres reçu par e-mail :'
                : 'Vous recevrez un code à 6 chiffres par e-mail.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            enabled: !hasCodeBeenSent,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Adresse e-mail'),
          ),
          if (hasCodeBeenSent) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: const InputDecoration(labelText: 'Code reçu par e-mail'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: textTheme.bodySmall!.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: 20),
          MagicButton(
            label: hasCodeBeenSent ? 'Valider le code' : 'Recevoir un code',
            onPressed: _isBusy ? null : (hasCodeBeenSent ? _verify : _sendCode),
          ),
          if (hasCodeBeenSent)
            TextButton(onPressed: _isBusy ? null : _changeEmail, child: const Text('Changer d’adresse')),
        ],
      ],
    );
  }
}

String _messageFor(Failure failure) => switch (failure) {
  Failure.offline => 'Pas de connexion Internet. Réessayez dans un instant.',
  Failure.invalidCode => 'Code incorrect ou expiré. Vérifiez l’e-mail le plus récent.',
  _ => 'Une erreur est survenue. Réessayez dans un instant.',
};

/// Les données du compte se rechargent d'elles-mêmes (accountProvider) ; l'écran, lui, peut avoir
/// disparu entre-temps : messagerie et routeur sont pris avant l'attente.
Future<void> _run(BuildContext context, Future<void> Function() action, {required String done}) async {
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(done)));
    router.go('/');
  } on Failure catch (failure) {
    messenger.showSnackBar(SnackBar(content: Text(_messageFor(failure))));
  }
}
