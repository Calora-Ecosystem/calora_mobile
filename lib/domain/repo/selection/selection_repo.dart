import 'package:calora/domain/model/selection/Selection.dart';

abstract class SelectionRepo {
  Future<List<Selection>> getSelections(Selection selection);
}
