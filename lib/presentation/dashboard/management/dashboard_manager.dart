import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class DashboardManager extends Manager<DashboardState, DashboardEffect> {

  DashboardManager() : super(const DashboardState());

}