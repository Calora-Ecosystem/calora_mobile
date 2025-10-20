import 'package:calora/domain/model/profile/profile.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'base_store.dart';

@lazySingleton
class GenderStore extends BaseStore<Gender> {
  GenderStore()
    : super(
        'user_gender',
        serialize: (value) => value.name,
        deserialize: (value) {
          if (value == null) return Gender.Male;

          final normalized = value.toString().toLowerCase();

          if (normalized == 'male') return Gender.Male;
          if (normalized == 'female') return Gender.Female;

          return Gender.Male;
        },
      );

  Future<void> setFromString(String genderString) async {
    final normalized = genderString.toLowerCase();
    final gender = normalized == 'female' ? Gender.Female : Gender.Male;
    await set(gender);
  }
}

final genderStore = GetIt.I<GenderStore>();
