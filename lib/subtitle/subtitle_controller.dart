import 'package:flutter/material.dart';

import 'bloc/subtitle/subtitle_bloc.dart';

class SubtitleController {
  SubtitleController({
    this.subtitleUrl,
    this.subtitlesContent,
    this.showSubtitles = true,
    this.subtitleDecoder,
    this.subtitleType = SubtitleType.webvtt,
  });
  String subtitlesContent;
  String subtitleUrl;
  final bool showSubtitles;
  SubtitleDecoder subtitleDecoder;
  SubtitleType subtitleType;
  //
  bool _attached = false;
  SubtitleBloc _subtitleBloc;

  void attach(SubtitleBloc subtitleBloc) {
    if (subtitleBloc != null) {
      _subtitleBloc = subtitleBloc;
      _attached = true;
    }
  }

  void detach() {
    _attached = false;
    _subtitleBloc = null;
  }

  void updateSubtitleUrl({
    @required url,
  }) {
    if (_attached) {
      subtitleUrl = url;
      _subtitleBloc.add(
        InitSubtitles(
          subtitleController: this,
        ),
      );
    } else {
      debugPrint('Seems that the controller is not correctly attached.');
    }
  }

  void updateSubtitleContent({
    @required content,
  }) {
    if (_attached) {
      subtitlesContent = content;
      _subtitleBloc.add(
        InitSubtitles(
          subtitleController: this,
        ),
      );
    } else {
      debugPrint('Seems that the controller is not correctly attached.');
    }
  }
}

enum SubtitleDecoder {
  utf8,
  latin1,
}

enum SubtitleType {
  webvtt,
  srt,
}
