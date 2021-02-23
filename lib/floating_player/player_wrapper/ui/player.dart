import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class Player extends StatefulWidget {
  final bool usePlayerPlaceHolder;

  Player({Key key, this.usePlayerPlaceHolder: false}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  @override
  Widget build(BuildContext context) {
    log('player build');
    return widget.usePlayerPlaceHolder
        ? Placeholder()
        : VlcPlayerWithControls(
            key: Key('VlcPlayerWithControls'),
            controller: VlcPlayerController.network(
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
              hwAcc: HwAcc.FULL,
              autoPlay: true,
              options: VlcPlayerOptions(),
            ),
          );
  }
}
