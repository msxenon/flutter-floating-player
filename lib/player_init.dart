import 'package:cast/cast.dart';
import 'package:cast/discovery_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlayerCastSettings extends GetxService {
  ///https://developers.google.com/android/reference/com/google/android/gms/cast/CastMediaControlIntent#public-static-final-string-default_media_receiver_application_id
  PlayerCastSettings({this.appId = 'CC1AD845', this.enableCast = true});
  final bool enableCast;
  final String appId;
  final isConnected = false.obs;
  @override
  void onInit() {
    super.onInit();

    _init();
  }

  void _init() async {
    if (enableCast) {
      await CastDiscoveryService().start();
    }
  }

  CastSession _session;
  Future<void> cast(CastDevice device, Map<String, dynamic> payload) async {
    if (!enableCast) {
      return;
    }
    _session = await CastSessionManager().startSession(device);

    _session?.stateStream?.listen((state) {
      debugPrint('newState $state ===========================================');
      if (state == CastSessionState.connected) {
        sendMessage(payload);
      }
      isConnected(CastSessionState.connected == state);
    });

    _session?.messageStream?.listen((message) {
      debugPrint('receive message Start======================================');
      debugPrint('$message');
      debugPrint('receive message End========================================');
    });

    _session?.sendMessage(CastSession.kNamespaceReceiver, {
      'type': 'LAUNCH',
      'appId': appId,
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    debugPrint('message will be send ========================================');
    debugPrint('$message');
    _session?.sendMessage(CastSession.kNamespaceMedia, message);
    debugPrint('message sent ================================================');
  }

  void disconnect() async {
    _session?.sendMessage(CastSession.kNamespaceConnection, {
      'type': 'CLOSE',
    });
    isConnected(false);
  }
}

class CastIcon extends StatelessWidget {
  CastIcon({Key key, this.onTap, this.connect}) : super(key: key);
  final Function(List<CastDevice>) onTap;
  final Function(CastDevice device) connect;
  final PlayerCastSettings playerCastSettings = Get.find<PlayerCastSettings>();
  @override
  Widget build(BuildContext context) {
    if (!playerCastSettings.enableCast) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<List<CastDevice>>(
      stream: CastDiscoveryService().stream,
      initialData: CastDiscoveryService().devices,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return IconButton(
              icon: const Icon(
                Icons.cast,
                color: Colors.white,
              ),
              onPressed: onTap != null ? () => onTap(snapshot.data) : null);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
