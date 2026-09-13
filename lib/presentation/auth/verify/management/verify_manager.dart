import 'dart:async';
import 'dart:io';

import 'package:calora/common/service/facebook_analytics_service.dart';
import 'package:calora/domain/model/verification/verification.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:calora/presentation/auth/verify/management/verify_management.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:smart_auth/smart_auth.dart';

@injectable
class VerifyManager extends Manager<VerifyState, VerifyEffect> {
  final AuthRepo authRepo;

  VerifyManager(this.authRepo) : super(const VerifyState());

  final TextEditingController controller = TextEditingController();

  bool _smsListenerActive = false;

  void setInitialVerification(Verification initialVerification) {
    emit(state.copyWith(verification: initialVerification));
    _startSmsListener();
  }

  Future<void> _startSmsListener() async {
    if (!Platform.isAndroid) return;
    if (_smsListenerActive) return;
    _smsListenerActive = true;
    final result = await SmartAuth.instance.getSmsWithUserConsentApi();
    _smsListenerActive = false;
    final code = result.data?.code;
    if (code == null || code.isEmpty || isClosed) return;
    controller.text = code;
    if (code.length == 6) verify();
  }

  Future<void> _stopSmsListener() async {
    if (!Platform.isAndroid) return;
    if (!_smsListenerActive) return;
    _smsListenerActive = false;
    await SmartAuth.instance.removeUserConsentApiListener();
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
            _startSmsListener();
          },
          onError: (error) {
            emit(state.copyWith(loading: false));
            final e = (error as DioException).response?.data['error'];
            publish(VerifyEffect.showError(e.toString()));
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
              // Meta CompleteRegistration. Lives in `onData`, not `onDone` —
              // `onDone` also runs on failure, which would report a
              // registration that never happened.
              unawaited(
                FacebookAnalyticsService.instance.logCompleteRegistration(
                  method: currentVerification.email == null
                      ? 'phone'
                      : 'email',
                ),
              );
              publish(VerifyEffect.openQuestions(currentVerification.email ?? ''));
            } else {
              publish(VerifyEffect.openDashboard());
            }
          },
          onError: (error) {
            final e = (error as DioException).response?.data['error'];
            publish(VerifyEffect.showError(e.toString()));
          },
          onDone: () => emit(state.copyWith(loading: false)),
        );
  }

  @override
  Future<void> close() async {
    await _stopSmsListener();
    controller.dispose();
    return super.close();
  }
}
