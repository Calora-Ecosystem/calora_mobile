import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// 2-column grid of food cards driven by a [PagingController].
///
/// Handles infinite scrolling, shimmer skeletons for the first page,
/// a bottom spinner while a later page is loading, an empty-state
/// message when the result set is empty, and a "no more items"
/// terminator at the end of the list.
class PaginatedFoodGrid extends StatelessWidget {
  final PagingController<int, FoodModel> controller;
  final ValueChanged<FoodModel> onFoodSelected;

  const PaginatedFoodGrid({
    super.key,
    required this.controller,
    required this.onFoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => controller.refresh(),
      child: PagedGridView<int, FoodModel>(
        pagingController: controller,
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        builderDelegate: PagedChildBuilderDelegate<FoodModel>(
          itemBuilder: (context, food, _) => _FoodCard(
            food: food,
            onTap: () => onFoodSelected(food),
          ),
          firstPageProgressIndicatorBuilder: (_) => const _ShimmerGrid(),
          newPageProgressIndicatorBuilder: (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          noItemsFoundIndicatorBuilder: (_) => Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Strings.mealsAreNotAvailable
                  .text(14, 18, 500)
                  .c(context.colors.textSub),
            ),
          ),
          firstPageErrorIndicatorBuilder: (_) => _ErrorRetry(
            onRetry: controller.retryLastFailedRequest,
          ),
          newPageErrorIndicatorBuilder: (_) => _ErrorRetry(
            onRetry: controller.retryLastFailedRequest,
          ),
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback onTap;

  const _FoodCard({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 152,
        decoration: BoxDecoration(
          color: context.colors.backgroundElevation,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CustomCachedNetworkImage.banner(
                radius: 16,
                height: 120,
                imageUrl: food.coverUrl,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: food.name
                  .text(14, 16, 600)
                  .c(context.colors.textStrong)
                  .copyWith(overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// First-page loading placeholder.
///
/// Rendered by `infinite_scroll_pagination` inside a `SliverFillRemaining`,
/// which queries intrinsic dimensions on its child. A `GridView` (which
/// wraps a `Viewport`) doesn't support intrinsic dimensions and would
/// crash with `RenderShrinkWrappingViewport does not support returning
/// intrinsic dimensions.`, so this is plain `Column` + `Row`s.
class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    Widget cell() => Expanded(
          child: ShimmerWrapper(
            loading: true,
            type: ShimmerType.backgroundElevation,
            shimmerChild: ShimmerChild(height: 152),
            child: const SizedBox.shrink(),
          ),
        );

    Widget row() => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [cell(), const SizedBox(width: 12), cell()]),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [row(), row(), row()],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 32, color: context.colors.textSub),
          const SizedBox(height: 8),
          Strings.tryAgain
              .text(14, 18, 500)
              .c(context.colors.textSub),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Strings.tryAgain
                .text(14, 18, 600)
                .c(context.colors.accentSub),
          ),
        ],
      ),
    );
  }
}
