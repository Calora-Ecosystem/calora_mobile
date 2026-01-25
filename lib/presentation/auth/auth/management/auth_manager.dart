import 'package:calora/common/gen/strings.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:calora/presentation/auth/auth/management/auth_management.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;

@injectable
class AuthManager extends Manager<AuthState, AuthEffect> {
  final AuthRepo _repo;
  final AuthStore _authStore;

  AuthManager(this._repo, this._authStore) : super(const AuthState()) {
    termsRecognizer.onTap = _openTermsOfUse;

    _googleInitFuture = _googleSignIn.initialize(
      serverClientId: _serverClientId,
    );
  }

  final controller = TextEditingController();
  final termsRecognizer = TapGestureRecognizer();

  void setChecked(bool? value) => emit(state.copyWith(checked: value == true));

  void _openTermsOfUse() async {
    final url = Uri.parse('https://www.google.com');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> login() async {
    if (!state.checked) {
      publish(AuthEffect.showError(Strings.youMustAgreeToTheTerms));
      return;
    }

    if (state.isUzbekistan) {
      final phone = controller.text.replaceAll(' ', '');
      if (phone.length != 9) {
        publish(AuthEffect.showError(Strings.enterValidNumber));
        return;
      }
      final fullPhoneNumber = '+998$phone';

      return _repo
          .sendOtpToPhone(fullPhoneNumber)
          .handle(
        onStart: () => emit(state.copyWith(loading: true)),
        onData: (verification) => publish(AuthEffect.verify(verification)),
        onError: (error) => emit(state.copyWith(loading: false)),
        onDone: () => emit(state.copyWith(loading: false)),
      );
    } else {
      final email = controller.text.trim();
      if (email.isEmpty) {
        publish(AuthEffect.showError(Strings.enterEmailAddress));
        return;
      }
      if (!_isValidEmail(email)) {
        publish(AuthEffect.showError(Strings.emailAddressIsWrongFormat));
        return;
      }

      return _repo
          .sendOtp(email)
          .handle(
        onStart: () => emit(state.copyWith(loading: true)),
        onData: (verification) => publish(AuthEffect.verify(verification)),
        onError: (error) => emit(state.copyWith(loading: false)),
        onDone: () => emit(state.copyWith(loading: false)),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> setIsUzbekistan({bool? value}) async {
    if (value == null) {
      final bool response = await _authStore.isCountryUzbekistan.call();
      emit(state.copyWith(isUzbekistan: response));
      return;
    }
    emit(state.copyWith(isUzbekistan: value));
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  late final Future<void> _googleInitFuture;

  static const String _serverClientId = '638398407864-e2qthkeciq05a3conbgd4tujlrn146lq.apps.googleusercontent.com';

  Future<void> loginWithGoogle() async {
    try {
      if (!state.checked) {
        publish(AuthEffect.showError(Strings.youMustAgreeToTheTerms));
        return;
      }

      emit(state.copyWith(loading: true));
      await _googleInitFuture;

      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email'],
      );

      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        publish(AuthEffect.showError('Google idToken topilmadi'));
        return;
      }

      final hasNewUser = await _repo.signInGoogle(idToken);
      if (hasNewUser) {
        publish(AuthEffect.openQuestions(account.email));
        return;
      }
      publish(AuthEffect.openDashboard());
    } on GoogleSignInException catch (e, st) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      publish(AuthEffect.showError('${e.code}: ${e.description ?? ''}'.trim()));
    } catch (e, st) {
      publish(AuthEffect.showError(e.toString()));
    } finally {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> loginWithApple() async {
    try {
      if (!state.checked) {
        publish(AuthEffect.showError(Strings.youMustAgreeToTheTerms));
        return;
      }

      emit(state.copyWith(loading: true));

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? ssoToken = credential.identityToken;

      if (ssoToken == null || ssoToken.isEmpty) {
        publish(AuthEffect.showError('Apple token topilmadi'));
        return;
      }

      final bool hasNewUser = await _repo.signInApple(ssoToken);

      if (hasNewUser) {
        publish(AuthEffect.openQuestions(credential.email ?? ''));
        return;
      }

      publish(AuthEffect.openDashboard());
    } catch (e) {
      publish(AuthEffect.showError(e.toString()));
    } finally {
      emit(state.copyWith(loading: false));
    }
  }

  @override
  Future<void> close() {
    controller.dispose();
    termsRecognizer.dispose();
    return super.close();
  }
}
