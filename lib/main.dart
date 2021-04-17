import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/mock_data.dart';
import 'package:flutter_player/player_init.dart';
import 'package:get/get.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:overlay_support/overlay_support.dart';

import 'floating_player/player_wrapper/logic/player_data.dart';
import 'floating_player/player_wrapper/navigation/player_nav.dart';

void main() {
  runApp(OverlaySupport(child: MyApp()));
}

void initPlayer() {
  kNotificationSlideDuration = const Duration(milliseconds: 0);
  kNotificationDuration = const Duration(milliseconds: 0);
}

GlobalKey<NavigatorState> playerOverFlowKey = GlobalKey();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          GetMaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.standard,
            ),
            onInit: () {
              Get.put(PlayerCastSettings());
            },
            home: MyHomePage(),
            popGesture: false,
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title = 'Floating Player'}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Widget player;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await MoveToBackground.moveTaskToBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  Get.to(SecondPage(
                    title: 'Dynamic Page',
                  ));
                },
                child: const Text('Open Dynamic Pages'),
              ),
            ],
          ),
        ),
      ).attachPLayerAware(),
    );
  }
}

class SecondPage extends StatefulWidget {
  SecondPage({Key key, this.title = 'No title'}) : super(key: key);
  final String title;

  @override
  _SecState createState() => _SecState();
}

void showPLayer(String id,String subtitleUrl) {
  PLayerNav.showPlayer(
    bgColor: Colors.black,
    playerData: PlayerData<String, String>(
        itemTitle: 'BigBuckBunny / VttSUB',
        startPosition: const Duration(seconds: 20),
        onDispose: () {},
        itemId: id,
        subtitle: subtitleUrl,
        videoItem: 'movieX',
        savePosition: (x) {
          debugPrint('savePos callback $x');
        }),
    details: (_) => FlatButton(
        onPressed: () {
          showPLayer('${id}kdk',subtitleUrl);
        },
        child: const Text(
          'Play nested',
          style: TextStyle(color: Colors.white),
        ),
    ),
  );
}

class _SecState extends State<SecondPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              onPressed: () {
                showPLayer('33',null);
              },
              child: const Text('Open Floating Player Screen / No CC'),
            ),
            RaisedButton(
              onPressed: () {
                showPLayer('44',MockData.testVtt);
              },
              child: const Text('Open Floating Player Screen'),
            ),
            RaisedButton(
              onPressed: () {
                Get.to(
                    SecondPage(
                      title: '${widget.title} |',
                    ),
                    preventDuplicates: false);
              },
              child: const Text('Open New Page'),
            ),
          ],
        ),
      ),
    ).attachPLayerAware();
  }
}
