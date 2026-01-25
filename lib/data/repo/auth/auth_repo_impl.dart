import 'dart:io';

import 'package:calora/data/api/auth_api.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
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
  final CommonStore _commonStore;

  AuthRepoImpl(this._api, this._store, this._commonStore);

  @override
  Future<Verification> sendOtp(String email) async {
    final response = await _api.sendOtp(email);
    final verification = Verification.fromJson(response.data['content']);
    return verification.copyWith(email: email);
  }

  @override
  Future<Verification> sendOtpToPhone(String phone) async {
    return await _api.sendOtpToPhone(phone);
  }

  @override
  Future<bool> signIn(Verification verification, String code) async {
    final device = await _getDevicePayload();

    final response = await _api.signIn(
      email: verification.email,
      phone: verification.phone,
      verificationCode: verification.verificationCode!,
      code: code,
      key: device.key,
      name: device.name,
      fcmToken: device.fcmToken,
    );

    return _saveAuthAndReturnHasNewUser(response.data);
  }

  @override
  Future<bool> signInGoogle(String ssoToken) async {
    final device = await _getDevicePayload();

    final response = await _api.signInGoogle(
      ssoToken: ssoToken,
      key: device.key,
      name: device.name,
      fcmToken: device.fcmToken,
    );

    return _saveAuthAndReturnHasNewUser(response.data);
  }

  @override
  Future<bool> signInApple(String ssoToken) async {
    final device = await _getDevicePayload();

    final response = await _api.signInApple(
      ssoToken: ssoToken,
      key: device.key,
      name: device.name,
      fcmToken: device.fcmToken,
    );

    return _saveAuthAndReturnHasNewUser(response.data);
  }

  Future<_DevicePayload> _getDevicePayload() async {
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

    return _DevicePayload(
      key: installationId,
      name: deviceName,
      fcmToken: fcmToken,
    );
  }

  bool _saveAuthAndReturnHasNewUser(dynamic responseData) {
    final Map<String, dynamic> content = (responseData as Map<String, dynamic>)['content'] as Map<String, dynamic>;

    final token = Token.fromJson(content);

    _store.token.set(token);

    final bool hasNewUser = content['hasNewUser'] as bool;
    _commonStore.isQuestionaryFinished.set(!hasNewUser);

    return hasNewUser;
  }
}

class _DevicePayload {
  final String key;
  final String name;
  final String? fcmToken;

  const _DevicePayload({
    required this.key,
    required this.name,
    required this.fcmToken,
  });
}
