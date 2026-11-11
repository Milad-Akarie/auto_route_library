import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/189976:
// a setState that lands after a frame's build phase stops every later
// setState from scheduling a frame, so the app stops painting.
// Setup, without auto_route (the reporter's second, debug-visible repro):
// two independent widgets, and a frame callback that runs after drawFrame,
// still in the persistentCallbacks phase, and calls setState on the first.
// Steps: run one frame, then setState the second widget while idle.
// Today the first setState marks its scope as having a build scheduled
// (widgets/framework.dart, BuildOwner.scheduleBuildFor and
// BuildScope._scheduleBuildFor), but ensureVisualUpdate does nothing in that
// phase (scheduler/binding.dart, ensureVisualUpdate), so no frame comes and
// the flags are never cleared: the idle setState schedules nothing either.
// Only an explicit scheduleFrame repairs it. The reporter reached it in
// release builds when a page popped by the iOS back swipe was disposed during
// finalizeTree and its dispose notified a listener that called setState; a
// commenter measured the same freeze with auto_route. auto_route never calls
// scheduleFrame itself.
// If this test fails after a Flutter upgrade, a late setState no longer
// stops frames: drop this canary.
void main() {
  testWidgets('a setState after drawFrame stops later frames', (tester) async {
    late StateSetter setFirst;
    late StateSetter setSecond;
    var first = 0;
    var second = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: .ltr,
        child: Column(
          children: [
            StatefulBuilder(
              builder: (_, setState) {
                setFirst = setState;
                return Text('First $first');
              },
            ),
            StatefulBuilder(
              builder: (_, setState) {
                setSecond = setState;
                return Text('Second $second');
              },
            ),
          ],
        ),
      ),
    );
    var isArmed = true;
    SchedulerBinding.instance
      ..addPersistentFrameCallback((_) {
        if (isArmed) {
          isArmed = false;
          setFirst(() => first++);
        }
      })
      ..scheduleFrame();
    await tester.pump();
    setSecond(() => second++);
    final hasFrameAfterIdleSetState =
        SchedulerBinding.instance.hasScheduledFrame;
    await tester.pump();
    final shownBeforeRepair = (
      find.text('First 1').evaluate().length,
      find.text('Second 1').evaluate().length,
    );

    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();

    expect(hasFrameAfterIdleSetState, isFalse);
    expect(shownBeforeRepair, (0, 0));
    expect(find.text('First 1'), findsOneWidget);
    expect(find.text('Second 1'), findsOneWidget);
  });
}
