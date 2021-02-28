import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:get/get.dart';

import 'controls_overlay.dart';

class VlcPlayerWithControls extends StatefulWidget {
  final VlcPlayerController controller;

  VlcPlayerWithControls({
    Key key,
    @required this.controller,
  })  : assert(controller != null, 'You must provide a vlc controller'),
        super(key: key);

  @override
  VlcPlayerWithControlsState createState() => VlcPlayerWithControlsState();
}

class VlcPlayerWithControlsState extends State<VlcPlayerWithControls> with AutomaticKeepAliveClientMixin {
  VlcPlayerController _controller;
  final FloatingViewController _floatingViewController = Get.find();

  //
  final double initSnapshotRightPosition = 10;
  final double initSnapshotBottomPosition = 10;

  //
  double sliderValue = 0.0;
  String position = '';
  String duration = '';
  int numberOfCaptions = 0;
  int numberOfAudioTracks = 0;

  //
  List<double> playbackSpeeds = [0.5, 1.0, 2.0];
  int playbackSpeedIndex = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(listener);
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    super.dispose();
  }

  void listener() async {
    if (!mounted) return;
    //
    if (_controller.value.isInitialized) {
      var oPosition = _controller.value.position;
      var oDuration = _controller.value.duration;
      if (oPosition != null && oDuration != null) {
        if (oDuration.inHours == 0) {
          var strPosition = oPosition.toString().split('.')[0];
          var strDuration = oDuration.toString().split('.')[0];
          position = "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
          duration = "${strDuration.split(':')[1]}:${strDuration.split(':')[2]}";
        } else {
          position = oPosition.toString().split('.')[0];
          duration = oDuration.toString().split('.')[0];
        }
        sliderValue = _controller.value.position.inSeconds.toDouble();
      }
      numberOfCaptions = _controller.value.spuTracksCount;
      numberOfAudioTracks = _controller.value.audioTracksCount;
      //
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      return Stack(
        children: [
          Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                Center(
                  child: VlcPlayer(
                    controller: _controller,
                    aspectRatio: 16 / 9,
                    placeholder: Center(child: CircularProgressIndicator()),
                  ),
                ),
                Visibility(child: ControlsOverlay(controller: _controller), visible: _floatingViewController.controllersCanBeVisible.value),
              ],
            ),
          ),
          Visibility(
            visible: _floatingViewController.controllersCanBeVisible.value,
            child: Container(
              height: 50,
              color: Colors.black87,
              child: Row(
                children: [
                  ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            tooltip: 'Get Subtitle Tracks',
                            icon: Icon(Icons.closed_caption),
                            color: Colors.white,
                            onPressed: () => showFloatingBottomSheet(context, _floatingViewController, null),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                              child: Text(
                                '$numberOfCaptions',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          IconButton(
                            tooltip: 'Get Audio Tracks',
                            icon: Icon(Icons.audiotrack),
                            color: Colors.white,
                            onPressed: () {
                              _getAudioTracks();
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                                child: Text(
                                  '$numberOfAudioTracks',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(Icons.timer),
                            color: Colors.white,
                            onPressed: () async {
                              playbackSpeedIndex++;
                              if (playbackSpeedIndex >= playbackSpeeds.length) {
                                playbackSpeedIndex = 0;
                              }
                              return await _controller.setPlaybackSpeed(playbackSpeeds.elementAt(playbackSpeedIndex));
                            },
                          ),
                          Positioned(
                            bottom: 7,
                            right: 3,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                                child: Text(
                                  '${playbackSpeeds.elementAt(playbackSpeedIndex)}x',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Get Snapshot',
                        icon: Icon(Icons.camera),
                        color: Colors.white,
                        onPressed: () {
                          _createCameraImage();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.cast),
                        color: Colors.white,
                        onPressed: () async {
                          _getRendererDevices();
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Size: ' + (_controller.value.size?.width?.toInt() ?? 0).toString() + 'x' + (_controller.value.size?.height?.toInt() ?? 0).toString(),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Status: ' + _controller.value.playingState.toString().split('.')[1],
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Visibility(
              visible: _floatingViewController.controllersCanBeVisible.value,
              child: Container(
                height: 50,
                color: Colors.black87,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      color: Colors.white,
                      icon: _controller.value.isPlaying ? Icon(Icons.pause_circle_outline) : Icon(Icons.play_circle_outline),
                      onPressed: () async {
                        return _controller.value.isPlaying ? await _controller.pause() : await _controller.play();
                      },
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            position,
                            style: TextStyle(color: Colors.white),
                          ),
                          Expanded(
                            child: Slider(
                              activeColor: Colors.redAccent,
                              inactiveColor: Colors.white70,
                              value: sliderValue,
                              min: 0.0,
                              max: _controller.value.duration == null ? 1.0 : _controller.value.duration.inSeconds.toDouble(),
                              onChanged: (progress) {
                                setState(() {
                                  sliderValue = progress.floor().toDouble();
                                });
                                //convert to Milliseconds since VLC requires MS to set time
                                _controller.setTime(sliderValue.toInt() * 1000);
                              },
                            ),
                          ),
                          Text(
                            duration,
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.fullscreen),
                      color: Colors.white,
                      onPressed: () => _floatingViewController.toggleFullScreen(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _getSubtitleTracks() async {
    if (!_controller.value.isPlaying) return;

    var subtitleTracks = await _controller.getSpuTracks();
    //
    if (subtitleTracks != null && subtitleTracks.isNotEmpty) {
      var selectedSubId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Subtitle'),
            content: Container(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: subtitleTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < subtitleTracks.keys.length ? subtitleTracks.values.elementAt(index).toString() : 'Disable',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < subtitleTracks.keys.length ? subtitleTracks.keys.elementAt(index) : -1,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      if (selectedSubId != null) await _controller.setSpuTrack(selectedSubId);
    }
  }

  void _getAudioTracks() async {
    if (!_controller.value.isPlaying) return;

    var audioTracks = await _controller.getAudioTracks();
    //
    if (audioTracks != null && audioTracks.isNotEmpty) {
      var selectedAudioTrackId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Audio'),
            content: Container(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: audioTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < audioTracks.keys.length ? audioTracks.values.elementAt(index).toString() : 'Disable',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < audioTracks.keys.length ? audioTracks.keys.elementAt(index) : -1,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      if (selectedAudioTrackId != null) {
        await _controller.setAudioTrack(selectedAudioTrackId);
      }
    }
  }

  void _getRendererDevices() async {
    var castDevices = await _controller.getRendererDevices();
    //
    if (castDevices != null && castDevices.isNotEmpty) {
      var selectedCastDeviceName = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Display Devices'),
            content: Container(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: castDevices.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < castDevices.keys.length ? castDevices.values.elementAt(index).toString() : 'Disconnect',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < castDevices.keys.length ? castDevices.keys.elementAt(index) : null,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      await _controller.castToRenderer(selectedCastDeviceName);
    } else {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('No Display Device Found!')));
    }
  }

  void _createCameraImage() async {
    // var snapshot = await _controller.takeSnapshot();
    // _overlayEntry?.remove();
    // _overlayEntry = _createSnapshotThumbnail(snapshot);
    // Overlay.of(context).insert(_overlayEntry);
    // _floatingViewController.showOverlay(context, (context) => null)
  }
}

showFloatingBottomSheet(BuildContext context, FloatingViewController floatingViewController, List<Widget> list) {
  floatingViewController.showOverlay(context, (context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => floatingViewController.removeOverlay(),
        child: Container(
          constraints: BoxConstraints.expand(),
          color: Colors.black.withOpacity(0.3),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: FloatingBottomSheet(
                    children: (list ??
                        [
                          FloatingSheetListTile(
                            floatingViewController: floatingViewController,
                            title: 'Captions'.tr,
                            icon: Icons.closed_caption_outlined,
                            titleStatus: floatingViewController.playerSettingsController.getCaptionStringValue(),
                            onTap: floatingViewController.playerSettingsController.isEnabled == null
                                ? null
                                : () {
                                    showFloatingBottomSheet(context, floatingViewController, [
                                      FloatingSheetListTile(
                                        floatingViewController: floatingViewController,
                                        selected: floatingViewController.playerSettingsController.isEnabled == false,
                                        title: 'Off'.tr,
                                        onTap: () => floatingViewController.playerSettingsController.toggleSubtitle(false),
                                      ),
                                      FloatingSheetListTile(
                                        floatingViewController: floatingViewController,
                                        selected: floatingViewController.playerSettingsController.isEnabled,
                                        title: 'Arabic'.tr,
                                        onTap: () => floatingViewController.playerSettingsController.toggleSubtitle(true),
                                      ),
                                    ]);
                                  },
                          ),
                          if (floatingViewController.playerSettingsController.isEnabled)
                            FloatingSheetListTile(
                              floatingViewController: floatingViewController,
                              title: 'Text_size'.tr,
                              icon: Icons.text_fields_outlined,
                              titleStatus: floatingViewController.playerSettingsController.textEnum.toString().split('.')[1].capitalize,
                              onTap: () {
                                showFloatingBottomSheet(
                                    context,
                                    floatingViewController,
                                    List.generate(TextSizes.values.length, (index) {
                                      var key = TextSizes.values[index];
                                      return FloatingSheetListTile(
                                        floatingViewController: floatingViewController,
                                        selected: floatingViewController.playerSettingsController.textEnum == key,
                                        title: key.toString().split('.')[1].capitalize,
                                        onTap: () => floatingViewController.playerSettingsController.setTextSize(key),
                                      );
                                    }));
                              },
                            ),
                          if (floatingViewController.playerSettingsController.videoResolutions.length > 1)
                            FloatingSheetListTile(
                              floatingViewController: floatingViewController,
                              title: 'Video_Resolution'.tr,
                              icon: Icons.video_settings_outlined,
                              titleStatus: floatingViewController.playerSettingsController.selectedRes,
                              onTap: () {
                                showFloatingBottomSheet(
                                    context,
                                    floatingViewController,
                                    List.generate(floatingViewController.playerSettingsController.videoResolutions.length, (index) {
                                      var key = floatingViewController.playerSettingsController.videoResolutions.keys.toList()[index];
                                      return FloatingSheetListTile(
                                        floatingViewController: floatingViewController,
                                        selected: floatingViewController.playerSettingsController.selectedRes == key,
                                        title: key,
                                        onTap: () => floatingViewController.playerSettingsController.changeVideoRes(key),
                                      );
                                    }));
                              },
                            )
                        ])
                      ..addAll([
                        Container(
                          height: 1,
                          color: floatingViewController.floatingBottomSheetDivColor,
                        ),
                        FloatingSheetListTile(
                          floatingViewController: floatingViewController,
                          title: 'Cancel'.tr,
                          icon: Icons.close,
                          onTap: () {},
                        )
                      ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}

//todo
class FloatingSheetListTile extends StatelessWidget {
  final FloatingViewController floatingViewController;
  final Function onTap;
  final String title;
  final String titleStatus;
  final bool selected;
  final IconData icon;
  const FloatingSheetListTile({Key key, @required this.floatingViewController, this.onTap, this.selected, @required this.title, this.titleStatus, this.icon}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon ?? Icons.check,
        color: (selected == true || icon != null) ? floatingViewController.floatingBottomSheetTextColor : Colors.transparent,
      ),
      title: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: title,
            style: TextStyle(color: floatingViewController.floatingBottomSheetTextColor),
          ),
          if (titleStatus != null)
            TextSpan(
              text: ' - ',
              style: TextStyle(color: floatingViewController.floatingBottomSheetTextColor.withOpacity(0.5)),
            ),
          if (titleStatus != null)
            TextSpan(
              text: titleStatus,
              style: TextStyle(color: floatingViewController.floatingBottomSheetTextColor.withOpacity(0.5)),
            ),
        ]),
      ),
      onTap: onTap != null
          ? () {
              floatingViewController.removeOverlay();
              onTap();
            }
          : null,
    );
  }
}

class FloatingBottomSheet extends StatefulWidget {
  final List<Widget> children;

  FloatingBottomSheet({Key key, @required this.children}) : super(key: key);
  final FloatingViewController floatingViewController = Get.find();
  @override
  _FloatingBottomSheetState createState() {
    return _FloatingBottomSheetState();
  }
}

class _FloatingBottomSheetState extends State<FloatingBottomSheet> with SingleTickerProviderStateMixin {
  bool show = false;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Future.delayed(Duration(milliseconds: 100));
      setState(() {
        show = true;
      });
    });
    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 100),
      alignment: Alignment.topLeft,
      width: Get.width,
      height: show ? min(Get.height, (widget.children.length * 50.0) + 10) : 0,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.floatingViewController.floatingBottomSheetBgColor,
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: widget.children,
        ),
      ),
    );
  }
}
