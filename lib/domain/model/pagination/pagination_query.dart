import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_query.freezed.dart';
part 'pagination_query.g.dart';

@freezed
sealed class PaginationQuery with _$PaginationQuery {
  const factory PaginationQuery({
    @JsonKey(name: 'FilteringExpression') List<String>? filteringExpression,
    @JsonKey(name: 'Skip') int? skip,
    @JsonKey(name: 'Take') int? take,
    @JsonKey(name: 'SortPropName') String? sortPropName,
    @JsonKey(name: 'SortDirection') String? sortDirection,
  }) = _PaginationQuery;

  factory PaginationQuery.fromJson(Map<String, dynamic> json) => _$PaginationQueryFromJson(json);
}
