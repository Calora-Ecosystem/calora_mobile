import 'package:calora/domain/repo/home/home_repo.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:permission_handler/permission_handler.dart';

@injectable
class HomeManager extends Manager<HomeState, HomeEffect> {
  final HomeRepo _homeRepo;

  HomeManager(this._homeRepo) : super(const HomeState());

  void getUserGender() {
    _homeRepo.getUserGender();
  }

  Future<void> requestPedometerPermissions() async {
    await [
      Permission.activityRecognition,
      Permission.sensors,
      Permission.locationWhenInUse,
    ].request();
  }
}
