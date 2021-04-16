import 'package:cast/cast.dart';
import 'package:cast/discovery_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlayerSettings extends GetxService {
  PlayerSettings(this.appId);

  final String appId;
  final isConnected = false.obs;
  @override
  void onInit() {
    super.onInit();
    _init();
  }

  void _init() async {
    await CastDiscoveryService().start();
  }

  Future<void> cast(CastDevice device) async {
    final session = await CastSessionManager().startSession(device);

    session.stateStream.listen((state) {
      isConnected(CastSessionState.connected == state);

      if (state == CastSessionState.connected) {
        sendMessage(session);
      }
    });

    session.messageStream.listen((message) {
      print('receive message: $message');
    });

    session.sendMessage(CastSession.kNamespaceReceiver, {
      'type': 'LAUNCH',
      'appId': appId,
    });
  }

  void sendMessage(CastSession session) {
    print('should play video');
    session.sendMessage(CastSession.kNamespaceMedia, {
      'type': 'LOAD',
      'autoPlay': true,
      'currentTime': 0,
      'activeTracks': [],
      'media': {
        'contentId':
            "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_20MB.mp4",
        'contentType': "video/mp4",
        'images': [],
        'title': "Big Buck Bunny",
        'streamType': 'BUFFERED'
      }
    });
    // session.sendMessage('urn:x-cast:namespace-of-the-app', {
    //   'type': 'sample',
    // });
  }
}

class CastIcon extends StatelessWidget {
  CastIcon({Key key, this.onTap, this.connect}) : super(key: key);
  final Function(List<CastDevice>) onTap;
  final Function(CastDevice device) connect;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CastDevice>>(
      stream: CastDiscoveryService().stream,
      initialData: CastDiscoveryService().devices,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return IconButton(
              icon: Icon(
                Icons.cast,
                color: Colors.white,
              ),
              onPressed: onTap != null ? () => onTap(snapshot.data) : null);
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
