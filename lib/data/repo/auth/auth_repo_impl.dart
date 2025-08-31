import 'dart:io';

import 'package:calora/data/api/auth_api.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:calora/domain/model/verification/verification.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: AuthRepo)
class AuthRepoImpl extends AuthRepo {
  final AuthApi _api;
  final AuthStore _store;

  AuthRepoImpl(this._api, this._store);

  @override
  Future<Verification> login(String email) async {
    final response = await _api.login(email);
    final verification = Verification.fromJson(response.data['content']);
    return verification.copyWith(email: email);
  }

  @override
  Future<Verification> register(String email, String name) async {
    final response = await _api.register(email, name);
    final verification = Verification.fromJson(response.data['content']);
    return verification.copyWith(email: email);
  }

  @override
  Future<void> verify(Verification verification, String code) async {
    final installationId = await FirebaseInstallations.instance.getId();

    final String deviceName;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.utsname.machine;
    } else {
      deviceName = 'N/A';
    }

    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    final apnsAvailable = apnsToken != null || !Platform.isIOS;
    String? fcmToken;
    if (apnsAvailable) {
      fcmToken = await FirebaseMessaging.instance.getToken();
    }

    final response = await _api.verify(
      email: verification.email!,
      verificationCode: verification.verificationCode!,
      code: code,
      key: installationId,
      name: deviceName,
      fcmToken: fcmToken,
    );

    final token = Token.fromJson(response.data['content']);
    await _store.token.set(token);
  }
}
