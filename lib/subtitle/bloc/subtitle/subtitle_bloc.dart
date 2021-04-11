import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/subtitle/data/models/subtitle.dart';
import 'package:flutter_player/subtitle/data/models/subtitles.dart';
import 'package:flutter_player/subtitle/data/repository/subtitle_repository.dart';

import '../../subtitle_controller.dart';

part 'subtitle_event.dart';
part 'subtitle_state.dart';

class SubtitleBloc extends Bloc<SubtitleEvent, SubtitleState> {
  final FloatingViewController controller;
  final SubtitleRepository subtitleRepository;
  final SubtitleController subtitleController;

  Subtitles subtitles;

  SubtitleBloc({
    @required this.controller,
    @required this.subtitleRepository,
    @required this.subtitleController,
  }) : super(SubtitleInitial()) {
    subtitleController.attach(this);
  }

  @override
  Stream<SubtitleState> mapEventToState(
    SubtitleEvent event,
  ) async* {
    if (event is LoadSubtitle) {
      yield* loadSubtitle();
    } else if (event is InitSubtitles) {
      yield* initSubtitles();
    } else if (event is UpdateLoadedSubtitle) {
      yield LoadedSubtitle(event.subtitle);
    }
  }

  Stream<SubtitleState> initSubtitles() async* {
    yield SubtitleInitializating();
    subtitles = await subtitleRepository.getSubtitles();
    yield SubtitleInitialized();
  }

  Stream<SubtitleState> loadSubtitle() async* {
    yield LoadingSubtitle();
    controller.videoPlayerController.addListener(() {
      var videoPlayerPosition = controller.videoPlayerController.value.position;
      if (videoPlayerPosition != null) {
        for (var subtitleItem in subtitles.subtitles) {
          if (videoPlayerPosition.inMilliseconds >
                  subtitleItem.startTime.inMilliseconds &&
              videoPlayerPosition.inMilliseconds <
                  subtitleItem.endTime.inMilliseconds) {
            add(UpdateLoadedSubtitle(subtitle: subtitleItem));
          }
        }
      }
    });
  }

  @override
  Future<void> close() {
    subtitleController.detach();
    return super.close();
  }
}
