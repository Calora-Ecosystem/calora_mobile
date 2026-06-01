import 'dart:developer';

import 'package:calora/common/gen/strings.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:calora/presentation/auth/auth/management/auth_management.dart';
import 'package:dio/dio.dart';
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

  static const String _serverClientId =
      '638398407864-kt5orfc7nipvl9trmcvt0mlrrfc7k2tg.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final Future<void> _googleInitFuture;

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
    final url = Uri.parse('https://calora.uz/term-of-use');
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
            onError: (error) {
              emit(state.copyWith(loading: false));
              final e = (error as DioException).response?.data['error'];
              publish(AuthEffect.showError(e.toString()));
            },
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
            onError: (error) {
              emit(state.copyWith(loading: false));
              final e = (error as DioException).response?.data['error'];
              publish(AuthEffect.showError(e.toString()));
            },
            onDone: () => emit(state.copyWith(loading: false)),
          );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> setIsUzbekistan({bool? value}) async {
    if (value == null) {
      final bool response = await _authStore.isCountryUzbekistan.call();
      emit(state.copyWith(isUzbekistan: response));
      return;
    }
    emit(state.copyWith(isUzbekistan: value));
  }

  Future<void> loginWithGoogle() async {
    try {
      if (!state.checked) {
        publish(AuthEffect.showError(Strings.youMustAgreeToTheTerms));
        return;
      }

      emit(state.copyWith(loading: true));

      await _googleInitFuture;
      await _googleSignIn.signOut();

      final GoogleSignInAccount account = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final GoogleSignInAuthentication authentication = await account.authentication;
      final String? idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        publish(AuthEffect.showError(Strings.googleIdTokenNotFound));
        return;
      }

      final bool hasNewUser = await _repo.signInGoogle(idToken);

      if (hasNewUser) {
        publish(AuthEffect.openQuestions(account.email));
        return;
      }
      publish(const AuthEffect.openDashboard());
    } catch (e) {
      log('Google Sign-In Error: $e');
      publish(AuthEffect.showError(Strings.googleSigninFailed));
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
        publish(AuthEffect.showError(Strings.appleTokenNotFound));
        return;
      }

      final bool hasNewUser = await _repo.signInApple(ssoToken);

      if (hasNewUser) {
        publish(AuthEffect.openQuestions(credential.email ?? ''));
        return;
      }

      publish(const AuthEffect.openDashboard());
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
