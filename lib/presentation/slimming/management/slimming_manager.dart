import 'package:calora/domain/repo/course/video_course_repo.dart';
import 'package:calora/presentation/slimming/management/slimming_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class SlimmingManager extends Manager<SlimmingState, SlimmingEffect> {
  final VideoCourseRepo _repo;
  SlimmingManager(this._repo) : super(SlimmingState());

  Future<void> getVideoCourses() async {
    await _repo.getVideoCourses().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) => emit(state.copyWith(videoCourse: data, isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }
}
