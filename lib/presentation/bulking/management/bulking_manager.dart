import 'package:calora/domain/repo/course/video_course_repo.dart';
import 'package:calora/presentation/bulking/management/bulking_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class BulkingManager extends Manager<BulkingState, BulkingEffect> {
  final VideoCourseRepo _repo;
  BulkingManager(this._repo) : super(BulkingState());

  Future<void> getVideoCourses() async {
    await _repo.getBulkingCourses().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) => emit(state.copyWith(videoCourse: data, isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }
}
