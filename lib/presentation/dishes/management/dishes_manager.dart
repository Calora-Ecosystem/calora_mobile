import 'package:calora/common/service/pagination_service.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/pagination/pagination_query.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:calora/presentation/dishes/management/dishes_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class DishesManager extends Manager<DishesState, DishesEffect> {
  final CaloriesRepo _caloriesRepo;

  /// Set lazily from [bind] so the paginator can pre-load
  /// `FilteringExpression=categoryId==<id>` on first build.
  PaginationService<FoodModel>? _paginator;

  PaginationService<FoodModel> get paginator => _paginator!;

  DishesManager(this._caloriesRepo) : super(const DishesState());

  /// Called from [DishesPage.init] with the selected category id.
  /// Idempotent — calling more than once for the same id is a no-op.
  void bindCategory(int categoryId) {
    if (_paginator != null) return;
    _paginator = PaginationService<FoodModel>(
      fetchData: (query) => _fetchPage(query, categoryId),
      initialQuery: PaginationQuery(
        filteringExpression: ['categoryId==$categoryId'],
      ),
    );
  }

  Future<PaginatedResponse<FoodModel>> _fetchPage(
    PaginationQuery query,
    int categoryId,
  ) {
    return _caloriesRepo.fetchFoodsPaged(query: query);
  }

  void getFoodById(int id, bool isFavourite) {
    _caloriesRepo
        .fetchFoodById(id)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (value) {
            emit(state.copyWith(food: value, isLoading: false));
            publish(DishesEffect.openInfoSheet(value, isFavourite));
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<bool> saveMenuItem(MenuInfo item) async {
    bool success = false;
    await _caloriesRepo
        .saveMenuItem(item)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (_) => success = true,
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) {
            success = false;
            emit(state.copyWith(isLoading: false));
          },
        );
    return success;
  }

  void addFavourite(int id) {
    _caloriesRepo
        .addFavourite(id)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  @override
  Future<void> close() {
    _paginator?.dispose();
    return super.close();
  }
}
