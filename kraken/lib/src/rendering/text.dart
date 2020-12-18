/*
 * Copyright (C) 2019-present Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:kraken/dom.dart';
import 'package:kraken/rendering.dart';
import 'package:kraken/css.dart';

class TextParentData extends ContainerBoxParentData<RenderBox> {}

enum WhiteSpace {
  normal,
  nowrap,
  pre,
  preWrap,
  preLine,
  breakSpaces
}

class RenderTextBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderTextBox(InlineSpan text, {
    this.targetId,
    this.style,
    this.elementManager,
  }) : assert(text != null) {
    _renderParagraph = RenderParagraph(
      text,
      textDirection: TextDirection.ltr,
    );

    child = _renderParagraph;
  }

  RenderParagraph _renderParagraph;
  int targetId;
  CSSStyleDeclaration style;
  ElementManager elementManager;

  BoxSizeType widthSizeType;
  BoxSizeType heightSizeType;

  // Auto value for min-width
  double autoMinWidth = 0;
  // Auto value for min-height
  double autoMinHeight = 0;

  set text(InlineSpan value) {
    assert(_renderParagraph != null);
    _renderParagraph.text = value;
  }

  set textAlign(TextAlign value) {
    assert(_renderParagraph != null);
    _renderParagraph.textAlign = value;
  }

  set overflow(TextOverflow value) {
    assert(_renderParagraph != null);
    _renderParagraph.overflow = value;
  }

  set maxLines(int value) {
    assert(_renderParagraph != null);
    // Forcing a break after a set number of lines
    // https://drafts.csswg.org/css-overflow-3/#max-lines
    _renderParagraph.maxLines = value;
  }

  // Box size equals to RenderBox.size to avoid flutter complain when read size property.
  Size _boxSize;
  Size get boxSize {
    assert(_boxSize != null, 'box does not have laid out.');
    return _boxSize;
  }

  set size(Size value) {
    _boxSize = value;
    super.size = value;
  }

  WhiteSpace _whiteSpace;
  WhiteSpace get whiteSpace {
    return _whiteSpace;
  }
  set whiteSpace(WhiteSpace value) {
    if (value == whiteSpace) return;
    _whiteSpace = value;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TextParentData) {
      child.parentData = TextParentData();
    }
  }

  @override
  void performLayout() {
    if (child != null) {
      BoxConstraints boxConstraints;
      Node hostTextNode = elementManager.getEventTargetByTargetId<EventTarget>(targetId);
      Element parentElement = hostTextNode.parent;
      double maxConstraintWidth = RenderBoxModel.getMaxConstraintWidth(parentElement.renderBoxModel);

      if (parentElement.style[DISPLAY] == NONE) {
        boxConstraints = BoxConstraints(
          minWidth: 0,
          maxWidth: 0,
          minHeight: 0,
          maxHeight: 0,
        );
      } else if (maxConstraintWidth != null && (whiteSpace != WhiteSpace.nowrap || _renderParagraph.overflow == TextOverflow.ellipsis)) {
        boxConstraints = BoxConstraints(
          minWidth: 0,
          maxWidth: maxConstraintWidth,
          minHeight: 0,
          maxHeight: double.infinity
        );
      } else {
        boxConstraints = constraints;
      }
      child.layout(boxConstraints, parentUsesSize: true);
      size = child.size;

      autoMinWidth = size.width;
      autoMinHeight = size.height;
    } else {
      performResize();
    }
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return _renderParagraph.computeDistanceToActualBaseline(TextBaseline.ideographic);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child, offset);
    }
  }

  // Determine whether the hittest position is within the visible area of the parent node in scroll.
  bool isParentViewContainsPosition (Offset position) {
    AbstractNode parentNode = parent;
    final globalPosition = localToGlobal(position);
    bool isContainsPosition = true;
    while (parentNode is RenderBoxModel) {
      final node =(parentNode as RenderBoxModel);
      if ((node.style[OVERFLOW_Y] != '' && node.style[OVERFLOW_Y] != VISIBLE) || (node.style[OVERFLOW_X] != '' && node.style[OVERFLOW_X] != VISIBLE) || (node.style[OVERFLOW] != '' && node.style[OVERFLOW] != VISIBLE)) {
        final position =  node.globalToLocal(globalPosition);
        isContainsPosition &= node.size.contains(position);
      }
      parentNode = parentNode.parent;
    }
    return isContainsPosition;
  }

  // Text node need hittest self to trigger scroll
  @override
  bool hitTest(BoxHitTestResult result, { Offset position }) {
    // Prioritize whether position belongs to the current size, so that each node does not need to traverse all its superiors.
    return size.contains(position) && isParentViewContainsPosition(position);
  }
}
