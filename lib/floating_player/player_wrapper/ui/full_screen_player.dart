import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player.dart';

class FullScreenPlayer extends StatefulWidget {
  FullScreenPlayer({Key key}) : super(key: key);

  @override
  _FullScreenPlayerState createState() {
    return _FullScreenPlayerState();
  }
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.restoreSystemUIOverlays();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: Container(
      //   color: Colors.red,
      // ),
      body: Hero(
        tag: 'playerv2',
        child: Player(
          usePlayerPlaceHolder: false,
        ),
      ),
    );
  }
}
