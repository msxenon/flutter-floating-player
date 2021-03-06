import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/floating_view_controller.dart';
import 'package:get/get.dart';

enum AnchoringPosition { minimized, maximized, fullScreen }

class DeleteIconConfig {
  const DeleteIconConfig(
      {this.maxSize = 50,
      this.minSize = 30,
      this.iconColor = Colors.white,
      this.backgroundColor = Colors.black54,
      this.icon = Icons.close});
  final double maxSize;
  final double minSize;
  final Color iconColor;
  final Color backgroundColor;
  final IconData icon;
}

class DraggableWidget extends StatefulWidget {
  DraggableWidget({
    @required this.child,
    this.initialHeight = 202,
    this.horizontalSapce = 0,
    this.animatedViewsDuration = const Duration(milliseconds: 150),
    this.deleteIconConfig = const DeleteIconConfig(),
    this.verticalSpace = 0,
    this.initialPosition = AnchoringPosition.maximized,
    this.intialVisibility = true,
    this.bottomMargin = 0,
    this.topSafeMargin = true,
    this.onRemove,
    this.statusBarHeight = 24,
    this.shadowBorderRadius = 5,
    this.dragController,
    this.dragAnimationScale = 1.1,
    this.touchDelay = Duration.zero,
    this.normalShadow = const BoxShadow(
      color: Colors.black12,
      offset: Offset(0, 0),
      blurRadius: 2,
    ),
    this.draggingShadow = const BoxShadow(
      color: Colors.black12,
      offset: Offset(0, 0),
      blurRadius: 10,
    ),
  })  : assert(dragAnimationScale != null),
        assert(normalShadow != null),
        assert(draggingShadow != null),
        assert(statusBarHeight != null && statusBarHeight >= 0),
        assert(horizontalSapce >= 0 && horizontalSapce != null),
        assert(verticalSpace >= 0 && verticalSpace != null),
        assert(initialPosition != null),
        assert(bottomMargin >= 0 && bottomMargin != null),
        assert(intialVisibility != null),
        assert(child != null);
  final double initialHeight;
  final Function onRemove;
  final Duration animatedViewsDuration;
  final DeleteIconConfig deleteIconConfig;

  /// The widget that will be displayed as dragging widget
  final Widget child;

  /// The horizontal padding around the widget
  final double horizontalSapce;

  /// The vertical padding around the widget
  final double verticalSpace;

  // ignore: comment_references
  /// Intial location of the widget, default to [AnchoringPosition.bottomRight]
  final AnchoringPosition initialPosition;

  // ignore: comment_references
  /// Intially should the widget be visible or not, default to [true]
  final bool intialVisibility;

  // ignore: lines_longer_than_80_chars
  /// The top bottom pargin to create the bottom boundary for the widget, for example if you have a [BottomNavigationBar],
  // ignore: lines_longer_than_80_chars
  /// then you may need to set the bottom boundary so that the draggable button can't get on top of the [BottomNavigationBar]
  final double bottomMargin;

  final bool topSafeMargin;

  /// Status bar's height, default to 24
  final double statusBarHeight;

  /// Shadow's border radius for the draggable widget, default to 10
  final double shadowBorderRadius;

  /// A drag controller to show/hide or move the widget around the screen
  final DragController dragController;

  /// [BoxShadow] when the widget is not being dragged, default to
  /// ```Dart
  ///const BoxShadow(
  ///     color: Colors.black38,
  ///    offset: Offset(0, 4),
  ///    blurRadius: 2,
  ///  ),
  /// ```
  final BoxShadow normalShadow;

  /// [BoxShadow] when the widget is being dragged
  ///```Dart
  ///const BoxShadow(
  ///     color: Colors.black38,
  ///    offset: Offset(0, 10),
  ///    blurRadius: 10,
  ///  ),
  /// ```
  final BoxShadow draggingShadow;

  // ignore: lines_longer_than_80_chars
  /// How much should the [DraggableWidget] be scaled when it is being dragged, default to 1.1
  final double dragAnimationScale;

  // ignore: lines_longer_than_80_chars
  /// Touch Delay Duration. Default value is zero. When set, drag operations will trigger after the duration.
  final Duration touchDelay;

  @override
  _DraggableWidgetState createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget>
    with TickerProviderStateMixin {
  final FloatingViewController _floatingViewController = Get.find();
  final playerKey = GlobalKey();
  final deleteAreaKey = GlobalKey();
  final bool _isAboutToDelete = false;
  double top = 0, left = 0;
  double boundary = 0;
  AnimationController animationController;
  Animation animation;
  double hardLeft = 0, hardTop = 0;
  bool offstage = true;
  double get topMargin => widget.topSafeMargin ? Get.mediaQuery.padding.top : 0;
  double closePercentage = 0;
  double get widgetHeight => getPlayerHeight();
  double get widgetWidth => getPlayerWidth();
  AnchoringPosition get currentlyDocked =>
      _floatingViewController.anchoringPosition.value;

  bool visible;

  bool get currentVisibility => visible ?? widget.intialVisibility;

  double lastCaseYPos = 0;
  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // _currentDocked = widget.initialPosition;
    hardTop = topMargin;
    animationController = AnimationController(
      value: 1,
      vsync: this,
      duration: widget.animatedViewsDuration,
    )
      ..addListener(() async {
        // await Future.delayed(Duration(microseconds: 200));
        if (!animationController.isAnimating) {
          animateWidget(currentlyDocked, 'AnimationController');
        }
      })
      ..addStatusListener(
        (status) {
          if (status == AnimationStatus.completed) {
            hardLeft = left;
            hardTop = top;
          }
        },
      );
    animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

    widget.dragController?._addState(this);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Future<void>.delayed(const Duration(
        milliseconds: 100,
      ));
      setState(() {
        offstage = false;
        boundary = MediaQuery.of(context).size.height - widget.bottomMargin;
        if (widget.initialPosition == AnchoringPosition.minimized) {
          top = boundary - widgetHeight + widget.statusBarHeight;
          left = MediaQuery.of(context).size.width - widgetWidth;
        } else {
          top = topMargin;
          left = 0;
        }
      });
    });
    _floatingViewController.setPlayerHeight(hardTop + getPlayerHeight());
    _floatingViewController.anchoringPosition.listen((x) {
      debugPrint(
          // ignore: lines_longer_than_80_chars
          'draggable listener $x --- $mounted -- maximi => ${_floatingViewController.isMaximized.value} - drag => ${_floatingViewController.dragging.value}');
      if (mounted) {
        _animateTo(x);
      }
    });
    super.initState();
  }

  @override
  void didUpdateWidget(DraggableWidget oldWidget) {
    if (offstage == false) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {
          boundary = MediaQuery.of(context).size.height - widget.bottomMargin;
          animateWidget(currentlyDocked, 'didUpdateWidget');
        });
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final currentPosY = top - topMargin;
    final res = currentPosY / (boundary - widget.initialHeight);
    final percentage = max(0.4, 1.0 - res);
    debugPrint(
        'getSize  ${Get.width} || ${MediaQuery.of(context).size.width}  $currentPosY ($top - ${widget.statusBarHeight}) / ($boundary - ${widget.initialHeight}) = $res => $percentage');
    debugPrint(
        '($currentPosY / ${(boundary - widget.initialHeight)}) = $res => $percentage');
    return Stack(
      children: [
        Positioned(
          top: _floatingViewController.isFullScreen.value
              ? 0 //top - widget.statusBarHeight
              : top,
          left: left,
          child: (!currentVisibility)
              ? Container()
              : Transform.scale(
                  alignment: Alignment.bottomRight,
                  scale: _floatingViewController.isFullScreen.value
                      ? 1
                      : percentage,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _floatingViewController.toggleControllers();
                    },
                    onDoubleTap: () {
                      if (currentlyDocked != AnchoringPosition.minimized) {
                      } else {
                        _animateTo(AnchoringPosition.maximized);
                      }
                    },
                    onTapDown: (v) async {
                      await Future<void>.delayed(widget.touchDelay);
                    },
                    onVerticalDragEnd: (v) {
                      _floatingViewController.dragging(false);
                      if (_floatingViewController.isFullScreen.value ||
                          _floatingViewController.controlsIsShowing.value) {
                        return;
                      }

                      // final p = Offset(left, top);
                      // debugPrint(
                      //     'onVerticalDragEnd  anchorPos: ${currentlyDocked} ==== ${top} - ${lastCaseYPos} = ${top - lastCaseYPos} > ${Get.height / 5}');
                      final bool switchPos =
                          v.velocity.pixelsPerSecond.dy.abs() > 3000.0 ||
                              (top - lastCaseYPos).abs() >
                                  MediaQuery.of(context).size.height / 5;
                      if (switchPos) {
                        _floatingViewController.changeAnchor(
                            determineDocker(switchPos), 'onVerticalDragEnd');
                      } else {
                        if (animationController.isAnimating) {
                          animationController.stop();
                        }
                        animationController
                          ..reset()
                          ..forward();
                      }
                      // debugPrint(
                      //     'onVerticalDragEnd $switchPos / Velocity:${v.primaryVelocity} = ${v.velocity.pixelsPerSecond.dy} : dir:${v.velocity.pixelsPerSecond.distanceSquared} / anchorPos: ${_floatingViewController.anchoringPosition.value}');
                    },
                    onVerticalDragUpdate: (v) async {
                      if (_floatingViewController.isFullScreen.value ||
                          _floatingViewController.controlsIsShowing.value) {
                        return;
                      }
                      _floatingViewController.dragging(true);

                      if (animationController.isAnimating) {
                        animationController
                          ..stop()
                          ..reset();
                      }
                      setState(() {
                        final pos = v.globalPosition.dy - (widgetHeight) / 2;
                        if (pos < (boundary - (widget.initialHeight)) &&
                            v.globalPosition.dy > topMargin) {
                          top = max(pos, topMargin);
                        }
                        left = max(v.globalPosition.dx - (widgetWidth), 0);

                        hardLeft = left;
                        hardTop = top;
                      });
                    },
                    onHorizontalDragUpdate: (f) {
                      if (!_floatingViewController.canClose.value ||
                          _floatingViewController.controlsIsShowing.value) {
                        return;
                      }
                      _floatingViewController.dragging(true);
                      left = left + f.primaryDelta;
                      if (left <= hardLeft) {
                        if (currentlyDocked == AnchoringPosition.minimized) {
                          closePercentage = hardLeft > 0
                              ? 1 - (left / hardLeft).abs()
                              : left.abs() > 200
                                  ? 1
                                  : 0;
                        } else {
                          closePercentage = hardLeft > 0
                              ? 1 - (left / hardLeft).abs()
                              : left.abs() > 50
                                  ? 1
                                  : 0;
                        }
                        setState(() {});
                      } else {
                        left = hardLeft;
                      }
                    },
                    onHorizontalDragEnd: (f) {
                      if (_floatingViewController.controlsIsShowing.value) {
                        return;
                      }
                      if (closePercentage == 1) {
                        widget.onRemove();
                      }
                      _animateTo(currentlyDocked);
                    },
                    child: IgnorePointer(
                      ignoring: _floatingViewController.dragging.value,
                      child: Offstage(
                        offstage: offstage,
                        child: Container(
                            alignment: Alignment.bottomRight,
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.horizontalSapce,
                              vertical: widget.verticalSpace,
                            ),
                            child: AnimatedContainer(
                                key: playerKey,
                                duration: widget.animatedViewsDuration,
                                foregroundDecoration: BoxDecoration(
                                    color: _isAboutToDelete
                                        ? Colors.red.withOpacity(0.5)
                                        : Colors.transparent),
                                width: getPlayerWidth(),
                                height: getPlayerHeight(),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    _floatingViewController.dragging.value
                                        ? widget.draggingShadow
                                        : widget.normalShadow
                                  ],
                                ),
                                child: Stack(
                                    fit: StackFit.expand,
                                    alignment: Alignment.center,
                                    children: [
                                      widget.child,
                                      IgnorePointer(
                                        ignoring: true,
                                        child: AnimatedOpacity(
                                          opacity: closePercentage,
                                          duration:
                                              widget.animatedViewsDuration,
                                          child: Container(
                                            key: deleteAreaKey,
                                            padding: const EdgeInsets.all(8),
                                            color: Colors.black87,
                                            child: FittedBox(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                child: Text(
                                                  'close'.tr,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]))),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  double getPlayerWidth() {
    return MediaQuery.of(Get.context).size.width;
  }

  bool get isAboveMaximizeGuideLine =>
      (MediaQuery.of(Get.context).size.height / 2) > top;

  double getPlayerHeight() {
    if (_floatingViewController.isFullScreen.value) {
      return MediaQuery.of(Get.context).size.height;
    } else {
      return widget.initialHeight;
    }
  }

  AnchoringPosition determineDocker(bool switchPos) {
    debugPrint(
        'determineDocker switchPos $switchPos &&  oldAnchor $currentlyDocked');
    if (switchPos) {
      if (currentlyDocked == AnchoringPosition.maximized) {
        return AnchoringPosition.minimized;
      } else {
        return AnchoringPosition.maximized;
      }
    }
    return currentlyDocked;
  }

  void animateWidget(AnchoringPosition docker, String tag) {
    if (!mounted) {
      return;
    }
    final double totalHeight = boundary;
    final double totalWidth = getPlayerWidth();
    if (_floatingViewController.isFullScreen.value) {
      return;
    }
    debugPrint(
        'animateWidget start $docker &  currently => $currentlyDocked  $tag');

    switch (docker) {
      case AnchoringPosition.minimized:
        final double remaingDistanceX = (totalWidth - widgetWidth - hardLeft);
        final double remaingDistanceY = (totalHeight - widgetHeight - hardTop);
        final noNeedToChange = remaingDistanceY < 5;
        debugPrint(
            // ignore: lines_longer_than_80_chars
            'animateWidget 1st $remaingDistanceX &  currently => $remaingDistanceY $noNeedToChange $tag');
        // if (noNeedToChange) {
        //   return;
        // }
        setState(() {
          left = hardLeft + (animation.value) * remaingDistanceX;
          top = hardTop +
              (animation.value) * remaingDistanceY +
              (animation.value);
          _floatingViewController.changeAnchor(
              AnchoringPosition.minimized, 'animateWidget 1st');
        });
        break;
      case AnchoringPosition.maximized:
        setState(() {
          left = 0;
          top = topMargin;
          _floatingViewController.changeAnchor(
              AnchoringPosition.maximized, 'animateWidget 2nd');
        });
        break;
      default:
    }
    lastCaseYPos = top;
  }

  void _showWidget() {
    setState(() {
      visible = true;
    });
  }

  void _hideWidget() {
    setState(() {
      visible = false;
    });
  }

  void _animateTo(AnchoringPosition anchoringPosition) {
    debugPrint('_animateTo start old $currentlyDocked => $anchoringPosition');

    if (animationController.isAnimating) {
      animationController.stop();
    }
    closePercentage = 0;
    animationController.reset();
    _floatingViewController.changeAnchor(anchoringPosition, 'animateTo');
    _floatingViewController.dragging(false);

    animationController.forward();
    debugPrint('_animateTo end $currentlyDocked');
  }

  Offset _getCurrentPosition() {
    return Offset(left, top);
  }

  // Rect getDeleteReact() {
  //   return deleteAreaKey.globalPaintBounds;
  // }

  // bool isInsideDeleteRect() {
  //   final x = getDeleteReact();
  //   final playerRect = getPlayerRect();
  //   final size = x.intersect(playerRect).size;
  //   return !size.isEmpty;
  // }

  Rect getPlayerRect() {
    return playerKey.globalPaintBounds.deflate(40) ?? Rect.zero;
  }
}

class DragController {
  _DraggableWidgetState _widgetState;
  void _addState(_DraggableWidgetState _widgetState) {
    this._widgetState = _widgetState;
  }

  /// Jump to any [AnchoringPosition] programmatically
  void jumpTo(AnchoringPosition anchoringPosition) {
    _widgetState._animateTo(anchoringPosition);
  }

  /// Get the current screen [Offset] of the widget
  Offset getCurrentPosition() {
    return _widgetState._getCurrentPosition();
  }

  /// Makes the widget visible
  void showWidget() {
    _widgetState._showWidget();
  }

  /// Hide the widget
  void hideWidget() {
    _widgetState._hideWidget();
  }
}

extension GlobalKeyExtension on GlobalKey {
  Rect get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null)?.getTranslation();
    if (translation != null && renderObject.paintBounds != null) {
      return renderObject.paintBounds
          .shift(Offset(translation.x, translation.y));
    } else {
      return Rect.zero;
    }
  }
}

double getValueFromPercentage(double min, double max, double percentage) {
  final double diff = max - min;
  return (percentage * diff) + min;
}
