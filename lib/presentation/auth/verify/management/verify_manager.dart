import 'package:calora/domain/model/verification/verification.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'package:calora/presentation/auth/verify/management/verify_management.dart';

@injectable
class VerifyManager extends Manager<VerifyState, VerifyEffect> {
  final AuthRepo authRepo;

  VerifyManager(this.authRepo) : super(const VerifyState());

  Verification _verification = Verification();
  String _verificationCode = '';

  void setVerification(Verification value) {
    _verification = value;
  }

  void setVerificationCode(String code) {
    _verificationCode = code;
  }

  void resend() {
    authRepo
        .sendOtp(_verification.email ?? '')
        .handle(
          onStart: () => emit(state.copyWith(loading: true)),
          onData: (data) {
            _verification = data.copyWith(email: _verification.email);
            emit(state.copyWith(loading: false));
          },
          onError: (error) => emit(state.copyWith(loading: false)),
          onDone: () {},
        );
  }

  void verify() {
    authRepo
        .signIn(_verification, _verificationCode)
        .handle(
          onStart: () => emit(state.copyWith(loading: true)),
          onData: (hasNewUser) {
            if (hasNewUser) {
              publish(VerifyEffect.openQuestions(_verification.email!));
            } else {
              publish(VerifyEffect.openDashboard());
            }
          },
          onError: (error) => emit(state.copyWith(loading: false)),
          onDone: () => emit(state.copyWith(loading: false)),
        );
  }
}
