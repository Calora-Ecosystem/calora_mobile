import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;

import 'auth_management.dart';

@injectable
class AuthManager extends Manager<AuthState, AuthEffect> {
  AuthManager(this._repo) : super(const AuthState()) {
    termsRecognizer.onTap = _openTermsOfUse;
  }

  final AuthRepo _repo;

  final controller = TextEditingController();
  final termsRecognizer = TapGestureRecognizer();

  void setChecked(bool? value) => emit(state.copyWith(checked: value == true));

  void _openTermsOfUse() async {
    final url = Uri.parse('https://www.google.com');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> login() => _repo
      .login(controller.text)
      .handle(
        onStart: () => emit(state.copyWith(loading: true)),
        onData: (verification) => publish(AuthEffect.verify(verification)),
        onError: (error) {
          if (error is DioException) {
            final statusCode = error.response?.statusCode;
            if (statusCode == 404) {
              publish(AuthEffect.registerNeeded(controller.text));
              return;
            }
          }
          emit(state.copyWith(loading: false));
        },
        onDone: () => emit(state.copyWith(loading: false)),
      );

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}
