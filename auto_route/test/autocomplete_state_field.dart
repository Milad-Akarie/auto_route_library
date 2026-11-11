import 'package:material_ui/material_ui.dart';

/// An Autocomplete text field labeled 'State', offering Texas, Tennessee and
/// New York.
///
/// Focusing it with an empty text shows all three options; text no option
/// holds, such as 'q', hides them. flutter/flutter#194873's tests use it to
/// open and close the options overlay above a focused field.
class AutocompleteStateField extends StatelessWidget {
  /// Creates the field.
  const new({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 300,
      child: Autocomplete<String>(
        optionsBuilder: (value) => ['Texas', 'Tennessee', 'New York'].where(
          (option) => option.toLowerCase().contains(value.text.toLowerCase()),
        ),
        fieldViewBuilder: (context, controller, focusNode, _) => TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(labelText: 'State'),
        ),
      ),
    ),
  );
}
