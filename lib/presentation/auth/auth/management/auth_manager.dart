import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/logger/local_logger.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
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

  Future<void> login() async {
    final email = controller.text.trim();

    final localLogger = LocalLogger();

    localLogger.writeToFile("Email: $email\n"
        "Email isEmpty: ${email.isEmpty}\n"
        "Email isValid: ${_isValidEmail(email)}\n"
        "Checked: ${state.checked}\n"
        );

    if (email.isEmpty) {
      publish(AuthEffect.showError(Strings.enterEmailAddress));
      return;
    }
    if (!_isValidEmail(email)) {
      publish(AuthEffect.showError(Strings.emailAddressIsWrongFormat));
      return;
    }
    if (!state.checked) {
      publish(AuthEffect.showError(Strings.youMustAgreeToTheTerms));
      return;
    }

    return _repo
        .sendOtp(email)
        .handle(
          onStart: () {
            localLogger.writeToFile("OnStart\n");
            emit(state.copyWith(loading: true));
          },
          onData: (verification) {
            localLogger.writeToFile("OnDone: ${verification.toJson()}\n");

            publish(AuthEffect.verify(verification));
          },
          onError: (error) {
            localLogger.writeToFile("OnError: ${error.toString()}\n");
            emit(state.copyWith(loading: false));
          },
          onDone: () => emit(state.copyWith(loading: false)),
        );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Future<void> close() {
    controller.dispose();
    termsRecognizer.dispose();
    return super.close();
  }
}
