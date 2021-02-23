import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class Player extends StatelessWidget {
  final bool usePlayerPlaceHolder;
  final Widget customPlayer;

  const Player({Key key, this.usePlayerPlaceHolder: false, this.customPlayer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return usePlayerPlaceHolder
        ? Placeholder()
        : customPlayer ??
            VlcPlayerWithControls(
              controller: VlcPlayerController.network(
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
                hwAcc: HwAcc.FULL,
                autoPlay: true,
                options: VlcPlayerOptions(),
              ),
            );
  }
}
