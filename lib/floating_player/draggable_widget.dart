import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:get/get.dart';

enum AnchoringPosition { bottomLeft, bottomRight, maximized }

class DeleteIconConfig {
  final double maxSize;
  final double minSize;
  final Color iconColor;
  final Color backgroundColor;
  final IconData icon;
  const DeleteIconConfig({this.maxSize: 50, this.minSize: 30, this.iconColor: Colors.white, this.backgroundColor: Colors.black54, this.icon: Icons.close});
}

class DraggableWidget extends StatefulWidget {
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

  /// Intial location of the widget, default to [AnchoringPosition.bottomRight]
  final AnchoringPosition initialPosition;

  /// Intially should the widget be visible or not, default to [true]
  final bool intialVisibility;

  /// The top bottom pargin to create the bottom boundary for the widget, for example if you have a [BottomNavigationBar],
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

  /// How much should the [DraggableWidget] be scaled when it is being dragged, default to 1.1
  final double dragAnimationScale;

  /// Touch Delay Duration. Default value is zero. When set, drag operations will trigger after the duration.
  final Duration touchDelay;
  final AnchoringPosition preferredAnchorPos;
  DraggableWidget({
    Key key,
    this.child,
    this.initialHeight: 202,
    this.preferredAnchorPos: AnchoringPosition.bottomRight,
    this.horizontalSapce = 0,
    this.animatedViewsDuration = const Duration(milliseconds: 150),
    this.deleteIconConfig = const DeleteIconConfig(),
    this.verticalSpace = 0,
    this.initialPosition = AnchoringPosition.bottomRight,
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
  @override
  _DraggableWidgetState createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget> with TickerProviderStateMixin {
  FloatingViewController _floatingViewController = Get.find();
  bool get isMinimized => currentDocker != null && currentDocker != AnchoringPosition.maximized;
  final playerKey = GlobalKey();
  final deleteAreaKey = GlobalKey();
  bool _isAboutToDelete = false;
  double top = 0, left = 0;
  double boundary = 0;
  AnimationController animationController;
  AnimationController _deleteWidgetAnimation;
  Animation animation;
  double hardLeft = 0, hardTop = 0;
  bool offstage = true;
  double get topMargin => widget.topSafeMargin ? Get.mediaQuery.padding.top : 0;
  AnchoringPosition currentDocker;

  double get widgetHeight => getPlayerHeight();
  double get widgetWidth => getPlayerWidth();

  bool dragging = false;

  AnchoringPosition _currentlyDocked;
  AnchoringPosition get currentlyDocked => _currentlyDocked;

  set currentlyDocked(AnchoringPosition value) {
    _currentlyDocked = value;
    _floatingViewController.onMaximizedStateChange(!isMinimized);
  }

  bool visible;

  bool get currentVisibility => visible ?? widget.intialVisibility;

  bool isStillTouching;

  PointerDownEvent _downPointer;
  @override
  void dispose() {
    animationController?.dispose();
    _deleteWidgetAnimation?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    currentlyDocked = widget.initialPosition;
    hardTop = topMargin;
    animationController = AnimationController(
      value: 1,
      vsync: this,
      duration: widget.animatedViewsDuration,
    )
      ..addListener(() {
        if (currentDocker != null) animateWidget(currentDocker);
      })
      ..addStatusListener(
        (status) {
          if (status == AnimationStatus.completed) {
            hardLeft = left;
            hardTop = top;
          }
        },
      );
    _deleteWidgetAnimation = AnimationController(
      value: 0,
      vsync: this,
      duration: widget.animatedViewsDuration,
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
      await Future<void>.delayed(Duration(
        milliseconds: 100,
      ));
      setState(() {
        offstage = false;
        boundary = MediaQuery.of(context).size.height - widget.bottomMargin;
        if (widget.initialPosition == AnchoringPosition.bottomRight) {
          top = boundary - widgetHeight + widget.statusBarHeight;
          left = MediaQuery.of(context).size.width - widgetWidth;
        } else if (widget.initialPosition == AnchoringPosition.bottomLeft) {
          top = boundary - widgetHeight + widget.statusBarHeight;
          left = 0;
        } else {
          top = topMargin;
          left = 0;
        }
      });
    });
    _floatingViewController.setPlayerHeight(hardTop + getPlayerHeight());
    _floatingViewController.isMaximized.listen((x) {
      if (mounted && !dragging && !x) {
        setState(() {
          _animateTo(widget.preferredAnchorPos ?? AnchoringPosition.bottomLeft);
        });
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
          animateWidget(currentlyDocked);
        });
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: top,
          left: left,
          child: (!currentVisibility)
              ? Container()
              : Listener(
                  onPointerUp: (v) {
                    if (!isStillTouching || _floatingViewController.isFullScreen) {
                      return;
                    }
                    isStillTouching = false;

                    final p = v.position;
                    currentDocker = determineDocker(p);

                    setState(() {
                      dragging = false;
                    });
                    _floatingViewController.onDraggingChange(dragging);
                    if (animationController.isAnimating) {
                      animationController.stop();
                    }
                    animationController.reset();
                    animationController.forward();
                    if (_isAboutToDelete) {
                      widget.onRemove();
                    }
                  },
                  onPointerDown: (v) async {
                    isStillTouching = false;
                    _downPointer = v;
                    await Future<void>.delayed(widget.touchDelay);
                    if (!_floatingViewController.showControllerView.value) {
                      isStillTouching = true;
                    }
                  },
                  onPointerMove: (v) async {
                    if (!isStillTouching || _floatingViewController.isFullScreen) {
                      return;
                    }
                    if (animationController.isAnimating) {
                      animationController.stop();
                      animationController.reset();
                    }
                    if (dragging == true || v.delta.distanceSquared > _downPointer.delta.distanceSquared) {
                      setState(() {
                        dragging = true;
                        _floatingViewController.onDraggingChange(dragging);
                        if (v.position.dy < boundary && v.position.dy > topMargin) {
                          top = max(v.position.dy - (widgetHeight) / 2, topMargin);
                        }

                        left = max(v.position.dx - (widgetWidth), 0);

                        hardLeft = left;
                        hardTop = top;
                      });
                      _floatingViewController.onMaximizedStateChange(top == topMargin);
                      isAboutToDelete = isInsideDeleteRect();
                    }
                  },
                  child: Offstage(
                    offstage: offstage,
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.horizontalSapce,
                        vertical: widget.verticalSpace,
                      ),
                      child: AnimatedContainer(
                          key: playerKey,
                          duration: widget.animatedViewsDuration,
                          foregroundDecoration: BoxDecoration(color: _isAboutToDelete ? Colors.red.withOpacity(0.5) : Colors.transparent),
                          width: getPlayerWidth(),
                          height: getPlayerHeight(),
                          decoration: BoxDecoration(
                            boxShadow: [dragging ? widget.draggingShadow : widget.normalShadow],
                          ),
                          child: widget.child),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: widget.bottomMargin),
          child: AnimatedBuilder(
            animation: _deleteWidgetAnimation,
            builder: (_, child) {
              double percentage = _deleteWidgetAnimation.value;
              return Align(
                child: AnimatedOpacity(
                  opacity: dragging ? 0.7 : 0,
                  duration: widget.animatedViewsDuration,
                  child: Container(
                    key: deleteAreaKey,
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      widget.deleteIconConfig.icon,
                      color: widget.deleteIconConfig.iconColor,
                      size: getValueFromPercentage(widget.deleteIconConfig.minSize, widget.deleteIconConfig.maxSize, percentage),
                    ),
                    decoration: BoxDecoration(
                        color: widget.deleteIconConfig.backgroundColor,
                        border: Border.all(
                          color: widget.deleteIconConfig.iconColor,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                  ),
                ),
                alignment: Alignment.bottomCenter,
              );
            },
          ),
        ),
      ],
    );
  }

  double getValueFromPercentage(double min, double max, double percentage) {
    double diff = max - min;
    return (percentage * diff) + min;
  }

  set isAboutToDelete(bool delete) {
    if (delete == _isAboutToDelete) {
      return;
    }
    _isAboutToDelete = delete;
    _deleteWidgetAnimation.animateTo(_isAboutToDelete ? 1 : 0);
  }

  final double initialWidth = Get.width;

  double getPlayerWidth() {
    if (_floatingViewController.isFullScreen) {
      return Get.width;
    }
    return dragging
        ? initialWidth * (isAboveMaximizeGuideLine ? 1 : 0.5)
        : (currentDocker == null || currentDocker == AnchoringPosition.maximized)
            ? initialWidth
            : initialWidth * 0.3;
  }

  bool get isAboveMaximizeGuideLine => (Get.height / 2) > top;

  double getPlayerHeight() {
    if (_floatingViewController.isFullScreen) {
      return Get.height;
    }
    return dragging
        ? widget.initialHeight * (isAboveMaximizeGuideLine ? 1 : 0.5)
        : (currentDocker == null || currentDocker == AnchoringPosition.maximized)
            ? widget.initialHeight
            : widget.initialHeight * 0.3;
  }

  AnchoringPosition determineDocker(Offset upPos) {
    if (_downPointer == null || !dragging) {
      return _currentlyDocked;
    }
    // print('determineDocker down:${_downPointer.position.dy}, up:${upPos.dy}');
    if (_downPointer.position.dy < upPos.dy || _downPointer.position.dy - upPos.dy < 200) {
      final double totalHeight = boundary;
      final double totalWidth = MediaQuery.of(context).size.width;
      if (upPos.dx < totalWidth / 2 && upPos.dy > totalHeight / 3) {
        return AnchoringPosition.bottomLeft;
      } else {
        return AnchoringPosition.bottomRight;
      }
    } else {
      return AnchoringPosition.maximized;
    }

    // if (isAboveMaximizeGuideLine) {
    //   return AnchoringPosition.maximized;
    // } else if (x < totalWidth / 2 && y > totalHeight / 3) {
    //   return AnchoringPosition.bottomLeft;
    // } else if (x > totalWidth / 2 && y > totalHeight / 3) {
    //   return AnchoringPosition.bottomRight;
    // } else {
    //   return AnchoringPosition.maximized;
    // }
  }

  void animateWidget(AnchoringPosition docker) {
    final double totalHeight = boundary;
    final double totalWidth = MediaQuery.of(context).size.width;
    if (_floatingViewController.isFullScreen) {
      return;
    }
    switch (docker) {
      case AnchoringPosition.bottomLeft:
        double remaingDistanceY = (totalHeight - widgetHeight - hardTop);
        setState(() {
          left = (1 - animation.value) * hardLeft;
          top = hardTop + (animation.value) * remaingDistanceY + (widget.statusBarHeight * animation.value);
          currentlyDocked = AnchoringPosition.bottomLeft;
        });
        break;
      case AnchoringPosition.bottomRight:
        double remaingDistanceX = (totalWidth - widgetWidth - hardLeft);
        double remaingDistanceY = (totalHeight - widgetHeight - hardTop);
        setState(() {
          left = hardLeft + (animation.value) * remaingDistanceX;
          top = hardTop + (animation.value) * remaingDistanceY + (widget.statusBarHeight * animation.value);
          currentlyDocked = AnchoringPosition.bottomRight;
        });
        break;
      case AnchoringPosition.maximized:
        setState(() {
          left = 0;
          top = topMargin;
          currentlyDocked = AnchoringPosition.maximized;
        });
        break;
      default:
    }
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
    if (animationController.isAnimating) {
      animationController.stop();
    }
    animationController.reset();
    currentDocker = anchoringPosition;
    animationController.forward();
  }

  Offset _getCurrentPosition() {
    return Offset(left, top);
  }

  Rect getDeleteReact() {
    return deleteAreaKey.globalPaintBounds;
  }

  bool isInsideDeleteRect() {
    var x = getDeleteReact();
    var playerRect = getPlayerRect();
    var size = x.intersect(playerRect).size;
    // dev.log('isInsideDeleteRect ${size.toString()}');
    return !size.isEmpty;
  }

  Rect getPlayerRect() {
    return playerKey.globalPaintBounds.deflate(40) ?? Rect.zero;
  }
}

class DragController {
  _DraggableWidgetState _widgetState;
  void _addState(_DraggableWidgetState _widgetState) {
    this._widgetState = _widgetState;
  }

  /// Jump to any [AnchoringPosition] programatically
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
    var translation = renderObject?.getTransformTo(null)?.getTranslation();
    if (translation != null && renderObject.paintBounds != null) {
      return renderObject.paintBounds.shift(Offset(translation.x, translation.y));
    } else {
      return Rect.zero;
    }
  }
}
