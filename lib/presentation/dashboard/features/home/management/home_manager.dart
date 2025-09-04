import 'package:calora/presentation/dashboard/features/home/management/home_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class HomeManager extends Manager<HomeState, HomeEffect> {

  HomeManager() : super(const HomeState());

}