import 'package:calora/presentation/account/detail/management/account_detail_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class AccountDetailManager extends Manager<AccountDetailState, AccountDetailEffect> {

  AccountDetailManager() : super(const AccountDetailState());

}