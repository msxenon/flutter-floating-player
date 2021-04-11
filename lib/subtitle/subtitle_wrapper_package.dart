import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/subtitle/subtitle_controller.dart';
import 'package:flutter_player/subtitle/subtitle_text_view.dart';

import 'bloc/subtitle/subtitle_bloc.dart';
import 'data/models/style/subtitle_style.dart';
import 'data/repository/subtitle_repository.dart';

class SubTitleWrapper extends StatelessWidget {
  final SubtitleController subtitleController;
  final FloatingViewController controller;
  final SubtitleStyle subtitleStyle;

  SubTitleWrapper({
    Key key,
    @required this.subtitleController,
    @required this.controller,
    this.subtitleStyle = const SubtitleStyle(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        subtitleController.showSubtitles
            ? IgnorePointer(
                ignoring: true,
                child: Positioned(
                  top: subtitleStyle.position.top,
                  bottom: subtitleStyle.position.bottom,
                  left: subtitleStyle.position.left,
                  right: subtitleStyle.position.right,
                  child: BlocProvider(
                    create: (context) => SubtitleBloc(
                      controller: controller,
                      subtitleRepository: SubtitleDataRepository(
                        subtitleController: subtitleController,
                      ),
                      subtitleController: subtitleController,
                    )..add(
                        InitSubtitles(
                          subtitleController: subtitleController,
                        ),
                      ),
                    child: AnimatedOpacity(
                      duration: const Duration(microseconds: 250),
                      opacity: controller.isUsingController.isTrue ? 0 : 1,
                      child: SubtitleTextView(
                        subtitleStyle: subtitleStyle,
                      ),
                    ),
                  ),
                ),
              )
            : SizedBox.shrink()
      ],
    );
  }
}
