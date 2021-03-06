import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/floating_view_controller.dart';
import 'package:flutter_player/subtitle/data/models/style/subtitle_position.dart';
import 'package:flutter_player/subtitle/subtitle_controller.dart';
import 'package:flutter_player/subtitle/subtitle_text_view.dart';

import 'bloc/subtitle/subtitle_bloc.dart';
import 'data/models/style/subtitle_style.dart';
import 'data/repository/subtitle_repository.dart';

class SubTitleWrapper extends StatelessWidget {
  SubTitleWrapper({
    @required this.subtitleController,
    @required this.controller,
    Key key,
    this.subtitleStyle =
        const SubtitleStyle(position: SubtitlePosition(bottom: 0)),
  }) : super(key: key);
  final SubtitleController subtitleController;
  final FloatingViewController controller;
  final SubtitleStyle subtitleStyle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        subtitleController.showSubtitles
            ? Positioned(
                top: subtitleStyle.position.top,
                bottom: subtitleStyle.position.bottom,
                left: 5,
                right: 5,
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
                  child: controller.playerSettingsController.isEnabled
                      ? SubtitleTextView(
                          subtitleStyle: subtitleStyle,
                        )
                      : const SizedBox.shrink(),
                ),
              )
            : const SizedBox.shrink()
      ],
    );
  }
}
