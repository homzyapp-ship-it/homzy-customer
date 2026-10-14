import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations_plus/flutter_staggered_animations_plus.dart';

enum StaggeredListType {
  column,
  row,
  listView,
  gridView,
}

class StaggeredListAnimator extends StatelessWidget {
  final List<Widget> children;
  final StaggeredListType type;
  final double verticalOffset;
  final double horizontalOffset;
  final Duration duration;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;
  final SliverGridDelegate? gridDelegate;
  final int? columnCount;
  final Axis scrollDirection;

  const StaggeredListAnimator({
    super.key,
    required this.children,
    this.type = StaggeredListType.column,
    this.verticalOffset = 40.0,
    this.horizontalOffset = 0.0,
    this.duration = const Duration(milliseconds: 300),
    this.physics,
    this.padding,
    this.shrinkWrap = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
    this.gridDelegate,
    this.columnCount,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    if (type == StaggeredListType.gridView) {
      assert(gridDelegate != null, 'gridDelegate is required for gridView layout');
      return AnimationLimiter(
        child: GridView.builder(
          physics: physics,
          padding: padding,
          shrinkWrap: shrinkWrap,
          gridDelegate: gridDelegate!,
          itemCount: children.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: duration,
              columnCount: columnCount ?? 2,
              child: SlideAnimation(
                verticalOffset: verticalOffset,
                horizontalOffset: horizontalOffset,
                curve: Curves.easeOutCubic,
                child: FadeInAnimation(
                  child: children[index],
                ),
              ),
            );
          },
        ),
      );
    }

    if (type == StaggeredListType.listView) {
      return AnimationLimiter(
        child: ListView.separated(
          scrollDirection: scrollDirection,
          physics: physics,
          padding: padding,
          shrinkWrap: shrinkWrap,
          itemCount: children.length,
          separatorBuilder: (context, index) => spacing != null
              ? (scrollDirection == Axis.horizontal ? SizedBox(width: spacing) : SizedBox(height: spacing))
              : const SizedBox.shrink(),
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: duration,
              child: SlideAnimation(
                verticalOffset: verticalOffset,
                horizontalOffset: horizontalOffset,
                curve: Curves.easeOutCubic,
                child: FadeInAnimation(
                  child: children[index],
                ),
              ),
            );
          },
        ),
      );
    }

    final double vOffset = type == StaggeredListType.row && verticalOffset == 40.0 ? 0.0 : verticalOffset;
    final double hOffset = type == StaggeredListType.row && horizontalOffset == 0.0 ? 40.0 : horizontalOffset;

    final animatedChildren = AnimationConfiguration.toStaggeredList(
      duration: duration,
      childAnimationBuilder: (widget) => SlideAnimation(
        verticalOffset: vOffset,
        horizontalOffset: hOffset,
        curve: Curves.easeOutCubic,
        child: FadeInAnimation(
          child: widget,
        ),
      ),
      children: type == StaggeredListType.row ? children.reversed.toList() : children,
    );

    final finalChildren = <Widget>[];
    for (var i = 0; i < animatedChildren.length; i++) {
      if (type == StaggeredListType.row) {
        finalChildren.add(Expanded(child: animatedChildren[i]));
        if (i < animatedChildren.length - 1 && spacing != null) {
          finalChildren.add(SizedBox(width: spacing));
        }
      } else {
        finalChildren.add(animatedChildren[i]);
        if (i < animatedChildren.length - 1 && spacing != null) {
          finalChildren.add(SizedBox(height: spacing));
        }
      }
    }

    return AnimationLimiter(
      child: type == StaggeredListType.row
          ? Row(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children: finalChildren,
            )
          : Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children: finalChildren,
            ),
    );
  }
}
