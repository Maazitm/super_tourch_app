import 'package:get/get.dart';
import 'package:tourch_app/home_screen/home_controller.dart';


class TorchBinding extends Bindings {
  @override
  void dependencies() {
    // This tells GetX how to build your controller,
    // so it's ready when the screen asks for it.
    Get.lazyPut<TorchController>(() => TorchController());
  }
}
