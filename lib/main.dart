import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'floating_player/player_wrapper/navigation/player_nav.dart';

void main() {
  runApp(MyApp());
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
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: Stack(children: [MyHomePage()]),
            popGesture: true,
          ),
          // Directionality(
          //   textDirection: TextDirection.rtl,
          //   child: SizedBox(
          //     width: 200,
          //     height: 200,
          //     child: Navigator(
          //       key: playerOverFlowKey,
          //       onGenerateRoute: (RouteSettings settings) {
          //         if (settings.name == '/') {
          //           return MaterialPageRoute(builder: (context) {
          //             return Container(
          //               width: 200,
          //               color: Colors.red,
          //               child: Text('Player ${settings.name} start'),
          //             );
          //           });
          //         }
          //         return MaterialPageRoute(builder: (context) {
          //           return Container(
          //             width: 200,
          //             color: Colors.red,
          //             child: Text('Player ${settings.name} }'),
          //           );
          //         });
          //       },
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title: 'Floating Player'}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Widget player;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                  child: Text('Open Dynamic Pages'),
                ),
              ],
            ),
          ),
        ).attachPLayerAware(),
      ],
    );
  }
}

class SecondPage extends StatefulWidget {
  SecondPage({Key key, this.title: 'No title'}) : super(key: key);
  final String title;

  @override
  _SecState createState() => _SecState();
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
                PLayerNav.showPlayer(context, null, null);
              },
              child: Text('Open Floating Player Screen'),
            ),
            RaisedButton(
              onPressed: () {
                Get.to(
                    SecondPage(
                      title: widget.title + ' |',
                    ),
                    preventDuplicates: false);
              },
              child: Text('Open New Page'),
            ),
          ],
        ),
      ),
    ).attachPLayerAware();
  }
}
