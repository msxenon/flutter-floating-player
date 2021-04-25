import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/floating_view_controller.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

class PLayerDetails extends StatelessWidget {
  PLayerDetails({
    @required this.floatingViewController,
    Key key,
    this.child,
    this.bgColor,
  }) : super(key: key);
  final WidgetBuilder child;
  final Color bgColor;

  final FloatingViewController floatingViewController;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor ?? Colors.black,
      constraints: const BoxConstraints.expand(),
      child: GetBuilder<FloatingViewController>(
        init: floatingViewController,
        builder: (FloatingViewController model) {
          return Container(
            color: Colors.black,
            padding: EdgeInsets.only(top: model.detailsTopPadding),
            constraints: const BoxConstraints.expand(),
            child: !model.showDetails
                ? const SizedBox.shrink()
                : child != null
                    ? child(context)
                    : ListView.builder(
                        itemBuilder: (_, index) => ListTile(
                          title: Text(
                            'Item $index',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        itemCount: 50,
                      ),
          );
        },
      ),
    );
  }
}
