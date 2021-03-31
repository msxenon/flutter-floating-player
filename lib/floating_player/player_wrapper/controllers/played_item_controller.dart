import 'package:flutter/cupertino.dart';

class SavePosition<T> {
  final int seconds;
  final T videoItem;
  final String itemId;
  final int totalSeconds;

  SavePosition(
      {@required this.seconds,
      @required this.totalSeconds,
      @required this.videoItem,
      @required this.itemId});

  @override
  String toString() {
    return 'SavePosition{seconds: $seconds, videoItem: $videoItem, itemId: $itemId, totalSeconds: $totalSeconds}';
  }
}

typedef SavePosFunc<T> = void Function(SavePosition<T>);

class PlayerData<VI, SI> {
  const PlayerData(
      {this.videoItem,
      this.itemId,
      this.playType = PlayType.video,
      this.onDispose,
      this.subItem,
      this.savePosition,
      this.videoRes,
      this.subtitle,
      @required this.itemTitle,
      this.useMockData: true,
      this.startPosition});
  final Map<String, String> videoRes;
  final String subtitle;
  final bool useMockData;
  final Duration startPosition;
  final VI videoItem;
  final String itemId;

  final PlayType playType;
  final void Function(SavePosition<dynamic>) savePosition;
  final Function onDispose;
  final String itemTitle;
  final SI subItem;

  @override
  String toString() {
    return 'PlayerData{videoRes: $videoRes, subtitle: $subtitle, useMockData: $useMockData, startPosition: $startPosition,   itemId: $itemId, playType: $playType, savePosition: $savePosition, onDispose: $onDispose, itemTitle: $itemTitle,  }';
  }
}

enum PlayType { live, video }
