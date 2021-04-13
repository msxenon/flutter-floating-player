import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/subtitle/subtitle_bloc.dart';
import 'data/constants/view_keys.dart';
import 'data/models/style/subtitle_style.dart';

class SubtitleTextView extends StatelessWidget {
  final SubtitleStyle subtitleStyle;

  const SubtitleTextView({Key key, @required this.subtitleStyle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ignore: close_sinks
    var subtitleBloc = BlocProvider.of<SubtitleBloc>(context);
    return BlocConsumer<SubtitleBloc, SubtitleState>(
      listener: (context, state) {
        if (state is SubtitleInitialized) {
          subtitleBloc.add(LoadSubtitle());
        }
      },
      builder: (context, state) {
        if (state is LoadedSubtitle) {
          return Stack(
            children: <Widget>[
              subtitleStyle.hasBorder
                  ? Center(
                      child: AutoSizeText(
                        state.subtitle.text,
                        textAlign: TextAlign.center,
                        maxFontSize:
                            Theme.of(context).textTheme.headline1.fontSize,
                        minFontSize:
                            Theme.of(context).textTheme.subtitle1.fontSize,
                        style: TextStyle(
                          fontSize: subtitleStyle.fontSize,
                          foreground: Paint()
                            ..style = subtitleStyle.borderStyle.style
                            ..strokeWidth =
                                subtitleStyle.borderStyle.strokeWidth
                            ..color = subtitleStyle.borderStyle.color,
                        ),
                      ),
                    )
                  : Container(
                      child: null,
                    ),
              Center(
                child: AutoSizeText(
                  state.subtitle.text,
                  key: ViewKeys.SUBTITLE_TEXT_CONTENT,
                  textAlign: TextAlign.center,
                  maxFontSize: Theme.of(context).textTheme.headline1.fontSize,
                  minFontSize: Theme.of(context).textTheme.subtitle1.fontSize,
                  style: TextStyle(
                    fontSize: subtitleStyle.fontSize,
                    color: subtitleStyle.textColor,
                  ),
                ),
              ),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }
}
