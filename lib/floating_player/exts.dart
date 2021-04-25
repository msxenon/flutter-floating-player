import 'package:flutter_player/subtitle/subtitle_controller.dart';

extension SubtitleTypeX on SubtitleType {
  String getName() => toString().split('.').last;
}
