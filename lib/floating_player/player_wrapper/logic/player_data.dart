import 'package:flutter/cupertino.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/save_position.dart';

typedef SavePosFunc<T> = void Function(SavePosition<T>);

class PlayerData<VI, SI> {
  const PlayerData(
      {@required this.itemTitle,
      this.videoItem,
      this.itemId,
      this.playType = PlayType.video,
      this.onDispose,
      this.subItem,
      this.savePosition,
      this.videoRes,
      this.optionalSubtitle,
      this.subtitle,
      this.useMockData = true,
      this.startPosition});
  final Map<String, String> videoRes;
  final String subtitle;

  ///used to cast vtt subtitle to chromecast
  final String optionalSubtitle;
  final bool useMockData;
  final Duration startPosition;
  final VI videoItem;
  final String itemId;

  final PlayType playType;
  final void Function(SavePosition<dynamic>) savePosition;
  final Function onDispose;
  final String itemTitle;
  final SI subItem;

  @override
  String toString() {
    // ignore: lines_longer_than_80_chars
    return 'PlayerData{videoRes: $videoRes, subtitle: $subtitle, useMockData: $useMockData, startPosition: $startPosition,   itemId: $itemId, playType: $playType, savePosition: $savePosition, onDispose: $onDispose, itemTitle: $itemTitle,  }';
  }

  Map<String, dynamic> castMessage({String videoLink, Duration position}) {
    debugPrint('$subtitle subtitle');
    return CastMedia(
      contentId: videoLink ?? videoRes.values.first,
      contentType: 'video/mp4',
      title: itemTitle,
      subtitlesUrl: optionalSubtitle ?? subtitle,
      streamType: playType == PlayType.video ? 'BUFFERED' : 'LIVE',
      position: position?.inSeconds ?? startPosition?.inSeconds ?? 0,
    ).toChromeCastMap();
  }
}

enum PlayType { live, video }

class CastMedia {
  CastMedia({
    this.contentId,
    this.title = '',
    this.subtitle = '',
    this.autoPlay = true,
    this.position = 0,
    this.contentType = 'video/mp4',
    this.streamType = 'BUFFERED',
    this.images,
    this.subtitlesUrl = '',
  }) {
    images ??= [];
  }
  final String contentId;
  String title;
  String subtitle;
  bool autoPlay = true;
  int position;
  String contentType;
  String streamType;
  List<String> images;
  String subtitlesUrl;

  Map<String, dynamic> toChromeCastMap() {
    // If media doesn't have subtitles send without media->Tracks
    if (subtitlesUrl == '')
      return {
        'type': 'LOAD',
        'autoPlay': autoPlay,
        'currentTime': position,
        'activeTracks': [],
        'media': {
          'contentId': contentId,
          'contentType': contentType,
          'streamType': streamType,
          'textTrackStyle': {
            'edgeType':
                // ignore: lines_longer_than_80_chars
                'NONE', // can be: "NONE", "OUTLINE", "DROP_SHADOW", "RAISED", "DEPRESSED"
            'fontScale':
                1.0, // transforms into "font-size: " + (fontScale*100) +"%"
            'fontStyle':
                'NORMAL', // can be: "NORMAL", "BOLD", "BOLD_ITALIC", "ITALIC",
            'fontFamily': 'Droid Sans',
            'fontGenericFamily':
                // ignore: lines_longer_than_80_chars
                'SANS_SERIF', // can be: "SANS_SERIF", "MONOSPACED_SANS_SERIF", "SERIF", "MONOSPACED_SERIF", "CASUAL", "CURSIVE", "SMALL_CAPITALS",
            'windowColor':
                '#00000', // see http://dev.w3.org/csswg/css-color/#hex-notation
            'windowRoundedCornerRadius': 10, // radius in px
            'windowType': 'NONE' // can be: "NONE", "NORMAL", "ROUNDED_CORNERS"
          },
          'metadata': {
            'metadataType': 0,
            'title': title,
            'subtitle': subtitle,
            'images': [
              if (images.isNotEmpty) {'url': images[0]}
            ],
          },
        }
      };
    // If media has subtitles send subtitles tracks in media->Tracks
    return {
      'type': 'LOAD',
      'autoPlay': autoPlay,
      'currentTime': position,
      'activeTracks': [],
      'media': {
        'contentId': contentId,
        'contentType': contentType,
        'streamType': streamType,
        'textTrackStyle': {
          'edgeType':
              // ignore: lines_longer_than_80_chars
              'NONE', // can be: "NONE", "OUTLINE", "DROP_SHADOW", "RAISED", "DEPRESSED"
          'fontScale':
              1.0, // transforms into "font-size: " + (fontScale*100) +"%"
          'fontStyle':
              'NORMAL', // can be: "NORMAL", "BOLD", "BOLD_ITALIC", "ITALIC",
          'fontFamily': 'Droid Sans',
          'fontGenericFamily':
              // ignore: lines_longer_than_80_chars
              'SANS_SERIF', // can be: "SANS_SERIF", "MONOSPACED_SANS_SERIF", "SERIF", "MONOSPACED_SERIF", "CASUAL", "CURSIVE", "SMALL_CAPITALS",
          'windowColor':
              '#00000', // see http://dev.w3.org/csswg/css-color/#hex-notation
          'windowRoundedCornerRadius': 10, // radius in px
          'windowType': 'NONE' // can be: "NONE", "NORMAL", "ROUNDED_CORNERS"
        },
        'metadata': {
          'metadataType': 0,
          'title': title,
          'subtitle': subtitle,
          'images': [
            if (images.isNotEmpty) {'url': images[0]}
          ],
        },
        'tracks': [
          {
            'trackId': 0, // This is an unique ID, used to reference the track
            'type':
                'TEXT', // Default Media Receiver currently only supports TEXT
            'trackContentId':
                // ignore: lines_longer_than_80_chars
                subtitlesUrl, // the URL of the VTT (enabled CORS and the correct ContentType are required)
            'trackContentType': 'text/vtt', // Currently only VTT is supported
            'name': 'Arabic', // a Name for humans
            'language': 'ar-IQ', // the language
            'subtype': 'SUBTITLES' // should be SUBTITLES
          }
        ]
      }
    };
  }
}
