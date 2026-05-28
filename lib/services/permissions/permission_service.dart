import 'package:photo_manager/photo_manager.dart';
import '../../shared/models/app_session.dart';

class PermissionService {
  PermissionStatus _mapState(PermissionState state) {
    if (state.isAuth) {
      return PermissionStatus.granted;
    } else if (state == PermissionState.limited) {
      return PermissionStatus.limited;
    } else if (state == PermissionState.notDetermined) {
      return PermissionStatus.notAsked;
    } else {
      return PermissionStatus.denied;
    }
  }

  /// Request gallery permission from the user.
  Future<PermissionStatus> request() async {
    final state = await PhotoManager.requestPermissionExtend();
    return _mapState(state);
  }

  /// Get the current permission status without prompting.
  Future<PermissionStatus> getStatus() async {
    final state = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );
    return _mapState(state);
  }
}
