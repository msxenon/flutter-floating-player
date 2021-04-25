import 'package:flutter/cupertino.dart';

class SavePosition<T> {
  SavePosition(
      {@required this.seconds,
      @required this.totalSeconds,
      @required this.videoItem,
      @required this.itemId});
  final int seconds;
  final T videoItem;
  final String itemId;
  final int totalSeconds;

  @override
  String toString() {
    // ignore: lines_longer_than_80_chars
    return 'SavePosition{seconds: $seconds, videoItem: $videoItem, itemId: $itemId, totalSeconds: $totalSeconds}';
  }
}
