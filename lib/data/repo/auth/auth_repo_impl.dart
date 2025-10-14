import 'dart:io';

import 'package:calora/data/api/auth_api.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:calora/domain/model/verification/verification.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: AuthRepo)
class AuthRepoImpl extends AuthRepo {
  final AuthApi _api;
  final AuthStore _store;

  AuthRepoImpl(this._api, this._store);

  @override
  Future<Verification> sendOtp(String email) async {
    final response = await _api.sendOtp(email);
    final verification = Verification.fromJson(response.data['content']);
    return verification.copyWith(email: email);
  }

  @override
  Future<void> signIn(Verification verification, String code) async {
    final installationId = await FirebaseInstallations.instance.getId();

    final String deviceName;
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      deviceName = android.model;
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      deviceName = ios.utsname.machine;
    } else {
      deviceName = 'N/A';
    }

    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    final apnsAvailable = apnsToken != null || !Platform.isIOS;
    String? fcmToken;
    if (apnsAvailable) {
      fcmToken = await FirebaseMessaging.instance.getToken();
    }

    final response = await _api.signIn(
      email: verification.email!,
      verificationCode: verification.verificationCode!,
      code: code,
      key: installationId,
      name: deviceName,
      fcmToken: fcmToken,
    );

    final token = Token.fromJson(response.data['content']);
    await _store.token.set(token);
    await _store.isLogin.set(true);
  }

  @override
  Future<bool> checkExtras() async {
    try {
      await _api.getUserExtras();
      return true; // user extras mavjud
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return false; // mavjud emas
      }
      rethrow;
    }
  }

  @override
  Future<void> saveExtras(Map<String, dynamic> extras) async {
    await _api.postUserExtras(extras);
  }

  @override
  Future<void> fetchUser() async {
    await _api.getUserMe();
  }
}
