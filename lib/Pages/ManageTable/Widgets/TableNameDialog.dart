import '../../../AdaptiveUI/adaptive_ui.dart';
import 'package:flutter/material.dart';
import '../../../Components/Dialog.dart';
import '../../../generated/l10n.dart';

class TableNameDialog extends StatefulWidget {
  const TableNameDialog({super.key, required this.name});
  final String name;
  @override
  State<TableNameDialog> createState() => _TableNameDialogState();
}

class _TableNameDialogState extends State<TableNameDialog> {
  late final _controller = TextEditingController(text: widget.name);
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => MDialog(
    S.of(context).rename_table,
    Form(
      key: _form,
      child: AdaptiveTextFormField(
        key: const ValueKey('table-name-input'),
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: S.of(context).table_name),
        validator:
            (v) =>
                (v ?? '').trim().isEmpty
                    ? S.of(context).table_name_required
                    : null,
        onFieldSubmitted: (_) => _save(),
      ),
    ),
    widgetCancelAction: () => Navigator.pop(context),
    widgetOK: Text(S.of(context).save),
    widgetOKAction: _save,
  );
}
