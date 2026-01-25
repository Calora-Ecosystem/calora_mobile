import 'package:freezed_annotation/freezed_annotation.dart';

part 'promo_code_model.freezed.dart';
part 'promo_code_model.g.dart';

@freezed
sealed class PromoCodeModel with _$PromoCodeModel {
  const factory PromoCodeModel({
    int? id,
    int? amount,
    bool? isActive,
    String? expireAt,
  }) = _PromoCodeModel;

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) => _$PromoCodeModelFromJson(json);
}
