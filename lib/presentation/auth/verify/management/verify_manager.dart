import 'dart:async';

import 'package:calora/common/service/facebook_analytics_service.dart';
import 'package:calora/common/service/sms_autofill_service.dart';
import 'package:calora/domain/model/verification/verification.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:calora/presentation/auth/verify/management/verify_management.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class VerifyManager extends Manager<VerifyState, VerifyEffect> {
  final AuthRepo authRepo;

  VerifyManager(this.authRepo) : super(const VerifyState());

  final TextEditingController controller = TextEditingController();

  final SmsAutofillService _smsAutofill = SmsAutofillService.instance;
  StreamSubscription<String>? _smsSubscription;
  String? _submittedCode;

  void setInitialVerification(Verification initialVerification) {
    emit(state.copyWith(verification: initialVerification));
    _listenForSmsCode();
  }

  void _listenForSmsCode() {
    _smsSubscription ??= _smsAutofill.codes.listen(_applyCode);

    final buffered = _smsAutofill.takeBufferedCode();
    if (buffered != null) {
      _applyCode(buffered);
      return;
    }

    unawaited(_smsAutofill.start());
  }

  void _applyCode(String code) {
    if (isClosed) return;
    controller.text = code;
    verify();
  }

  void resend() {
    final currentVerification = state.verification;
    if (currentVerification == null) return;

    final phone = currentVerification.phone;
    final email = currentVerification.email;

    final Future<Verification> request;
    if (phone != null && phone.isNotEmpty) {
      _listenForSmsCode();
      request = authRepo.sendOtpToPhone(phone);
    } else if (email != null && email.isNotEmpty) {
      request = authRepo.sendOtp(email);
    } else {
      return;
    }

    request.handle(
      onStart: () => emit(state.copyWith(loading: true)),
      onData: (data) {
        _submittedCode = null;
        controller.clear();
        emit(
          state.copyWith(
            loading: false,
            verification: data.copyWith(email: email, phone: phone),
          ),
        );
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
    if (currentVerification == null || isClosed) return;

    final code = controller.text;
    if (state.loading || _submittedCode == code) return;
    _submittedCode = code;

    authRepo
        .signIn(currentVerification, code)
        .handle(
          onStart: () => emit(state.copyWith(loading: true)),
          onData: (hasNewUser) {
            unawaited(_smsAutofill.stop());
            if (hasNewUser) {
              // Meta CompleteRegistration. Lives in `onData`, not `onDone` —
              // `onDone` also runs on failure, which would report a
              // registration that never happened.
              unawaited(
                FacebookAnalyticsService.instance.logCompleteRegistration(
                  method: currentVerification.email == null ? 'phone' : 'email',
                ),
              );
              publish(
                VerifyEffect.openQuestions(currentVerification.email ?? ''),
              );
            } else {
              publish(VerifyEffect.openDashboard());
            }
          },
          onError: (error) {
            _submittedCode = null;
            final e = (error as DioException).response?.data['error'];
            publish(VerifyEffect.showError(e.toString()));
          },
          onDone: () => emit(state.copyWith(loading: false)),
        );
  }

  @override
  Future<void> close() async {
    await _smsSubscription?.cancel();
    await _smsAutofill.stop();
    controller.dispose();
    return super.close();
  }
}
