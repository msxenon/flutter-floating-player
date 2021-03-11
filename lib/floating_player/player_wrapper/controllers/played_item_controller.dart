class SavePosition<T> {
  final int? seconds;
  final T? videoItem;
  final int? itemId;

  @override
  String toString() {
    return 'SavePosition{seconds: $seconds, videoItem: $videoItem, itemId: $itemId}';
  }

  SavePosition({this.seconds, this.videoItem, this.itemId});
}

typedef SavePosFunc<T> = void Function(SavePosition<T>);

class PlayerData<T> {
  final Map<String, String>? videoRes;
  final String? subtitle;
  final bool useMockData;
  final Duration? startPosition;
  final T? videoItem;
  final int? itemId;
  final void Function(SavePosition<dynamic>)? savePosition;
  final Function? onDispose;
  const PlayerData(
      {this.videoItem,
      this.itemId,
      this.onDispose,
      this.savePosition,
      this.videoRes,
      this.subtitle,
      this.useMockData: true,
      this.startPosition});
}
