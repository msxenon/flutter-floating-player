import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/floating_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/text_size_enum.dart';
import 'package:flutter_player/subtitle/subtitle_controller.dart';
import 'package:get/get.dart';

import '../../exts.dart';

class PlayerSettingsController extends GetxController {
  SubtitleController subtitleController;
  DateTime dateTime;
  String link;
  bool isEnabled = false;
  Map<String, String> videoResolutions = {};
  String selectedRes;
  TextSizes textEnum = TextSizes.normal;
  static const double _defaultTextSize = 1;
  Function(Duration, dynamic videoItem, String itemId) onDisposeListener;
  double getTextSize(bool isFullScreen) {
    double result = _defaultTextSize;
    switch (textEnum) {
      case TextSizes.normal:
        result = 1;
        break;
      case TextSizes.medium:
        result = 1.5;
        break;
      case TextSizes.large:
        result = isFullScreen ? 3 : 1.6;
        break;
      case TextSizes.xlarge:
        result = isFullScreen ? 4 : 1.8;
        break;
    }
    return result;
  }

  void setTextSize(TextSizes _textSize) {
    textEnum = _textSize;
    update();
  }

  void initVideoResolutions(Map<String, String> res) {
    if (res == null || res.isEmpty) {
      throw Exception('video res is empty');
    }
    videoResolutions = res;
    if (selectedRes == null || !videoResolutions.containsKey(selectedRes)) {
      selectedRes = videoResolutions.keys.first;
    }
  }

  void changeVideoRes(String name) {
    if (name == selectedRes) {
      return;
    }
    selectedRes = name;
    Get.find<FloatingViewController>().setNewVideo();
    debugPrint('video set $name ${getVideo()}');
    update();
  }

  String getVideo() {
    return videoResolutions[selectedRes];
  }

  Future<void> initSubtitles({String subtitleLink}) async {
    link = subtitleLink;
    return _setSubtitle();
  }

  String getCaptionStringValue() {
    if (isEnabled == null) {
      return 'unavailable'.tr;
    } else if (isEnabled) {
      return 'arabic'.tr;
    } else {
      return 'off'.tr;
    }
  }

  Future<void> _setSubtitle() async {
    var subtitleLink = link;

    final subtitleType = subtitleLink != null
        ? SubtitleType.values.firstWhere(
            (e) => subtitleLink.split('.')?.last == e.getName(),
            orElse: () => SubtitleType.webvtt)
        : null;
    if (subtitleController == null) {
      isEnabled = link?.isNotEmpty == true;
    }
    final isLocal = isEnabled ? !subtitleLink.startsWith('http') : false;

    debugPrint('setSubtitle $subtitleLink => isLocal? $isLocal $subtitleType');
    String subtitleContent;
    if (isLocal) {
      final File file = File(subtitleLink);
      subtitleLink = null;
      try {
        subtitleContent = await file.readAsString();
      } catch (e) {
        isEnabled = false;
        debugPrint(e);
      }
    }
    subtitleController = SubtitleController(
        subtitleUrl: subtitleLink,
        subtitleType: subtitleType,
        subtitlesContent: subtitleContent,
        subtitleDecoder: SubtitleDecoder.utf8,
        showSubtitles: isEnabled);
    return;
  }

  void toggleSubtitle(bool forceIsEnabled) {
    debugPrint('toggle subtitle $forceIsEnabled == $isEnabled');

    if (forceIsEnabled == isEnabled) {
      return;
    }
    isEnabled = forceIsEnabled;
    update();

    debugPrint('toggle subtitle end $isEnabled');
  }

  @override
  void onClose() {
    subtitleController?.detach();
    super.onClose();
  }
}
