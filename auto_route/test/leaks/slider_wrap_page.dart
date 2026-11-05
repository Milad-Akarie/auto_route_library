import 'package:material_ui/material_ui.dart';

/// A page of sliders, one per value in [values], each in a Hero, as in
/// flutter/flutter#182287. Adds a weak reference to its state to [states]
/// when it is built.
class SliderWrapPage extends StatefulWidget {
  /// Shows a slider for each of [values] and records into [states].
  const new(this.values, this.states, {super.key});

  /// The values the sliders show and change, shared by every page.
  final List<ValueNotifier<double>> values;

  /// A weak reference to the state of every page built, oldest first.
  final List<WeakReference<State>> states;

  @override
  State<SliderWrapPage> createState() => _SliderWrapPageState();
}

class _SliderWrapPageState extends State<SliderWrapPage> {
  @override
  void initState() {
    super.initState();
    widget.states.add(WeakReference(this));
  }

  @override
  Widget build(BuildContext context) => Wrap(
    children: [
      for (var i = 0; i < widget.values.length; i++)
        Hero(
          tag: 'slider$i',
          child: SizedBox(
            width: 120,
            child: ValueListenableBuilder(
              valueListenable: widget.values[i],
              builder: (context, value, _) => Slider(
                value: value,
                onChanged: (newValue) => widget.values[i].value = newValue,
              ),
            ),
          ),
        ),
    ],
  );
}
