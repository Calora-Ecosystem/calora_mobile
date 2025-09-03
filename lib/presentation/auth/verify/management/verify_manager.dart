import 'package:calora/domain/model/verification/verification.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'verify_management.dart';

@injectable
class VerifyManager extends Manager<VerifyState, VerifyEffect> {
  final AuthRepo authRepo;

  VerifyManager(this.authRepo) : super(const VerifyState());

  Verification _verification = Verification();

  String _verificationCode = "";

  void setVerification(Verification value) {
    _verification = value;
  }

  void setVerificationCode(String code) {
    this._verificationCode = code;
  }

  void resend() {
    authRepo
        .login(_verification.email ?? "")
        .handle(
          onStart: () {
            emit(state.copyWith(isStartTime: false, loading: true));
          },
          onData: (data) {
            _verification = data.copyWith(email: _verification.email);
            emit(state.copyWith(isStartTime: true, loading: false));
          },
          onError: (error) {
            emit(state.copyWith(isStartTime: false, loading: false));
          },
          onDone: () {},
        );
  }

  void verify() {
    authRepo
        .verify(_verification, _verificationCode)
        .handle(
          onStart: () {
            emit(state.copyWith(loading: true, isStartTime: false));
          },
          onData: (data) {
            publish(VerifyEffect());
          },
          onError: (error) {
            emit(state.copyWith(loading: false, isStartTime: false));
          },
          onDone: () {},
        );
  }
}
