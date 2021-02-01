import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:get/get.dart';

class FloatingViewController extends GetxController {
  static const String detailsControllerId = 'detailsController1';
  VlcPlayerController videoPlayerController;
  RxBool isMaximized = true.obs;
  RxBool _showControllerView = false.obs;
  RxBool get showControllerView => _showControllerView;
  bool get showDetails => detailsTopPadding > 0;
  double detailsTopPadding = 0;
  set showControllerViewValue(bool value) {
    _showControllerView.value = value && isMaximized.value;
  }

  @override
  void onInit() {
    videoPlayerController = VlcPlayerController.network(
      'https://media.w3.org/2010/05/sintel/trailer.mp4',
      hwAcc: HwAcc.FULL,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
    super.onInit();
  }

  @override
  void onClose() {
    videoPlayerController.stopRendererScanning();
    videoPlayerController.removeListener(() {});
    super.onClose();
  }

  void onMaximizedStateChange(bool _isMaximized) {
    isMaximized.value = _isMaximized;
  }

  void onDraggingChange(bool dragging) {}

  void setPlayerHeight(double d) {
    detailsTopPadding = d;
    update(List.of([detailsControllerId]));
  }
}

class PlayerControllersController extends GetxController {
  FloatingViewController _floatingViewController = Get.find();
  bool get canShowControllers => _floatingViewController.isMaximized.value;
  @override
  void onInit() {
    super.onInit();
  }
}
