class PlayerData {
  final Map<String, String> videoRes;
  final String subtitle;
  final bool useMockData;
  final Duration playerPosition;

  const PlayerData(
      {this.videoRes,
      this.subtitle,
      this.useMockData: true,
      this.playerPosition});
}
