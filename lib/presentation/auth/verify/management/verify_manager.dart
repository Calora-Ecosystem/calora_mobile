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

  String _email = "";

  void setUserEmail(String value) {
    _email = value;
  }

  void resend() {
    authRepo.resendVerifyCode().handle(
      onStart: () {
        emit(state.copyWith(isStartTime: true));
      },
      onData: (data) {},
      onError: (error) {
        emit(state.copyWith(isStartTime: false));
      },
      onDone: () {},
    );
  }

  void verify(String code) {
    authRepo
        .verify(
          Verification(
            verificationCode: code,
            email: _email,
            expireDate: DateTime.now(),
          ),
          code,
        )
        .handle(
          onStart: () {},
          onData: (data) {},
          onError: (error) {},
          onDone: () {},
        );
  }
}
