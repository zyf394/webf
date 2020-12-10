import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:kraken/rendering.dart';
import 'package:kraken/dom.dart';
import 'package:kraken/css.dart';

/// Infos of each run (flex line) in flex layout
/// https://www.w3.org/TR/css-flexbox-1/#flex-lines
class _RunMetrics {
  _RunMetrics(
    this.mainAxisExtent,
    this.crossAxisExtent,
    double totalFlexGrow,
    double totalFlexShrink,
    this.baselineExtent,
    this.runChildren,
    double remainingFreeSpace,
  ) : _totalFlexGrow = totalFlexGrow,
    _totalFlexShrink = totalFlexShrink,
    _remainingFreeSpace = remainingFreeSpace;

  // Main size extent of the run
  final double mainAxisExtent;
  // Cross size extent of the run
  final double crossAxisExtent;

  // Total flex grow factor in the run
  double get totalFlexGrow => _totalFlexGrow;
  double _totalFlexGrow;
  set totalFlexGrow(double value) {
    assert(value != null);
    if (_totalFlexGrow != value) {
      _totalFlexGrow = value;
    }
  }

  // Total flex shrink factor in the run
  double get totalFlexShrink => _totalFlexShrink;
  double _totalFlexShrink;
  set totalFlexShrink(double value) {
    assert(value != null);
    if (_totalFlexShrink != value) {
      _totalFlexShrink = value;
    }
  }

  // Max extent above each flex items in the run
  final double baselineExtent;
  // All the children RenderBox of layout in the run
  final Map<int, _RunChild> runChildren;

  // Remaining free space in the run
  double get remainingFreeSpace => _remainingFreeSpace;
  double _remainingFreeSpace = 0;
  set remainingFreeSpace(double value) {
    assert(value != null);
    if (_remainingFreeSpace != value) {
      _remainingFreeSpace = value;
    }
  }
}

/// Infos about Flex item in the run
class _RunChild {
  _RunChild(
    RenderBox child,
    double originalMainSize,
    double adjustedMainSize,
    bool frozen,
  ) : _child = child,
      _originalMainSize = originalMainSize,
      _adjustedMainSize = adjustedMainSize,
      _frozen = frozen;

  /// Render object of flex item
  RenderBox get child => _child;
  RenderBox _child;
  set child(RenderBox value) {
    assert(value != null);
    if (_child != value) {
      _child = value;
    }
  }

  /// Original main size on first layout
  double get originalMainSize => _originalMainSize;
  double _originalMainSize;
  set originalMainSize(double value) {
    assert(value != null);
    if (_originalMainSize != value) {
      _originalMainSize = value;
    }
  }

  /// Adjusted main size after flexible length resolve algorithm
  double get adjustedMainSize => _adjustedMainSize;
  double _adjustedMainSize;
  set adjustedMainSize(double value) {
    assert(value != null);
    if (_adjustedMainSize != value) {
      _adjustedMainSize = value;
    }
  }

  /// Whether flex item should be frozen in flexible length resolve algorithm
  bool get frozen => _frozen;
  bool _frozen = false;
  set frozen(bool value) {
    assert(value != null);
    if (_frozen != value) {
      _frozen = value;
    }
  }
}

class RenderFlexParentData extends RenderLayoutParentData {
  /// Flex grow
  double flexGrow;

  /// Flex shrink
  double flexShrink;

  /// Flex basis
  String flexBasis;

  /// Align self
  AlignSelf alignSelf = AlignSelf.auto;

  @override
  String toString() =>
      '${super.toString()}; flexGrow=$flexGrow; flexShrink=$flexShrink; flexBasis=$flexBasis; alignSelf=$alignSelf';
}

bool _startIsTopLeft(FlexDirection direction) {
  assert(direction != null);

  switch (direction) {
    case FlexDirection.column:
    case FlexDirection.row:
      return true;
    case FlexDirection.rowReverse:
    case FlexDirection.columnReverse:
      return false;
  }

  return null;
}

/// ## Layout algorithm
///
/// _This section describes how the framework causes [RenderFlexLayout] to position
/// its children._
///
/// Layout for a [RenderFlexLayout] proceeds in 5 steps:
///
/// 1. Layout placeholder child of positioned element(absolute/fixed) in new layer
/// 2. Layout no positioned children with no constraints, compare children width with flex container main axis extent
///    to caculate total flex lines
/// 3. Caculate horizontal constraints of each child according to availabe horizontal space in each flex line
///    and flex-grow and flex-shrink properties
/// 4. Caculate vertical constraints of each child accordint to availabe vertical space in flex container vertial
///    and align-content properties and set
/// 5. Layout children again with above cacluated constraints
/// 6. Caculate flex line leading space and between space and position children in each flex line
///
class RenderFlexLayout extends RenderLayoutBox {
  /// Creates a flex render object.
  ///
  /// By default, the flex layout is horizontal and children are aligned to the
  /// start of the main axis and the center of the cross axis.
  RenderFlexLayout({
    List<RenderBox> children,
    FlexDirection flexDirection = FlexDirection.row,
    FlexWrap flexWrap = FlexWrap.nowrap,
    JustifyContent justifyContent = JustifyContent.flexStart,
    AlignItems alignItems = AlignItems.stretch,
    AlignContent alignContent = AlignContent.stretch,
    int targetId,
    ElementManager elementManager,
    CSSStyleDeclaration style,
  })  : assert(flexDirection != null),
        assert(flexWrap != null),
        assert(justifyContent != null),
        assert(alignItems != null),
        assert(alignContent != null),
        _flexDirection = flexDirection,
        _flexWrap = flexWrap,
        _justifyContent = justifyContent,
        _alignContent = alignContent,
        _alignItems = alignItems,
        super(targetId: targetId, style: style, elementManager: elementManager) {
    addAll(children);
  }

  /// The direction to use as the main axis.
  FlexDirection get flexDirection => _flexDirection;
  FlexDirection _flexDirection;

  set flexDirection(FlexDirection value) {
    assert(value != null);
    if (_flexDirection != value) {
      _flexDirection = value;
      markNeedsLayout();
    }
  }

  /// whether flex items are forced onto one line or can wrap onto multiple lines.
  FlexWrap get flexWrap => _flexWrap;
  FlexWrap _flexWrap;

  set flexWrap(FlexWrap value) {
    assert(value != null);
    if (_flexWrap != value) {
      _flexWrap = value;
      markNeedsLayout();
    }
  }

  JustifyContent get justifyContent => _justifyContent;
  JustifyContent _justifyContent;

  set justifyContent(JustifyContent value) {
    assert(value != null);
    if (_justifyContent != value) {
      _justifyContent = value;
      markNeedsLayout();
    }
  }

  AlignItems get alignItems => _alignItems;
  AlignItems _alignItems;

  set alignItems(AlignItems value) {
    assert(value != null);
    if (_alignItems != value) {
      _alignItems = value;
      markNeedsLayout();
    }
  }

  AlignContent get alignContent => _alignContent;
  AlignContent _alignContent;
  set alignContent(AlignContent value) {
    assert(value != null);
    if (_alignContent == value) return;
    _alignContent = value;
    markNeedsLayout();
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow;

  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! RenderFlexParentData) {
      child.parentData = RenderFlexParentData();
    }
    if (child is RenderBoxModel) {
      child.parentData = CSSPositionedLayout.getPositionParentData(child.style, child.parentData);
    }
  }

  double _getIntrinsicSize({
    FlexDirection sizingDirection,
    double extent, // the extent in the direction that isn't the sizing direction
    double Function(RenderBox child, double extent) childSize, // a method to find the size in the sizing direction
  }) {
    if (_flexDirection == sizingDirection) {
      // INTRINSIC MAIN SIZE
      // Intrinsic main size is the smallest size the flex container can take
      // while maintaining the min/max-content contributions of its flex items.
      double totalFlexGrow = 0.0;
      double inflexibleSpace = 0.0;
      double maxFlexFractionSoFar = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        final double flex = _getFlexGrow(child);
        totalFlexGrow += flex;
        if (flex > 0) {
          final double flexFraction = childSize(child, extent) / _getFlexGrow(child);
          maxFlexFractionSoFar = math.max(maxFlexFractionSoFar, flexFraction);
        } else {
          inflexibleSpace += childSize(child, extent);
        }
        final RenderFlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
      return maxFlexFractionSoFar * totalFlexGrow + inflexibleSpace;
    } else {
      // INTRINSIC CROSS SIZE
      // Intrinsic cross size is the max of the intrinsic cross sizes of the
      // children, after the flexible children are fit into the available space,
      // with the children sized using their max intrinsic dimensions.

      // Get inflexible space using the max intrinsic dimensions of fixed children in the main direction.
      final double availableMainSpace = extent;
      double totalFlexGrow = 0;
      double inflexibleSpace = 0.0;
      double maxCrossSize = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        final double flex = _getFlexGrow(child);
        totalFlexGrow += flex;
        double mainSize;
        double crossSize;
        if (flex == 0) {
          switch (_flexDirection) {
            case FlexDirection.rowReverse:
            case FlexDirection.row:
              mainSize = child.getMaxIntrinsicWidth(double.infinity);
              crossSize = childSize(child, mainSize);
              break;
            case FlexDirection.column:
            case FlexDirection.columnReverse:
              mainSize = child.getMaxIntrinsicHeight(double.infinity);
              crossSize = childSize(child, mainSize);
              break;
          }
          inflexibleSpace += mainSize;
          maxCrossSize = math.max(maxCrossSize, crossSize);
        }
        final RenderFlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }

      // Determine the spacePerFlex by allocating the remaining available space.
      // When you're overconstrained spacePerFlex can be negative.
      final double spacePerFlex = math.max(0.0, (availableMainSpace - inflexibleSpace) / totalFlexGrow);

      // Size remaining (flexible) items, find the maximum cross size.
      child = firstChild;
      while (child != null) {
        final double flex = _getFlexGrow(child);
        if (flex > 0) maxCrossSize = math.max(maxCrossSize, childSize(child, spacePerFlex * flex));
        final RenderFlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }

      return maxCrossSize;
    }
  }

  /// Get start/end padding in the main axis according to flex direction
  double flowAwareMainAxisPadding({bool isEnd = false}) {
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return isEnd ? paddingRight : paddingLeft;
    } else {
      return isEnd ? paddingBottom : paddingTop;
    }
  }

  /// Get start/end padding in the cross axis according to flex direction
  double flowAwareCrossAxisPadding({bool isEnd = false}) {
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return isEnd ? paddingBottom : paddingTop;
    } else {
      return isEnd ? paddingRight : paddingLeft;
    }
  }

  /// Get start/end border in the main axis according to flex direction
  double flowAwareMainAxisBorder({bool isEnd = false}) {
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return isEnd ? borderRight : borderLeft;
    } else {
      return isEnd ? borderBottom : borderTop;
    }
  }

  /// Get start/end border in the cross axis according to flex direction
  double flowAwareCrossAxisBorder({bool isEnd = false}) {
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return isEnd ? borderBottom : borderTop;
    } else {
      return isEnd ? borderRight : borderLeft;
    }
  }

  /// Get start/end margin of child in the main axis according to flex direction
  double flowAwareChildMainAxisMargin(RenderBox child, {bool isEnd = false}) {
    RenderBoxModel childRenderBoxModel;
    if (child is RenderBoxModel) {
      childRenderBoxModel = _getChildRenderBoxModel(child);
    }
    if (childRenderBoxModel == null) {
      return 0;
    }

    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return isEnd ? childRenderBoxModel.marginRight : childRenderBoxModel.marginLeft;
    } else {
      return isEnd ? childRenderBoxModel.marginBottom : childRenderBoxModel.marginTop;
    }
  }

  /// Get start/end margin of child in the cross axis according to flex direction
  double flowAwareChildCrossAxisMargin(RenderBox child, {bool isEnd = false}) {
    RenderBoxModel childRenderBoxModel;
    if (child is RenderBoxModel) {
      childRenderBoxModel = _getChildRenderBoxModel(child);
    }
    if (childRenderBoxModel == null) {
      return 0;
    }
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return isEnd ? childRenderBoxModel.marginBottom : childRenderBoxModel.marginTop;
    } else {
      return isEnd ? childRenderBoxModel.marginRight : childRenderBoxModel.marginLeft;
    }
  }

  RenderBoxModel _getChildRenderBoxModel(RenderBoxModel child) {
    Element childEl = elementManager.getEventTargetByTargetId<Element>(child.targetId);
    RenderBoxModel renderBoxModel = childEl.renderBoxModel;
    return renderBoxModel;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: FlexDirection.row,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicWidth(extent),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: FlexDirection.row,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicWidth(extent),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: FlexDirection.column,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicHeight(extent),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: FlexDirection.column,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicHeight(extent),
    );
  }

  double _getFlexGrow(RenderBox child) {
    // Flex grow has no effect on placeholder of positioned element
    if (child is RenderPositionHolder) {
      return 0;
    }
    final RenderFlexParentData childParentData = child.parentData;
    return childParentData.flexGrow ?? 0;
  }

  double _getFlexShrink(RenderBox child) {
    // Flex shrink has no effect on placeholder of positioned element
    if (child is RenderPositionHolder) {
      return 0;
    }
    final RenderFlexParentData childParentData = child.parentData;
    return childParentData.flexShrink ?? 1;
  }

  String _getFlexBasis(RenderBox child) {
    // Flex basis has no effect on placeholder of positioned element
    if (child is RenderPositionHolder) {
      return AUTO;
    }
    final RenderFlexParentData childParentData = child.parentData;
    return childParentData.flexBasis ?? AUTO;
  }

  double _getMaxMainAxisSize(RenderBox child) {
    double maxMainSize;
    if (child is RenderBoxModel) {
      maxMainSize = CSSFlex.isHorizontalFlexDirection(flexDirection) ?
        child.maxWidth : child.maxHeight;
    }
    return maxMainSize ?? double.infinity;
  }

  /// Calculate automatic minimum size of flex item
  /// Refer to https://www.w3.org/TR/css-flexbox-1/#min-size-auto for detail rules
  double _getMinMainAxisSize(RenderBox child) {
    double minMainSize;

    double contentSize = 0;
    // Min width of flex item if min-width is not specified use auto min width instead
    double minWidth = 0;
    // Min height of flex item if min-height is not specified use auto min height instead
    double minHeight = 0;
    if (child is RenderBoxModel) {
      minWidth = child.minWidth != null ? child.minWidth : child.autoMinWidth;
      minHeight = child.minHeight != null ? child.minHeight : child.autoMinHeight;
    } else if (child is RenderTextBox) {
      minWidth =  child.autoMinWidth;
      minHeight =  child.autoMinHeight;
    }
    contentSize = CSSFlex.isHorizontalFlexDirection(flexDirection) ?
      minWidth : minHeight;

    if (child is RenderIntrinsic && child.intrinsicRatio != null &&
      CSSFlex.isHorizontalFlexDirection(flexDirection) && child.width == null
    ) {
      double transferredSize = child.height != null ?
       child.height * child.intrinsicRatio : child.intrinsicWidth;
      minMainSize = math.min(contentSize, transferredSize);
    } else if (child is RenderIntrinsic && child.intrinsicRatio != null &&
      CSSFlex.isVerticalFlexDirection(flexDirection) && child.height == null
    ) {
      double transferredSize = child.width != null ?
        child.width / child.intrinsicRatio : child.intrinsicHeight;
      minMainSize = math.min(contentSize, transferredSize);
    } else if (child is RenderBoxModel) {
      double specifiedMainSize = CSSFlex.isHorizontalFlexDirection(flexDirection) ?
        RenderBoxModel.getContentWidth(child) : RenderBoxModel.getContentHeight(child);
      minMainSize = specifiedMainSize != null ?
        math.min(contentSize, specifiedMainSize) : contentSize;
    } else if (child is RenderTextBox) {
      minMainSize = contentSize;
    }

    return minMainSize;
  }

  double _getShrinkConstraints(RenderBox child, Map<int, _RunChild> runChildren, double remainingFreeSpace) {
    double totalWeightedFlexShrink = 0;
    runChildren.forEach((int targetId, _RunChild runChild) {
      double childOriginalMainSize = runChild.originalMainSize;
      RenderBox child = runChild.child;
      if (!runChild.frozen) {
        double childFlexShrink = _getFlexShrink(child);
        totalWeightedFlexShrink += childOriginalMainSize * childFlexShrink;
      }
    });

    int childNodeId;
    if (child is RenderTextBox) {
      childNodeId = child.targetId;
    } else if (child is RenderBoxModel) {
      childNodeId = child.targetId;
    }

    _RunChild current = runChildren[childNodeId];
    double currentOriginalMainSize = current.originalMainSize;
    double currentFlexShrink = _getFlexShrink(current.child);
    double currentExtent = currentFlexShrink * currentOriginalMainSize;
    double minusConstraints = (currentExtent / totalWeightedFlexShrink) * remainingFreeSpace;

    return minusConstraints;
  }

  BoxSizeType _getChildWidthSizeType(RenderBox child) {
    if (child is RenderTextBox) {
      return child.widthSizeType;
    } else if (child is RenderBoxModel) {
      return child.widthSizeType;
    }
    return null;
  }

  BoxSizeType _getChildHeightSizeType(RenderBox child) {
    if (child is RenderTextBox) {
      return child.heightSizeType;
    } else if (child is RenderBoxModel) {
      return child.heightSizeType;
    }
    return null;
  }

  bool _isCrossAxisDefinedSize(RenderBox child) {
    BoxSizeType widthSizeType = _getChildWidthSizeType(child);
    BoxSizeType heightSizeType = _getChildHeightSizeType(child);

    if (style != null) {
      if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
        return heightSizeType != null && heightSizeType == BoxSizeType.specified;
      } else {
        return widthSizeType != null && widthSizeType == BoxSizeType.specified;
      }
    }

    return false;
  }

  double _getCrossAxisExtent(RenderBox child) {
    double marginHorizontal = 0;
    double marginVertical = 0;

    RenderBoxModel childRenderBoxModel;
    if (child is RenderBoxModel) {
      childRenderBoxModel = _getChildRenderBoxModel(child);
    } else if (child is RenderPositionHolder) {
      // Position placeholder of flex item need to layout as its original renderBox
      // so it needs to add margin to its extent
      childRenderBoxModel = child.realDisplayedBox;
    }

    if (childRenderBoxModel != null) {
      marginHorizontal = childRenderBoxModel.marginLeft + childRenderBoxModel.marginRight;
      marginVertical = childRenderBoxModel.marginTop + childRenderBoxModel.marginBottom;
    }

    Size childSize = _getChildSize(child);
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return childSize.height + marginVertical;
    } else {
      return childSize.width + marginHorizontal;
    }
  }

  bool _isChildMainAxisClip(RenderBoxModel renderBoxModel) {
    if (renderBoxModel is RenderIntrinsic) {
      return false;
    }
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return renderBoxModel.clipX;
    } else {
      return renderBoxModel.clipY;
    }
  }

  double _getMainAxisExtent(RenderBox child) {
    double marginHorizontal = 0;
    double marginVertical = 0;

    RenderBoxModel childRenderBoxModel;
    if (child is RenderBoxModel) {
      childRenderBoxModel = _getChildRenderBoxModel(child);
    } else if (child is RenderPositionHolder) {
      // Position placeholder of flex item need to layout as its original renderBox
      // so it needs to add margin to its extent
      childRenderBoxModel = child.realDisplayedBox;
    }

    if (childRenderBoxModel != null) {
      marginHorizontal = childRenderBoxModel.marginLeft + childRenderBoxModel.marginRight;
      marginVertical = childRenderBoxModel.marginTop + childRenderBoxModel.marginBottom;
    }

    double baseSize = _getMainSize(child);
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return baseSize + marginHorizontal;
    } else {
      return baseSize + marginVertical;
    }
  }

  BoxConstraints _getBaseConstraints(RenderObject child) {
    double minWidth = 0;
    double maxWidth = double.infinity;
    double minHeight = 0;
    double maxHeight = double.infinity;

    if (child is RenderBoxModel) {

      String flexBasis = _getFlexBasis(child);
      double baseSize;
      // @FIXME when flex-basis is smaller than content width, it will not take effects
      if (flexBasis != AUTO) {
        baseSize = CSSLength.toDisplayPortValue(flexBasis) ?? 0;
      }
      if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
        minWidth = child.minWidth != null ? child.minWidth : 0;
        maxWidth = child.maxWidth != null ? child.maxWidth : double.infinity;

        if (flexBasis == AUTO) {
          baseSize = child.width;
        }
        if (baseSize != null) {
          if (child.minWidth != null && baseSize < child.minWidth) {
            baseSize = child.minWidth;
          } else if (child.maxWidth != null && baseSize > child.maxWidth) {
            baseSize = child.maxWidth;
          }
          minWidth = maxWidth = baseSize;
        }
      } else {
        minHeight = child.minHeight != null ? child.minHeight : 0;
        maxHeight = child.maxHeight != null ? child.maxHeight : double.infinity;

        if (flexBasis == AUTO) {
          baseSize = child.height;
        }
        if (baseSize != null) {
          if (child.minHeight != null && baseSize < child.minHeight) {
            baseSize = child.minHeight;
          } else if (child.maxHeight != null && baseSize > child.maxHeight) {
            baseSize = child.maxHeight;
          }
          minHeight = maxHeight = baseSize;
        }
      }
    }

    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return BoxConstraints(
        minWidth: minWidth,
        maxWidth: maxWidth,
      );
    } else {
      return BoxConstraints(
        minHeight: minHeight,
        maxHeight: maxHeight,
      );
    }
  }

  double _getBaseSize(RenderObject child) {
    // set default value
    double baseSize;
    if (child is RenderTextBox) {
      return baseSize;
    } else if (child is RenderBoxModel) {
      String flexBasis = _getFlexBasis(child);

      if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
        String width = child.style[WIDTH];
        if (flexBasis == AUTO) {
          if (width != null) {
            baseSize = CSSLength.toDisplayPortValue(width) ?? 0;
          }
        } else {
          baseSize = CSSLength.toDisplayPortValue(flexBasis) ?? 0;
        }
      } else {
        String height = child.style[HEIGHT];
        if (flexBasis == AUTO) {
          if (height != '') {
            baseSize = CSSLength.toDisplayPortValue(height) ?? 0;
          }
        } else {
          baseSize = CSSLength.toDisplayPortValue(flexBasis) ?? 0;
        }
      }
    }
    return baseSize;
  }

  double _getMainSize(RenderBox child) {
    Size childSize = _getChildSize(child);
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return childSize.width;
    } else {
      return childSize.height;
    }
  }

  @override
  void performLayout() {
    if (display == CSSDisplay.none) {
      size = constraints.smallest;
      return;
    }

    beforeLayout();
    RenderBox child = firstChild;
    Element element = elementManager.getEventTargetByTargetId<Element>(targetId);
    // Layout positioned element
    while (child != null) {
      final RenderFlexParentData childParentData = child.parentData;
      // Layout placeholder of positioned element(absolute/fixed) in new layer
      if (childParentData.isPositioned) {
        CSSPositionedLayout.layoutPositionedChild(element, this, child);
      } else if (child is RenderPositionHolder && isPlaceholderPositioned(child)) {
        _layoutChildren(child);
      }

      child = childParentData.nextSibling;
    }
    // Layout non positioned element and its placeholder
    _layoutChildren(null);

    // Set offset of positioned element
    child = firstChild;
    while (child != null) {
      final RenderLayoutParentData childParentData = child.parentData;

      if (child is RenderBoxModel && childParentData.isPositioned) {
        CSSPositionedLayout.applyPositionedChildOffset(this, child, size, borderEdge);

        setMaximumScrollableSizeForPositionedChild(childParentData, child.boxSize);
      }
      child = childParentData.nextSibling;
    }

    didLayout();
  }

  bool _isChildDisplayNone(RenderObject child) {
    CSSStyleDeclaration style;
    if (child is RenderTextBox) {
      style = child.style;
    } else if (child is RenderBoxModel) {
      style = child.style;
    }

    if (style == null) return false;

    return style[DISPLAY] == NONE;
  }

  bool isPlaceholderPositioned(RenderObject child) {
    if (child is RenderPositionHolder) {
      RenderBoxModel realDisplayedBox = child.realDisplayedBox;
      CSSPositionType positionType = CSSPositionedLayout.parsePositionType(realDisplayedBox.style[POSITION]);
      if (positionType == CSSPositionType.absolute || positionType == CSSPositionType.fixed) {
        return true;
      }
    }
    return false;
  }

  /// There are 4 stages when layouting children
  /// 1. Layout children in flow order to calculate flex lines according to its constaints and flex-wrap property
  /// 2. Relayout children according to flex-grow and flex-shrink factor
  /// 3. Set flex container size according to children size
  /// 4. Align children according to justify-content, align-items and align-self properties
  void _layoutChildren(RenderPositionHolder placeholderChild) {
    final double contentWidth = RenderBoxModel.getContentWidth(this);
    final double contentHeight = RenderBoxModel.getContentHeight(this);

    CSSDisplay realDisplay = CSSSizing.getElementRealDisplayValue(targetId, elementManager);

    /// If no child exists, stop layout.
    if (childCount == 0) {
      double constraintWidth = contentWidth ?? 0;
      double constraintHeight = contentHeight ?? 0;

      bool isInline = realDisplay == CSSDisplay.inline;
      bool isInlineFlex = realDisplay == CSSDisplay.inlineFlex;

      if (!isInline) {
        // Base width when width no exists, inline-flex has width of 0
        double baseWidth = isInlineFlex ? 0 : constraintWidth;
        if (maxWidth != null && width == null) {
          constraintWidth = baseWidth > maxWidth ? maxWidth : baseWidth;
        } else if (minWidth != null && width == null) {
          constraintWidth = baseWidth < minWidth ? minWidth : baseWidth;
        }

        // Base height always equals to 0 no matter
        double baseHeight = 0;
        if (maxHeight != null && height == null) {
          constraintHeight = baseHeight > maxHeight ? maxHeight : baseHeight;
        } else if (minHeight != null && height == null) {
          constraintHeight = baseHeight < minHeight ? minHeight : baseHeight;
        }
      }

      setMaxScrollableSize(constraintWidth, constraintHeight);

      size = getBoxSize(Size(
        constraintWidth,
        constraintHeight,
      ));
      return;
    }
    assert(contentConstraints != null);

    // Metrics of each flex line
    final List<_RunMetrics> runMetrics = <_RunMetrics>[];
    // Max size of scrollable area
    Map<int, double> maxScrollableWidthMap = Map();
    Map<int, double> maxScrollableHeightMap = Map();
    // Flex container size in main and cross direction
    Map<String, double> containerSizeMap = {
      'main': 0.0,
      'cross': 0.0,
    };

    /// Stage 1: Layout children in flow order to calculate flex lines
    _layoutByFlexLine(
      runMetrics,
      placeholderChild,
      containerSizeMap,
      contentWidth,
      contentHeight,
      maxScrollableWidthMap,
      maxScrollableHeightMap,
    );

    /// If no non positioned child exists, stop layout
    if (runMetrics.length == 0) {
      Size preferredSize = Size(
        contentWidth ?? 0,
        contentHeight ?? 0,
      );
      setMaxScrollableSize(preferredSize.width, preferredSize.height);
      size = getBoxSize(preferredSize);
      return;
    }

    double containerCrossAxisExtent = 0.0;

    bool isVerticalDirection = CSSFlex.isVerticalFlexDirection(_flexDirection);
    if (isVerticalDirection) {
      containerCrossAxisExtent = contentWidth ?? 0;
    } else {
      containerCrossAxisExtent = contentHeight ?? 0;
    }

    /// Calculate leading and between space between flex lines
    final double crossAxisFreeSpace = containerCrossAxisExtent - containerSizeMap['cross'];
    final int runCount = runMetrics.length;
    double runLeadingSpace = 0.0;
    double runBetweenSpace = 0.0;
    /// Align-content only works in when flex-wrap is no nowrap
    if (flexWrap == FlexWrap.wrap || flexWrap == FlexWrap.wrapReverse) {
      switch (alignContent) {
        case AlignContent.flexStart:
        case AlignContent.start:
          break;
        case AlignContent.flexEnd:
        case AlignContent.end:
          runLeadingSpace = crossAxisFreeSpace;
          break;
        case AlignContent.center:
          runLeadingSpace = crossAxisFreeSpace / 2.0;
          break;
        case AlignContent.spaceBetween:
          if (crossAxisFreeSpace < 0) {
            runBetweenSpace = 0;
          } else {
            runBetweenSpace = runCount > 1 ? crossAxisFreeSpace / (runCount - 1) : 0.0;
          }
          break;
        case AlignContent.spaceAround:
          if (crossAxisFreeSpace < 0) {
            runLeadingSpace = crossAxisFreeSpace / 2.0;
            runBetweenSpace = 0;
          } else {
            runBetweenSpace = crossAxisFreeSpace / runCount;
            runLeadingSpace = runBetweenSpace / 2.0;
          }
          break;
        case AlignContent.spaceEvenly:
          if (crossAxisFreeSpace < 0) {
            runLeadingSpace = crossAxisFreeSpace / 2.0;
            runBetweenSpace = 0;
          } else {
            runBetweenSpace = crossAxisFreeSpace / (runCount + 1);
            runLeadingSpace = runBetweenSpace;
          }
          break;
        case AlignContent.stretch:
          runBetweenSpace = crossAxisFreeSpace / runCount;
          if (runBetweenSpace < 0) {
            runBetweenSpace = 0;
          }
          break;
      }
    }

    /// Stage 2: Layout flex item second time based on flex factor and actual size
    _relayoutByFlexFactor(
      runMetrics,
      runBetweenSpace,
      placeholderChild,
      contentWidth,
      contentHeight,
      containerSizeMap,
      maxScrollableWidthMap,
      maxScrollableHeightMap,
    );

    /// Stage 3: Set flex container size according to children size
    _setContainerSize(
      runMetrics,
      containerSizeMap,
      contentWidth,
      contentHeight,
      maxScrollableWidthMap,
      maxScrollableHeightMap,
    );

    /// Stage 4: Set children offset based on flex alignment properties
    _alignChildren(
      runMetrics,
      runBetweenSpace,
      runLeadingSpace,
      placeholderChild,
      containerSizeMap,
      maxScrollableWidthMap,
      maxScrollableHeightMap,
    );
  }

  /// 1. Layout children in flow order to calculate flex lines according to its constaints and flex-wrap property
  void _layoutByFlexLine(
    List<_RunMetrics> runMetrics,
    RenderPositionHolder placeholderChild,
    Map<String, double> containerSizeMap,
    double contentWidth,
    double contentHeight,
    Map<int, double> maxScrollableWidthMap,
    Map<int, double> maxScrollableHeightMap,
  ) {
    double mainAxisExtent = 0.0;
    double crossAxisExtent = 0.0;
    double runMainAxisExtent = 0.0;
    double runCrossAxisExtent = 0.0;

    // Determine used flex factor, size inflexible items, calculate free space.
    double totalFlexGrow = 0;
    double totalFlexShrink = 0;

    double maxSizeAboveBaseline = 0;
    double maxSizeBelowBaseline = 0;

    // Max length of each flex line
    double flexLineLimit = 0.0;

    bool isAxisHorizontalDirection = CSSFlex.isHorizontalFlexDirection(flexDirection);
    if (isAxisHorizontalDirection) {
      double maxConstraintWidth = RenderBoxModel.getMaxConstraintWidth(this);
      flexLineLimit = contentWidth != null ? contentWidth : maxConstraintWidth;
    } else {
      // Children in vertical direction should not wrap if height no exists
      double maxContentHeight = double.infinity;
      flexLineLimit = contentHeight != null ? contentHeight : maxContentHeight;
    }

    RenderBox child = placeholderChild ?? firstChild;

    // Infos about each flex item in each flex line
    Map<int, _RunChild> runChildren = {};

    while (child != null) {
      final RenderFlexParentData childParentData = child.parentData;
      // Exclude positioned placeholder renderObject when layout non placeholder object
      // and positioned renderObject
      if (placeholderChild == null && (isPlaceholderPositioned(child) || childParentData.isPositioned)) {
        child = childParentData.nextSibling;
        continue;
      }

      double baseSize = _getBaseSize(child);
      BoxConstraints innerConstraints;

      int childNodeId;
      if (child is RenderTextBox) {
        childNodeId = child.targetId;
      } else if (child is RenderBoxModel) {
        childNodeId = child.targetId;
      }

      CSSStyleDeclaration childStyle = _getChildStyle(child);
      BoxSizeType heightSizeType = _getChildHeightSizeType(child);
      BoxConstraints baseConstraints = _getBaseConstraints(child);

      if (child is RenderPositionHolder) {
        RenderBoxModel realDisplayedBox = child.realDisplayedBox;
        // Flutter only allow access size of direct children, so cannot use realDisplayedBox.size
        Size realDisplayedBoxSize = realDisplayedBox.getBoxSize(realDisplayedBox.contentSize);
        double realDisplayedBoxWidth = realDisplayedBoxSize.width;
        double realDisplayedBoxHeight = realDisplayedBoxSize.height;
        innerConstraints = BoxConstraints(
          minWidth: realDisplayedBoxWidth,
          maxWidth: realDisplayedBoxWidth,
          minHeight: realDisplayedBoxHeight,
          maxHeight: realDisplayedBoxHeight,
        );
      } else if (CSSFlex.isHorizontalFlexDirection(_flexDirection)) {
        double maxCrossAxisSize;
        // Calculate max height constraints
        if (heightSizeType == BoxSizeType.specified && childStyle[HEIGHT] != '') {
          maxCrossAxisSize = CSSLength.toDisplayPortValue(childStyle[HEIGHT]);
        } else {
          // Child in flex line expand automatic when height is not specified
          if (flexWrap == FlexWrap.wrap || flexWrap == FlexWrap.wrapReverse) {
            maxCrossAxisSize = double.infinity;
          } else if (child is RenderTextBox) {
            maxCrossAxisSize = double.infinity;
          } else {
            // Should substract margin when layout child
            double marginVertical = 0;
            if (child is RenderBoxModel) {
              RenderBoxModel childRenderBoxModel = _getChildRenderBoxModel(child);
              marginVertical = childRenderBoxModel.marginTop + childRenderBoxModel.marginBottom;
            }
            maxCrossAxisSize = contentHeight != null ? contentHeight - marginVertical : double.infinity;
          }
        }

        innerConstraints = BoxConstraints(
          minWidth: baseConstraints.minWidth,
          maxWidth: baseConstraints.maxWidth,
          maxHeight: maxCrossAxisSize,
        );
      } else {
        innerConstraints = BoxConstraints(
          minHeight: baseSize != null ? baseSize : 0
        );
      }

      BoxConstraints childConstraints = deflateOverflowConstraints(innerConstraints);

      // Whether child need to layout
      bool isChildNeedsLayout = true;
      if (child is RenderBoxModel && child.hasSize) {
        double childContentWidth = RenderBoxModel.getContentWidth(child);
        double childContentHeight = RenderBoxModel.getContentHeight(child);
        // Always layout child when parent is not laid out yet or child is marked as needsLayout
        if (!hasSize || child.needsLayout) {
          isChildNeedsLayout = true;
        } else {
          Size childOldSize = _getChildSize(child);
          // Need to layout child when width and height of child are both specified and differ from its previous size
          isChildNeedsLayout = childContentWidth != null && childContentHeight != null &&
            (childOldSize.width != childContentWidth ||
              childOldSize.height != childContentHeight);
        }
      }
      if (isChildNeedsLayout) {
        child.layout(childConstraints, parentUsesSize: true);
      }

      double childMainAxisExtent = _getMainAxisExtent(child);
      double childCrossAxisExtent = _getCrossAxisExtent(child);

      Size childSize = _getChildSize(child);
      // update max scrollable size
      if (child is RenderBoxModel) {
        maxScrollableWidthMap[child.targetId] = math.max(child.maxScrollableSize.width, childSize.width);
        maxScrollableHeightMap[child.targetId] = math.max(child.maxScrollableSize.height, childSize.height);
      }

      bool isExceedFlexLineLimit = runMainAxisExtent + childMainAxisExtent > flexLineLimit;

      // calculate flex line
      if ((flexWrap == FlexWrap.wrap || flexWrap == FlexWrap.wrapReverse) &&
        runChildren.length > 0 && isExceedFlexLineLimit) {

        mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
        crossAxisExtent += runCrossAxisExtent;

        runMetrics.add(_RunMetrics(
          runMainAxisExtent,
          runCrossAxisExtent,
          totalFlexGrow,
          totalFlexShrink,
          maxSizeAboveBaseline,
          runChildren,
          0
        ));
        runChildren = {};
        runMainAxisExtent = 0.0;
        runCrossAxisExtent = 0.0;
        maxSizeAboveBaseline = 0.0;
        maxSizeBelowBaseline = 0.0;

        totalFlexGrow = 0;
        totalFlexShrink = 0;
      }
      runMainAxisExtent += childMainAxisExtent;
      runCrossAxisExtent = math.max(runCrossAxisExtent, childCrossAxisExtent);

      /// Calculate baseline extent of layout box
      AlignSelf alignSelf = childParentData.alignSelf;
      // Vertical align is only valid for inline box
      // Baseline alignment in column direction behave the same as flex-start
      if (CSSFlex.isHorizontalFlexDirection(flexDirection) &&
        (alignSelf == AlignSelf.baseline || alignItems == AlignItems.baseline)) {
        // Distance from top to baseline of child
        double childAscent = _getChildAscent(child);
        CSSStyleDeclaration childStyle = _getChildStyle(child);
        double lineHeight = CSSText.getLineHeight(childStyle);

        Size childSize = _getChildSize(child);
        // Leading space between content box and virtual box of child
        double childLeading = 0;
        if (lineHeight != null) {
          childLeading = lineHeight - childSize.height;
        }

        double childMarginTop = 0;
        double childMarginBottom = 0;
        if (child is RenderBoxModel) {
          RenderBoxModel childRenderBoxModel = _getChildRenderBoxModel(child);
          childMarginTop = childRenderBoxModel.marginTop;
          childMarginBottom = childRenderBoxModel.marginBottom;
        }
        maxSizeAboveBaseline = math.max(
          childAscent + childLeading / 2,
          maxSizeAboveBaseline,
        );
        maxSizeBelowBaseline = math.max(
          childMarginTop + childMarginBottom + childSize.height - childAscent + childLeading / 2,
          maxSizeBelowBaseline,
        );
        runCrossAxisExtent = maxSizeAboveBaseline + maxSizeBelowBaseline;
      } else {
        runCrossAxisExtent = math.max(runCrossAxisExtent, childCrossAxisExtent);
      }

      runChildren[childNodeId] = _RunChild(
        child,
        _getMainSize(child),
        0,
        false,
      );

      childParentData.runIndex = runMetrics.length;

      assert(child.parentData == childParentData);

      final double flexGrow = _getFlexGrow(child);
      final double flexShrink = _getFlexShrink(child);
      if (flexGrow > 0) {
        totalFlexGrow += flexGrow;
      }
      if (flexShrink > 0) {
        totalFlexShrink += flexShrink;
      }
      // Only layout placeholder renderObject child
      child = placeholderChild == null ? childParentData.nextSibling : null;
    }

    if (runChildren.length > 0) {
      mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
      crossAxisExtent += runCrossAxisExtent;
      runMetrics.add(_RunMetrics(
        runMainAxisExtent,
        runCrossAxisExtent,
        totalFlexGrow,
        totalFlexShrink,
        maxSizeAboveBaseline,
        runChildren,
        0
      ));

      containerSizeMap['cross'] = crossAxisExtent;
    }
  }

  /// Resolve flex item length if flex-grow or flex-shrink exists
  /// https://www.w3.org/TR/css-flexbox-1/#resolve-flexible-lengths
  bool _resolveFlexibleLengths(
    _RunMetrics runMetric,
    double initialFreeSpace,
  ) {
    Map<int, _RunChild> runChildren = runMetric.runChildren;
    double totalFlexGrow = runMetric.totalFlexGrow;
    double totalFlexShrink = runMetric.totalFlexShrink;
    bool isFlexGrow = initialFreeSpace >= 0 && totalFlexGrow > 0;
    bool isFlexShrink = initialFreeSpace < 0 && totalFlexShrink > 0;

    double sumFlexFactors = isFlexGrow ? totalFlexGrow : totalFlexShrink;
    /// If the sum of the unfrozen flex items’ flex factors is less than one,
    /// multiply the initial free space by this sum as remaining free space
    if (sumFlexFactors > 0 && sumFlexFactors < 1) {
      double remainingFreeSpace = initialFreeSpace;
      double fractional = initialFreeSpace * sumFlexFactors;
      if (fractional.abs() < remainingFreeSpace.abs()) {
        remainingFreeSpace = fractional;
      }
      runMetric.remainingFreeSpace = remainingFreeSpace;
    }

    List<_RunChild> minViolations = [];
    List<_RunChild> maxViolations = [];
    double totalViolation = 0;

    /// Loop flex item to find min/max violations
    runChildren.forEach((int index, _RunChild runChild) {
      if (runChild.frozen) {
        return;
      }
      RenderBox child = runChild.child;
      RenderFlexParentData childParentData = child.parentData;
      final double mainSize = _getMainSize(child);

      double computedSize = mainSize; /// Computed size by flex factor
      double adjustedSize = mainSize; /// Adjusted size after min and max size clamp
      double flexGrow = childParentData.flexGrow;
      double flexShrink = childParentData.flexShrink;

      int childNodeId;
      if (child is RenderTextBox) {
        childNodeId = child.targetId;
      } else if (child is RenderBoxModel) {
        childNodeId = child.targetId;
      }

      double remainingFreeSpace = runMetric.remainingFreeSpace;
      if (isFlexGrow && flexGrow != null && flexGrow > 0) {
        final double spacePerFlex = totalFlexGrow > 0 ? (remainingFreeSpace / totalFlexGrow) : double.nan;
        final double flexGrow = _getFlexGrow(child);
        computedSize = mainSize + spacePerFlex * flexGrow;
      } else if (isFlexShrink && flexShrink != null && flexShrink > 0) {
        _RunChild current = runChildren[childNodeId];
        /// If child's mainAxis have clips, it will create a new format context in it's children's.
        /// so we do't need to care about child's size.
        if (child is RenderBoxModel && _isChildMainAxisClip(child)) {
          computedSize = current.originalMainSize + remainingFreeSpace;
        } else {
          double shrinkValue = _getShrinkConstraints(child, runChildren, remainingFreeSpace);
          computedSize = current.originalMainSize + shrinkValue;
        }
      }

      adjustedSize = computedSize;
      /// Find all the violations by comparing min and max size of flex items
      if (child is RenderBoxModel && !_isChildMainAxisClip(child)) {
        double minMainAxisSize = _getMinMainAxisSize(child);
        double maxMainAxisSize = _getMaxMainAxisSize(child);
        if (computedSize < minMainAxisSize) {
          adjustedSize = minMainAxisSize;
        } else if (computedSize > maxMainAxisSize) {
          adjustedSize = maxMainAxisSize;
        }
      }

      double violation = adjustedSize - computedSize;
      /// Collect all the flex items with violations
      if (violation > 0) {
        minViolations.add(runChild);
      } else if (violation < 0) {
        maxViolations.add(runChild);
      }
      runChild.adjustedMainSize = adjustedSize;
      totalViolation += violation;
    });

    /// Freeze over-flexed items
    if (totalViolation == 0) {
      /// If total violation is zero, freeze all the flex items and exit loop
      runChildren.forEach((int index, _RunChild runChild) {
        runChild.frozen = true;
      });
    } else {
      List<_RunChild> violations = totalViolation < 0 ? maxViolations : minViolations;
      /// Find all the violations, set main size and freeze all the flex items
      for (int i = 0; i < violations.length; i++) {
        _RunChild runChild = violations[i];
        runChild.frozen = true;
        RenderBox child = runChild.child;
        RenderFlexParentData childParentData = child.parentData;
        runMetric.remainingFreeSpace -= runChild.adjustedMainSize - runChild.originalMainSize;

        /// If total violation is positive, freeze all the items with min violations
        if (childParentData.flexGrow > 0) {
          runMetric.totalFlexGrow -= childParentData.flexGrow;
        /// If total violation is negative, freeze all the items with max violations
        } else if (childParentData.flexShrink > 0) {
          runMetric.totalFlexShrink -= childParentData.flexShrink;
        }
      }
    }

    return totalViolation != 0;
  }

  /// Stage 2: Set size of flex item based on flex factors and min and max constraints and relayout
  ///  https://www.w3.org/TR/css-flexbox-1/#resolve-flexible-lengths
  void _relayoutByFlexFactor(
    List<_RunMetrics> runMetrics,
    double runBetweenSpace,
    RenderPositionHolder placeholderChild,
    double contentWidth,
    double contentHeight,
    Map<String, double> containerSizeMap,
    Map<int, double> maxScrollableWidthMap,
    Map<int, double> maxScrollableHeightMap,
  ) {
    RenderBox child = placeholderChild != null ? placeholderChild : firstChild;

    // Container's width specified by style or inherited from parent
    double containerWidth = 0;
    if (contentWidth != null) {
      containerWidth = contentWidth;
    } else if (contentConstraints.hasTightWidth) {
      containerWidth = contentConstraints.maxWidth;
    }

    // Container's height specified by style or inherited from parent
    double containerHeight = 0;
    if (contentHeight != null) {
      containerHeight = contentHeight;
    } else if (contentConstraints.hasTightHeight) {
      containerHeight = contentConstraints.maxHeight;
    }

    double maxMainSize = CSSFlex.isHorizontalFlexDirection(_flexDirection) ? containerWidth : containerHeight;
    final BoxSizeType mainSizeType = maxMainSize == 0.0 ? BoxSizeType.automatic : BoxSizeType.specified;

    // Find max size of flex lines
    _RunMetrics maxMainSizeMetrics = runMetrics.reduce((_RunMetrics curr, _RunMetrics next) {
      return curr.mainAxisExtent > next.mainAxisExtent ? curr : next;
    });
    // Actual main axis size of flex items
    double maxAllocatedMainSize = maxMainSizeMetrics.mainAxisExtent;
    // Main axis size of flex container
    containerSizeMap['main'] = mainSizeType != BoxSizeType.automatic ? maxMainSize : maxAllocatedMainSize;

    for (int i = 0; i < runMetrics.length; ++i) {
      final _RunMetrics metrics = runMetrics[i];
      final double runMainAxisExtent = metrics.mainAxisExtent;
      final double runCrossAxisExtent = metrics.crossAxisExtent;
      final double totalFlexGrow = metrics.totalFlexGrow;
      final double totalFlexShrink = metrics.totalFlexShrink;
      final bool canFlex = maxMainSize < double.infinity;

      // Distribute free space to flexible children, and determine baseline.
      final double initialFreeSpace = mainSizeType == BoxSizeType.automatic ?
        0 : (canFlex ? maxMainSize : 0.0) - runMainAxisExtent;

      bool isFlexGrow = initialFreeSpace >= 0 && totalFlexGrow > 0;
      bool isFlexShrink = initialFreeSpace < 0 && totalFlexShrink > 0;

      if (isFlexGrow || isFlexShrink) {
        /// remainingFreeSpace starts out at the same value as initialFreeSpace
        /// but as we place and lay out flex items we subtract from it.
        metrics.remainingFreeSpace = initialFreeSpace;
        /// Loop flex items to resolve flexible length of flex items with flex factor
        while(_resolveFlexibleLengths(metrics, initialFreeSpace));
      }

      while (child != null) {
        final RenderFlexParentData childParentData = child.parentData;

        AlignSelf alignSelf = childParentData.alignSelf;

        // If size exists in align-items direction, stretch not works
        bool isStretchSelfValid = false;
        if (child is RenderBoxModel) {
          isStretchSelfValid = CSSFlex.isHorizontalFlexDirection(flexDirection) ?
            child.height == null : child.width == null;
        }

        // Whether child should be stretched
        bool isStretchSelf = placeholderChild == null && isStretchSelfValid &&
          (alignSelf != AlignSelf.auto ? alignSelf == AlignSelf.stretch : alignItems == AlignItems.stretch);

        // Whether child is positioned placeholder or positioned renderObject
        bool isChildPositioned = placeholderChild == null &&
          (isPlaceholderPositioned(child) || childParentData.isPositioned);
        // Whether child cross size should be changed based on cross axis alignment change
        bool isCrossSizeChanged = false;

        if (child is RenderBoxModel && child.hasSize) {
          Size childSize = _getChildSize(child);
          double childContentWidth = RenderBoxModel.getContentWidth(child);
          double childContentHeight = RenderBoxModel.getContentHeight(child);

          double childLogicalWidth = childContentWidth != null ?
            childContentWidth + child.borderLeft + child.borderRight + child.paddingLeft + child.paddingRight :
            null;
          double childLogicalHeight = childContentHeight != null ?
            childContentHeight + child.borderTop + child.borderBottom + child.paddingTop + child.paddingBottom :
            null;

          // Cross size calculated from style which not including padding and border
          double childCrossLogicalSize = CSSFlex.isHorizontalFlexDirection(flexDirection) ?
            childLogicalHeight : childLogicalWidth;
          // Cross size from first layout
          double childCrossSize = CSSFlex.isHorizontalFlexDirection(flexDirection) ?
          childSize.height : childSize.width;

          isCrossSizeChanged = childCrossSize != childCrossLogicalSize;
        }

        // Don't need to relayout child in following cases
        // 1. child is placeholder when in layout non placeholder stage
        // 2. child is positioned renderObject, it needs to layout in its special stage
        // 3. child's size don't need to recompute if no flex-grow、flex-shrink or cross size not changed
        if (isChildPositioned || (!isFlexGrow && !isFlexShrink && !isCrossSizeChanged)) {
          child = childParentData.nextSibling;
          continue;
        }

        if (childParentData.runIndex != i) break;

        // Whether child need to layout
        bool isChildNeedsLayout = true;
        if (child is RenderBoxModel && child.hasSize) {
          double childContentWidth = RenderBoxModel.getContentWidth(child);
          double childContentHeight = RenderBoxModel.getContentHeight(child);
          RenderFlexParentData childParentData = child.parentData;

          // Always layout child when parent is not laid out yet or child is marked as needsLayout
          if (!hasSize || child.needsLayout) {
            isChildNeedsLayout = true;
          } else {
            // Need to relayout child when flex factor exists
            if ((isFlexGrow && childParentData.flexGrow > 0) ||
              (isFlexShrink) && childParentData.flexShrink > 0) {
              isChildNeedsLayout = true;
            } else if (isStretchSelf) {
              Size childOldSize = _getChildSize(child);
              // Need to layout child when width and height of child are both specified and differ from its previous size
              isChildNeedsLayout = childContentWidth != null && childContentHeight != null &&
                (childOldSize.width != childContentWidth ||
                  childOldSize.height != childContentHeight);
            }
          }
        }

        if (!isChildNeedsLayout) {
          child = childParentData.nextSibling;
          continue;
        }

        double maxChildExtent;
        double minChildExtent;

        if (_isChildDisplayNone(child)) {
          // Skip No Grow and unsized child.
          child = childParentData.nextSibling;
          continue;
        }

        Size childSize = _getChildSize(child);

        int childNodeId;
        if (child is RenderTextBox) {
          childNodeId = child.targetId;
        } else if (child is RenderBoxModel) {
          childNodeId = child.targetId;
        }

        double mainSize = isFlexGrow || isFlexShrink ?
          metrics.runChildren[childNodeId].adjustedMainSize : _getMainSize(child);
        maxChildExtent = minChildExtent = mainSize;

        BoxConstraints innerConstraints;
        if (isStretchSelf) {
          switch (_flexDirection) {
            case FlexDirection.row:
            case FlexDirection.rowReverse:
              double minMainAxisSize = minChildExtent ?? childSize.width;
              double maxMainAxisSize = maxChildExtent ?? double.infinity;
              double minCrossAxisSize;
              double maxCrossAxisSize;

              // if child have predefined size
              if (_isCrossAxisDefinedSize(child)) {
                BoxSizeType sizeType = _getChildHeightSizeType(child);

                // child have predefined height, use previous layout height.
                if (sizeType == BoxSizeType.specified) {
                  // for empty child width, maybe it's unloaded image, set constraints range.
                  if (childSize.isEmpty) {
                    minCrossAxisSize = 0.0;
                    maxCrossAxisSize = contentConstraints.maxHeight;
                  } else {
                    minCrossAxisSize = childSize.height;
                    maxCrossAxisSize = double.infinity;
                  }
                } else {
                  // expand child's height to contentConstraints.maxHeight;
                  minCrossAxisSize = contentConstraints.maxHeight;
                  maxCrossAxisSize = contentConstraints.maxHeight;
                }
              } else if (child is! RenderTextBox) {
                String marginTop;
                String marginBottom;
                if (child is RenderBoxModel) {
                  CSSStyleDeclaration childStyle = child.style;
                  marginTop = childStyle[MARGIN_TOP];
                  marginBottom = childStyle[MARGIN_BOTTOM];
                }
                // Margin auto alignment takes priority over align-items stretch,
                // it will not stretch child in vertical direction
                if (marginTop == AUTO || marginBottom == AUTO) {
                  minCrossAxisSize = childSize.height;
                  maxCrossAxisSize = double.infinity;
                } else {
                  double flexLineHeight = _getFlexLineHeight(runCrossAxisExtent, runBetweenSpace);
                  // Should substract margin when layout child
                  double marginVertical = 0;
                  if (child is RenderBoxModel) {
                    RenderBoxModel childRenderBoxModel = _getChildRenderBoxModel(child);
                    marginVertical = childRenderBoxModel.marginTop + childRenderBoxModel.marginBottom;
                  }
                  minCrossAxisSize = flexLineHeight - marginVertical;
                  maxCrossAxisSize = double.infinity;
                }
              } else {
                minCrossAxisSize = 0.0;
                maxCrossAxisSize = double.infinity;
              }
              innerConstraints = BoxConstraints(
                minWidth: minMainAxisSize,
                maxWidth: maxMainAxisSize,
                minHeight: minCrossAxisSize,
                maxHeight: maxCrossAxisSize);
              break;
            case FlexDirection.column:
            case FlexDirection.columnReverse:
              double mainAxisMinSize = minChildExtent ?? childSize.height;
              double mainAxisMaxSize = maxChildExtent ?? double.infinity;
              double minCrossAxisSize;
              double maxCrossAxisSize;

              // if child have predefined size
              if (_isCrossAxisDefinedSize(child)) {
                BoxSizeType sizeType = _getChildWidthSizeType(child);

                // child have predefined width, use previous layout width.
                if (sizeType == BoxSizeType.specified) {
                  // for empty child width, maybe it's unloaded image, set contentConstraints range.
                  if (childSize.isEmpty) {
                    minCrossAxisSize = 0.0;
                    maxCrossAxisSize = contentConstraints.maxWidth;
                  } else {
                    minCrossAxisSize = childSize.width;
                    maxCrossAxisSize = double.infinity;
                  }
                } else {
                  // expand child's height to contentConstraints.maxWidth;
                  minCrossAxisSize = contentConstraints.maxWidth;
                  maxCrossAxisSize = contentConstraints.maxWidth;
                }
              } else if (child is! RenderTextBox) {
                String marginLeft;
                String marginRight;
                if (child is RenderBoxModel) {
                  CSSStyleDeclaration childStyle = child.style;
                  marginLeft = childStyle[MARGIN_LEFT];
                  marginRight = childStyle[MARGIN_RIGHT];
                }
                // Margin auto alignment takes priority over align-items stretch,
                // it will not stretch child in horizontal direction
                if (marginLeft == AUTO || marginRight == AUTO) {
                  minCrossAxisSize = childSize.width;
                  maxCrossAxisSize = double.infinity;
                } else {
                  double flexLineHeight = _getFlexLineHeight(runCrossAxisExtent, runBetweenSpace);
                  // Should substract margin when layout child
                  double marginHorizontal = 0;
                  if (child is RenderBoxModel) {
                    RenderBoxModel childRenderBoxModel = _getChildRenderBoxModel(child);
                    marginHorizontal = childRenderBoxModel.marginLeft + childRenderBoxModel.marginRight;
                  }

                  minCrossAxisSize = flexLineHeight - marginHorizontal;
                  maxCrossAxisSize = double.infinity;
                }
              } else {
                // for RenderTextBox, there are no cross Axis contentConstraints.
                minCrossAxisSize = 0.0;
                maxCrossAxisSize = double.infinity;
              }
              innerConstraints = BoxConstraints(
                minHeight: mainAxisMinSize,
                maxHeight: mainAxisMaxSize,
                minWidth: minCrossAxisSize,
                maxWidth: maxCrossAxisSize);
              break;
          }
        } else {
          switch (_flexDirection) {
            case FlexDirection.row:
            case FlexDirection.rowReverse:
              innerConstraints = BoxConstraints(
                minWidth: minChildExtent,
                maxWidth: maxChildExtent,
              );
              break;
            case FlexDirection.column:
            case FlexDirection.columnReverse:
              innerConstraints = BoxConstraints(
                minHeight: minChildExtent,
                maxHeight: maxChildExtent
              );
              break;
          }
        }

        child.layout(deflateOverflowConstraints(innerConstraints), parentUsesSize: true);

        // update max scrollable size
        if (child is RenderBoxModel) {
          maxScrollableWidthMap[child.targetId] = math.max(child.maxScrollableSize.width, childSize.width);
          maxScrollableHeightMap[child.targetId] = math.max(child.maxScrollableSize.height, childSize.height);
        }

        containerSizeMap['cross'] = math.max(containerSizeMap['cross'], _getCrossAxisExtent(child));

        // Only layout placeholder renderObject child
        child = childParentData.nextSibling;
      }

    }
  }

  /// Stage 3: Set flex container size according to children size
  void _setContainerSize(
    List<_RunMetrics> runMetrics,
    Map<String, double> containerSizeMap,
    double contentWidth,
    double contentHeight,
    Map<int, double> maxScrollableWidthMap,
    Map<int, double> maxScrollableHeightMap,
  ) {

    // Find max size of flex lines
    _RunMetrics maxMainSizeMetrics = runMetrics.reduce((_RunMetrics curr, _RunMetrics next) {
      return curr.mainAxisExtent > next.mainAxisExtent ? curr : next;
    });
    // Actual main axis size of flex items
    double maxAllocatedMainSize = maxMainSizeMetrics.mainAxisExtent;

    CSSDisplay realDisplay = CSSSizing.getElementRealDisplayValue(targetId, elementManager);
    // Get layout width from children's width by flex axis
    double constraintWidth = CSSFlex.isHorizontalFlexDirection(_flexDirection) ? containerSizeMap['main'] : containerSizeMap['cross'];
    bool isInlineBlock = realDisplay == CSSDisplay.inlineBlock;

    // Constrain to min-width or max-width if width not exists
    double childrenWidth = CSSFlex.isHorizontalFlexDirection(_flexDirection) ? maxAllocatedMainSize : containerSizeMap['cross'];
    if (isInlineBlock && maxWidth != null && width == null) {
      constraintWidth = childrenWidth > maxWidth ? maxWidth : childrenWidth;
    } else if (isInlineBlock && minWidth != null && width == null) {
      constraintWidth = childrenWidth < minWidth ? minWidth : childrenWidth;
    } else if (contentWidth != null) {
      constraintWidth = math.max(constraintWidth, contentWidth);
    }

    // Get layout height from children's height by flex axis
    double constraintHeight = CSSFlex.isHorizontalFlexDirection(_flexDirection) ? containerSizeMap['cross'] : containerSizeMap['main'];
    bool isNotInline = realDisplay != CSSDisplay.inline;

    // Constrain to min-height or max-height if width not exists
    double childrenHeight = CSSFlex.isHorizontalFlexDirection(_flexDirection) ? containerSizeMap['cross'] : maxAllocatedMainSize;
    if (isNotInline && maxHeight != null && height == null) {
      constraintHeight = childrenHeight > maxHeight ? maxHeight : childrenHeight;
    } else if (isNotInline && minHeight != null && height == null) {
      constraintHeight = constraintHeight < minHeight ? minHeight : constraintHeight;
    } else if (contentHeight != null) {
      constraintHeight = math.max(constraintHeight, contentHeight);
    }

    double maxScrollableWidth = 0.0;
    double maxScrollableHeight = 0.0;

    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      maxScrollableWidthMap.forEach((key, value) => maxScrollableWidth += value);
      maxScrollableHeightMap.forEach((key, value) => maxScrollableHeight = math.max(value, maxScrollableHeight));
    } else {
      maxScrollableWidthMap.forEach((key, value) => maxScrollableWidth = math.max(value, maxScrollableWidth));
      maxScrollableHeightMap.forEach((key, value) => maxScrollableHeight += value);
    }

    /// Stage 3: Set flex container size
    Size contentSize = Size(constraintWidth, constraintHeight);
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      setMaxScrollableSize(math.max(contentSize.width, maxScrollableWidth), math.max(contentSize.height, maxScrollableHeight));
    } else {
      setMaxScrollableSize(math.max(contentSize.width, maxScrollableWidth), math.max(contentSize.height, maxScrollableHeight));
    }
    size = getBoxSize(contentSize);

    /// Set auto value of min-width and min-height based on size of flex items
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      autoMinWidth = _getMainAxisAutoSize(runMetrics);
      autoMinHeight = _getCrossAxisAutoSize(runMetrics);
    } else {
      autoMinHeight = _getMainAxisAutoSize(runMetrics);
      autoMinWidth = _getCrossAxisAutoSize(runMetrics);
    }
  }

  /// Get auto min size in the main axis which equals the main axis size of its contents
  /// https://www.w3.org/TR/css-sizing-3/#automatic-minimum-size
  double _getMainAxisAutoSize(
    List<_RunMetrics> runMetrics,
    ) {
    double autoMinSize = 0;
    // Get the length of the line which has the max main size
    _RunMetrics maxMainSizeMetrics = runMetrics.reduce((_RunMetrics curr, _RunMetrics next) {
      return curr.mainAxisExtent > next.mainAxisExtent ? curr : next;
    });
    autoMinSize = maxMainSizeMetrics.mainAxisExtent;
    return autoMinSize;
  }

  /// Get auto min size in the cross axis which equals the cross axis size of its contents
  /// https://www.w3.org/TR/css-sizing-3/#automatic-minimum-size
  double _getCrossAxisAutoSize(
    List<_RunMetrics> runMetrics,
    ) {
    double autoMinSize = 0;
    // Get the sum size of flex lines
    for (_RunMetrics curr in runMetrics) {
      autoMinSize += curr.crossAxisExtent;
    }
    return autoMinSize;
  }

  /// Get flex line height according to flex-wrap style
  double _getFlexLineHeight(double runCrossAxisExtent, double runBetweenSpace) {
    // Flex line of align-content stretch should includes between space
    bool isMultiLineStretch = (flexWrap == FlexWrap.wrap || flexWrap == FlexWrap.wrapReverse) &&
      alignContent == AlignContent.stretch;
    // The height of flex line in single line equals to flex container's cross size
    bool isSingleLine = (flexWrap != FlexWrap.wrap && flexWrap != FlexWrap.wrapReverse);

    if (isSingleLine) {
      return hasSize ? _getContentCrossSize() : runCrossAxisExtent;
    } else if (isMultiLineStretch) {
      return runCrossAxisExtent + runBetweenSpace;
    } else {
      return runCrossAxisExtent;
    }
  }

  // Set flex item offset based on flex alignment properties
  void _alignChildren(
    List<_RunMetrics> runMetrics,
    double runBetweenSpace,
    double runLeadingSpace,
    RenderPositionHolder placeholderChild,
    Map<String, double> containerSizeMap,
    Map<int, double> maxScrollableWidthMap,
    Map<int, double> maxScrollableHeightMap,
    ) {
    RenderBox child = placeholderChild != null ? placeholderChild : firstChild;
    // Cross axis offset of each flex line
    double crossAxisOffset = runLeadingSpace;
    double mainAxisContentSize;
    double crossAxisContentSize;

    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      mainAxisContentSize = contentSize.width;
      crossAxisContentSize = contentSize.height;
    } else {
      mainAxisContentSize = contentSize.height;
      crossAxisContentSize = contentSize.width;
    }

    RenderBox preChild;

    /// Set offset of children
    for (int i = 0; i < runMetrics.length; ++i) {
      final _RunMetrics metrics = runMetrics[i];
      final double runMainAxisExtent = metrics.mainAxisExtent;
      final double runCrossAxisExtent = metrics.crossAxisExtent;
      final double runBaselineExtent = metrics.baselineExtent;
      final double totalFlexGrow = metrics.totalFlexGrow;
      final double totalFlexShrink = metrics.totalFlexShrink;
      final Map<int, _RunChild> runChildren = metrics.runChildren;

      final double mainContentSizeDelta = mainAxisContentSize - runMainAxisExtent;
      bool isFlexGrow = mainContentSizeDelta >= 0 && totalFlexGrow > 0;
      bool isFlexShrink = mainContentSizeDelta < 0 && totalFlexShrink > 0;

      _overflow = math.max(0.0, - mainContentSizeDelta);
      // If flex grow or flex shrink exists, remaining space should be zero
      final double remainingSpace = (isFlexGrow || isFlexShrink) ? 0 : mainContentSizeDelta;
      double leadingSpace;
      double betweenSpace;

      final int runChildrenCount = runChildren.length;

      // flipMainAxis is used to decide whether to lay out left-to-right/top-to-bottom (false), or
      // right-to-left/bottom-to-top (true). The _startIsTopLeft will return null if there's only
      // one child and the relevant direction is null, in which case we arbitrarily decide not to
      // flip, but that doesn't have any detectable effect.
      final bool flipMainAxis = !(_startIsTopLeft(flexDirection) ?? true);
      switch (justifyContent) {
        case JustifyContent.flexStart:
        case JustifyContent.start:
          leadingSpace = 0.0;
          betweenSpace = 0.0;
          break;
        case JustifyContent.flexEnd:
        case JustifyContent.end:
          leadingSpace = remainingSpace;
          betweenSpace = 0.0;
          break;
        case JustifyContent.center:
          leadingSpace = remainingSpace / 2.0;
          betweenSpace = 0.0;
          break;
        case JustifyContent.spaceBetween:
          leadingSpace = 0.0;
          if (remainingSpace < 0) {
            betweenSpace = 0;
          } else {
            betweenSpace = runChildrenCount > 1 ? remainingSpace / (runChildrenCount - 1) : 0.0;
          }
          break;
        case JustifyContent.spaceAround:
          if (remainingSpace < 0) {
            leadingSpace = remainingSpace / 2.0;
            betweenSpace = 0;
          } else {
            betweenSpace = runChildrenCount > 0 ? remainingSpace / runChildrenCount : 0.0;
            leadingSpace = betweenSpace / 2.0;
          }
          break;
        case JustifyContent.spaceEvenly:
          if (remainingSpace < 0) {
            leadingSpace = remainingSpace / 2.0;
            betweenSpace = 0;
          } else {
            betweenSpace = runChildrenCount > 0 ? remainingSpace / (runChildrenCount + 1) : 0.0;
            leadingSpace = betweenSpace;
          }
          break;
        default:
      }

      // Calculate margin auto children in the main axis
      double mainAxisMarginAutoChildren = 0;
      RenderBox runChild = firstChild;
      while (runChild != null) {
        final RenderFlexParentData childParentData = runChild.parentData;
        if (childParentData.runIndex != i) break;
        if (runChild is RenderBoxModel) {
          CSSStyleDeclaration childStyle = runChild.style;
          String marginLeft = childStyle[MARGIN_LEFT];
          String marginTop = childStyle[MARGIN_TOP];

          if ((CSSFlex.isHorizontalFlexDirection(flexDirection) && marginLeft == AUTO) ||
            (CSSFlex.isVerticalFlexDirection(flexDirection) && marginTop == AUTO)) {
            mainAxisMarginAutoChildren++;
          }
        }
        runChild = childParentData.nextSibling;
      }

      // Margin auto alignment takes priority over align-self alignment
      if (mainAxisMarginAutoChildren != 0) {
        leadingSpace = 0;
        betweenSpace = 0;
      }

      double mainAxisStartPadding = flowAwareMainAxisPadding();
      double crossAxisStartPadding = flowAwareCrossAxisPadding();

      double mainAxisStartBorder = flowAwareMainAxisBorder();
      double crossAxisStartBorder = flowAwareCrossAxisBorder();

      // Main axis position of child while layout
      double childMainPosition =
      flipMainAxis ? mainAxisStartPadding + mainAxisStartBorder + mainAxisContentSize - leadingSpace :
      leadingSpace + mainAxisStartPadding + mainAxisStartBorder;

      // Leading between height of line box's content area and line height of line box
      double lineBoxLeading = 0;
      double lineBoxHeight = CSSText.getLineHeight(style);
      if (lineBoxHeight != null) {
        lineBoxLeading = lineBoxHeight - runCrossAxisExtent;
      }

      while (child != null) {

        final RenderFlexParentData childParentData = child.parentData;
        // Exclude positioned placeholder renderObject when layout non placeholder object
        // and positioned renderObject
        if (placeholderChild == null && (isPlaceholderPositioned(child) || childParentData.isPositioned)) {
          child = childParentData.nextSibling;
          continue;
        }
        if (childParentData.runIndex != i) break;

        double childMainAxisMargin = flowAwareChildMainAxisMargin(child);
        double childCrossAxisStartMargin = flowAwareChildCrossAxisMargin(child);

        // Add start margin of main axis when setting offset
        childMainPosition += childMainAxisMargin;

        double childCrossPosition;

        CSSStyleDeclaration childStyle = _getChildStyle(child);

        AlignSelf alignSelf = childParentData.alignSelf;
        double crossStartAddedOffset = crossAxisStartPadding + crossAxisStartBorder + childCrossAxisStartMargin;

        /// Align flex item by direction returned by align-items or align-self
        double alignFlexItem(String alignment) {
          double flexLineHeight = _getFlexLineHeight(runCrossAxisExtent, runBetweenSpace);

          switch (alignment) {
            case 'start':
              return crossStartAddedOffset;
            case 'end':
              // Length returned by _getCrossAxisExtent includes margin, so end alignment should add start margin
              return crossAxisStartPadding + crossAxisStartBorder + flexLineHeight -
                _getCrossAxisExtent(child) + childCrossAxisStartMargin;
            case 'center':
              return childCrossPosition = crossStartAddedOffset + (flexLineHeight - _getCrossAxisExtent(child)) / 2.0;
            case 'baseline':
              // Distance from top to baseline of child
              double childAscent = _getChildAscent(child);
              return crossStartAddedOffset + lineBoxLeading / 2 + (runBaselineExtent - childAscent);
            default:
              return null;
          }
        }

        if (alignSelf == AlignSelf.auto) {
          switch (alignItems) {
            case AlignItems.flexStart:
            case AlignItems.start:
            case AlignItems.stretch:
              childCrossPosition = flexWrap == FlexWrap.wrapReverse ? alignFlexItem('end') : alignFlexItem('start');
              break;
            case AlignItems.flexEnd:
            case AlignItems.end:
              childCrossPosition = flexWrap == FlexWrap.wrapReverse ? alignFlexItem('start') : alignFlexItem('end');
              break;
            case AlignItems.center:
              childCrossPosition = alignFlexItem('center');
              break;
            case AlignItems.baseline:
              // FIXME: baseline aligne in wrap-reverse flexWrap may display different from browser in some case
              if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
                childCrossPosition = alignFlexItem('baseline');
              } else if (flexWrap == FlexWrap.wrapReverse) {
                childCrossPosition = alignFlexItem('end');
              } else {
                childCrossPosition = alignFlexItem('start');
              }
              break;
            default:
              break;
          }
        } else {
          switch (alignSelf) {
            case AlignSelf.flexStart:
            case AlignSelf.start:
            case AlignSelf.stretch:
              childCrossPosition = flexWrap == FlexWrap.wrapReverse ? alignFlexItem('end') : alignFlexItem('start');
              break;
            case AlignSelf.flexEnd:
            case AlignSelf.end:
              childCrossPosition = flexWrap == FlexWrap.wrapReverse ? alignFlexItem('start') : alignFlexItem('end');
              break;
            case AlignSelf.center:
              childCrossPosition = alignFlexItem('center');
              break;
            case AlignSelf.baseline:
              childCrossPosition = alignFlexItem('baseline');
              break;
            default:
              break;
          }
        }

        // Calculate margin auto length according to CSS spec rules
        // https://www.w3.org/TR/css-flexbox-1/#auto-margins
        // margin auto takes up available space in the remaining space
        // between flex items and flex container
        if (child is RenderBoxModel) {
          CSSStyleDeclaration childStyle = child.style;
          String marginLeft = childStyle[MARGIN_LEFT];
          String marginRight = childStyle[MARGIN_RIGHT];
          String marginTop = childStyle[MARGIN_TOP];
          String marginBottom = childStyle[MARGIN_BOTTOM];

          double horizontalRemainingSpace;
          double verticalRemainingSpace;
          // Margin auto does not work with negative remaining space
          double mainAxisRemainingSpace = math.max(0, remainingSpace);
          double crossAxisRemainingSpace = math.max(0, crossAxisContentSize - _getCrossAxisExtent(child));

          if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
            horizontalRemainingSpace = mainAxisRemainingSpace;
            verticalRemainingSpace = crossAxisRemainingSpace;
            if (totalFlexGrow == 0 && marginLeft == AUTO) {
              if (marginRight == AUTO) {
                childMainPosition += (horizontalRemainingSpace / mainAxisMarginAutoChildren) / 2;
                betweenSpace = (horizontalRemainingSpace / mainAxisMarginAutoChildren) / 2;
              } else {
                childMainPosition += horizontalRemainingSpace / mainAxisMarginAutoChildren;
              }
            }

            if (marginTop == AUTO) {
              if (marginBottom == AUTO) {
                childCrossPosition += verticalRemainingSpace / 2;
              } else {
                childCrossPosition += verticalRemainingSpace;
              }
            }
          } else {
            horizontalRemainingSpace = crossAxisRemainingSpace;
            verticalRemainingSpace = mainAxisRemainingSpace;
            if (totalFlexGrow == 0 && marginTop == AUTO) {
              if (marginBottom == AUTO) {
                childMainPosition += (verticalRemainingSpace / mainAxisMarginAutoChildren) / 2;
                betweenSpace = (verticalRemainingSpace / mainAxisMarginAutoChildren) / 2;
              } else {
                childMainPosition += verticalRemainingSpace / mainAxisMarginAutoChildren;
              }
            }

            if (marginLeft == AUTO) {
              if (marginRight == AUTO) {
                childCrossPosition += horizontalRemainingSpace / 2;
              } else {
                childCrossPosition += horizontalRemainingSpace;
              }
            }
          }
        }

        if (flipMainAxis) childMainPosition -= _getMainAxisExtent(child);

        double crossOffset;
        if (flexWrap == FlexWrap.wrapReverse) {
          crossOffset = childCrossPosition + (crossAxisContentSize - crossAxisOffset - runCrossAxisExtent - runBetweenSpace);
        } else {
          crossOffset = childCrossPosition + crossAxisOffset;
        }

        // RenderMargin doesn't support negative margin, it needs to substract
        // negative margin of current child and its pre sibling
        double negativeMarginTop = computeNegativeMarginTop(preChild, child, elementManager);
        double negativeMarginLeft = computeNegativeMarginLeft(preChild, child, elementManager);
        if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
          crossOffset += negativeMarginTop;
          childMainPosition += negativeMarginLeft;
        } else {
          crossOffset += negativeMarginLeft;
          childMainPosition += negativeMarginTop;
        }

        Offset relativeOffset = _getOffset(
          childMainPosition,
          crossOffset
        );

        /// Apply position relative offset change
        CSSPositionedLayout.applyRelativeOffset(relativeOffset, child, childStyle);

        // Need to substract start margin of main axis when calculating next child's start position
        if (flipMainAxis) {
          childMainPosition -= betweenSpace + childMainAxisMargin;
        } else {
          childMainPosition += _getMainAxisExtent(child) - childMainAxisMargin + betweenSpace;
        }

        preChild = child;
        // Only layout placeholder renderObject child
        child = placeholderChild == null ? childParentData.nextSibling : null;
      }

      crossAxisOffset += runCrossAxisExtent + runBetweenSpace;
    }
  }

  /// Get child size through boxSize to avoid flutter error when parentUsesSize is set to false
  Size _getChildSize(RenderBox child) {
    if (child is RenderBoxModel) {
      return child.boxSize;
    } else if (child is RenderPositionHolder) {
      return child.boxSize;
    } else if (child is RenderTextBox) {
      return child.boxSize;
    }
    return null;
  }

  // Get distance from top to baseline of child incluing margin
  double _getChildAscent(RenderBox child) {
    // Distance from top to baseline of child
    double childAscent = child.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true);

    double childMarginTop = 0;
    double childMarginBottom = 0;
    if (child is RenderBoxModel) {
      RenderBoxModel childRenderBoxModel = _getChildRenderBoxModel(child);
      childMarginTop = childRenderBoxModel.marginTop;
      childMarginBottom = childRenderBoxModel.marginBottom;
    }

    Size childSize = _getChildSize(child);
    // When baseline of children not found, use boundary of margin bottom as baseline
    double extentAboveBaseline = childAscent != null ?
    childMarginTop + childAscent :
    childMarginTop + childSize.height + childMarginBottom;

    return extentAboveBaseline;
  }

  CSSStyleDeclaration _getChildStyle(RenderBox child) {
    CSSStyleDeclaration childStyle;
    int childNodeId;
    if (child is RenderTextBox) {
      childNodeId = targetId;
    } else if (child is RenderBoxModel) {
      childNodeId = child.targetId;
    } else if (child is RenderPositionHolder) {
      childNodeId = child.realDisplayedBox?.targetId;
    }
    childStyle = elementManager.getEventTargetByTargetId<Element>(childNodeId)?.style;
    return childStyle;
  }

  Offset _getOffset(double mainAxisOffset, double crossAxisOffset) {
    bool isVerticalDirection = CSSFlex.isVerticalFlexDirection(_flexDirection);
    if (isVerticalDirection) {
      return Offset(crossAxisOffset, mainAxisOffset);
    } else {
      return Offset(mainAxisOffset, crossAxisOffset);
    }
  }
  /// Get cross size of  content size
  double _getContentCrossSize() {
    if (CSSFlex.isHorizontalFlexDirection(flexDirection)) {
      return contentSize.height;
    }
    return contentSize.width;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    if (transform != null) {
      return hitTestLayoutChildren(result, lastChild, position);
    }
    return defaultHitTestChildren(result, position: position);
  }

  Offset getChildScrollOffset(RenderObject child, Offset offset) {
    final RenderLayoutParentData childParentData = child.parentData;
    // Fixed elements always paint original offset
    Offset scrollOffset = childParentData.position == CSSPositionType.fixed ?
    childParentData.offset : childParentData.offset + offset;
    return scrollOffset;
  }

  @override
  void performPaint(PaintingContext context, Offset offset) {
    if (needsSortChildren) {
      if (!isChildrenSorted) {
        sortChildrenByZIndex();
      }
      for (int i = 0; i < sortedChildren.length; i ++) {
        RenderObject child = sortedChildren[i];
        // Don't paint placeholder of positioned element
        if (child is! RenderPositionHolder) {
          context.paintChild(child, getChildScrollOffset(child, offset));
        }
      }
    } else {
      RenderObject child = firstChild;
      while (child != null) {
        final RenderFlexParentData childParentData = child.parentData;
        // Don't paint placeholder of positioned element
        if (child is! RenderPositionHolder) {
          context.paintChild(child, getChildScrollOffset(child, offset));
        }
        child = childParentData.nextSibling;
      }
    }
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => _hasOverflow ? Offset.zero & size : null;

  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (_overflow is double && _hasOverflow) header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FlexDirection>('flexDirection', flexDirection));
    properties.add(DiagnosticsProperty<JustifyContent>('justifyContent', justifyContent));
    properties.add(DiagnosticsProperty<AlignItems>('alignItems', alignItems));
    properties.add(DiagnosticsProperty<FlexWrap>('flexWrap', flexWrap));
  }

  RenderRecyclerLayout toRenderRecyclerLayout() {
    List<RenderBox> children = getDetachedChildrenAsList();
    RenderRecyclerLayout renderRecyclerLayout = RenderRecyclerLayout(
        targetId: targetId,
        style: style,
        elementManager: elementManager
    );
    renderRecyclerLayout.addAll(children);
    return copyWith(renderRecyclerLayout);
  }

  /// Convert [RenderFlexLayout] to [RenderFlowLayout]
  RenderFlowLayout toFlowLayout() {
    List<RenderBox> children = getDetachedChildrenAsList();
    RenderFlowLayout flowLayout = RenderFlowLayout(
      children: children,
      targetId: targetId,
      style: style,
      elementManager: elementManager
    );
    return copyWith(flowLayout);
  }

  /// Convert [RenderFlexLayout] to [RenderSelfRepaintFlexLayout]
  RenderSelfRepaintFlexLayout toSelfRepaint() {
    List<RenderObject> children = getDetachedChildrenAsList();
    RenderSelfRepaintFlexLayout selfRepaintFlexLayout = RenderSelfRepaintFlexLayout(
      children: children,
      targetId: targetId,
      style: style,
      elementManager: elementManager
    );
    return copyWith(selfRepaintFlexLayout);
  }

  /// Convert [RenderFlexLayout] to [RenderSelfRepaintFlowLayout]
  RenderSelfRepaintFlowLayout toSelfRepaintFlowLayout() {
    List<RenderObject> children = getDetachedChildrenAsList();
    RenderSelfRepaintFlowLayout selfRepaintFlowLayout = RenderSelfRepaintFlowLayout(
      children: children,
      targetId: targetId,
      style: style,
      elementManager: elementManager
    );
    return copyWith(selfRepaintFlowLayout);
  }
}

// Render flex layout with self repaint boundary.
class RenderSelfRepaintFlexLayout extends RenderFlexLayout {
  RenderSelfRepaintFlexLayout({
    List<RenderBox> children,
    int targetId,
    ElementManager elementManager,
    CSSStyleDeclaration style,
  }) : super(children: children, targetId: targetId, elementManager: elementManager, style: style);

  @override
  bool get isRepaintBoundary => true;

  /// Convert [RenderSelfRepaintFlexLayout] to [RenderFlowLayout]
  RenderSelfRepaintFlowLayout toFlowLayout() {
    List<RenderObject> children = getDetachedChildrenAsList();
    RenderSelfRepaintFlowLayout selfRepaintFlowLayout = RenderSelfRepaintFlowLayout(
      children: children,
      targetId: targetId,
      style: style,
      elementManager: elementManager
    );
    return copyWith(selfRepaintFlowLayout);
  }

  /// Convert [RenderSelfRepaintFlexLayout] to [RenderFlexLayout]
  RenderFlexLayout toParentRepaint() {
    List<RenderObject> children = getDetachedChildrenAsList();
    RenderFlexLayout flexLayout = RenderFlexLayout(
      children: children,
      targetId: targetId,
      style: style,
      elementManager: elementManager
    );
    return copyWith(flexLayout);
  }

  /// Convert [RenderSelfRepaintFlexLayout] to [RenderFlowLayout]
  RenderFlowLayout toParentRepaintFlowLayout() {
    List<RenderObject> children = getDetachedChildrenAsList();
    RenderFlowLayout flowLayout = RenderFlowLayout(
      children: children,
      targetId: targetId,
      style: style,
      elementManager: elementManager
    );
    return copyWith(flowLayout);
  }
}
