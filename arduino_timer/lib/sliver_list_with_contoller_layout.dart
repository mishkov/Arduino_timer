import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class UpdateLayoutController {
  void Function()? layoutUpdater;
}

class SliverListWithControlledLayout extends SliverList {
  const SliverListWithControlledLayout(
      {Key? key,
      this.updateLayoutController,
      required SliverChildDelegate delegate})
      : super(
          key: key,
          delegate: delegate,
        );

  final UpdateLayoutController? updateLayoutController;

  @override
  RenderSliverListWithControlledLayout createRenderObject(
      BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;
    return RenderSliverListWithControlledLayout(
      childManager: element,
      updateLayoutController: updateLayoutController,
    );
  }
}

class RenderSliverListWithControlledLayout extends RenderSliverList {
  RenderSliverListWithControlledLayout(
      {UpdateLayoutController? updateLayoutController,
      required RenderSliverBoxChildManager childManager})
      : super(childManager: childManager) {
    updateLayoutController?.layoutUpdater = () {
      markNeedsLayout();
    };
  }
}
