import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/model/premium/family_coupon.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class FamilyCouponsManager extends Manager<List<FamilyCoupon>, Never> {
  FamilyCouponsManager(this._repo) : super(const []);

  final PremiumRepo _repo;

  @override
  void initialize() => load();

  Future<void> load() async {
    try {
      final coupons = await _repo.getMyCoupons();
      if (isClosed) return;
      emit(sorted(coupons));
    } catch (_) {}
  }

  static List<FamilyCoupon> sorted(List<FamilyCoupon> coupons) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return [...coupons]..sort((a, b) {
      final byStatus = _rank(a.status).compareTo(_rank(b.status));
      if (byStatus != 0) return byStatus;
      return (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch);
    });
  }

  static int _rank(FamilyCodeStatus status) => switch (status) {
    FamilyCodeStatus.active => 0,
    FamilyCodeStatus.redeemed => 1,
    FamilyCodeStatus.expired => 2,
  };
}
