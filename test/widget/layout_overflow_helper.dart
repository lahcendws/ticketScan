import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails with the offending flex and child descriptions when a horizontal
/// row paints beyond the width assigned to it.
void expectNoHorizontalOverflow(WidgetTester tester, {required String label}) {
  final offenders = <String>[];

  for (final object in tester.allRenderObjects) {
    if (object is! RenderFlex || object.direction != Axis.horizontal) {
      continue;
    }

    final maxWidth = object.constraints.maxWidth;
    if (!maxWidth.isFinite || maxWidth <= 0) {
      continue;
    }

    if (object.size.width > maxWidth + precisionErrorTolerance) {
      offenders.add(
        '${object.toStringShort()} '
        '(width=${object.size.width.toStringAsFixed(1)}, '
        'maxWidth=${maxWidth.toStringAsFixed(1)}) exceeds its constraints',
      );
    }

    RenderBox? child = object.firstChild;
    while (child != null) {
      final parentData = child.parentData;
      if (parentData is FlexParentData) {
        final leftEdge = parentData.offset.dx;
        final rightEdge = leftEdge + child.size.width;
        if (leftEdge < -precisionErrorTolerance ||
            rightEdge > object.size.width + precisionErrorTolerance) {
          offenders.add(
            '${object.toStringShort()} '
            '(width=${object.size.width.toStringAsFixed(1)}, '
            'maxWidth=${maxWidth.toStringAsFixed(1)}) contains '
            '${child.toStringShort()} from '
            'x=${leftEdge.toStringAsFixed(1)} to '
            'x=${rightEdge.toStringAsFixed(1)}',
          );
        }
      }
      child = object.childAfter(child);
    }
  }

  expect(
    offenders,
    isEmpty,
    reason: '$label has horizontal overflow:\n${offenders.join('\n')}',
  );
}
