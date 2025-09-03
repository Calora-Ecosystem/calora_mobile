import 'package:freezed_annotation/freezed_annotation.dart';

part 'input_name_management.freezed.dart';

@freezed
abstract class InputNameState with _$InputNameState {
  const factory InputNameState({@Default("") String userName}) =_InputNameState;
}

@freezed
sealed class InputNameEffect with _$InputNameEffect {
  const factory InputNameEffect() = _InputNameEffect;
}
