import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'auth_management.dart';

@injectable
class AuthManager extends Manager<AuthState, AuthEffect> {
  AuthManager(this._repo) : super(const AuthState());

  final AuthRepo _repo;

  final controller = TextEditingController();

  void setChecked(bool? value) => emit(state.copyWith(checked: value == true));

  Future<void> login() => _repo
      .login(controller.text)
      .handle(
        onStart: () => emit(state.copyWith(loading: true)),
        onData: (verification) => publish(AuthEffect.verify(verification)),
        onDone: () => emit(state.copyWith(loading: false)),
      );

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}
