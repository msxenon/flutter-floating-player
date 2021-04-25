import 'package:equatable/equatable.dart';

class Subtitle extends Equatable {
  Subtitle({this.startTime, this.endTime, this.text});

  final Duration startTime;
  final Duration endTime;
  final String text;

  @override
  List<Object> get props => [
        startTime,
        endTime,
        text,
      ];
}
