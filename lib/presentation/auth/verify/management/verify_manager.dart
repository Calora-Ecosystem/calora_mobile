import 'package:calora/domain/model/verification/verification.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:calora/presentation/auth/verify/management/verify_management.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class VerifyManager extends Manager<VerifyState, VerifyEffect> {
  final AuthRepo authRepo;

  VerifyManager(this.authRepo) : super(const VerifyState());

  final TextEditingController controller = TextEditingController();

  void setInitialVerification(Verification initialVerification) {
    emit(state.copyWith(verification: initialVerification));
  }

  void resend() {
    final currentVerification = state.verification;
    if (currentVerification?.email == null) return;

    authRepo
        .sendOtp(currentVerification!.email!)
        .handle(
          onStart: () => emit(state.copyWith(loading: true)),
          onData: (data) {
            final newVerification = data.copyWith(email: currentVerification.email);
            emit(state.copyWith(loading: false, verification: newVerification));
          },
          onError: (error) {
            emit(state.copyWith(loading: false));
            publish(VerifyEffect.showError(error.toString()));
          },
        );
  }

  void verify() {
    final currentVerification = state.verification;
    if (currentVerification == null) return;

    authRepo
        .signIn(currentVerification, controller.text)
        .handle(
          onStart: () => emit(state.copyWith(loading: true)),
          onData: (hasNewUser) {
            if (hasNewUser) {
              publish(VerifyEffect.openQuestions(currentVerification.email ?? ''));
            } else {
              publish(VerifyEffect.openDashboard());
            }
          },
          onError: (error) {
            publish(VerifyEffect.showError(error.toString()));
          },
          onDone: () => emit(state.copyWith(loading: false)),
        );
  }
}
