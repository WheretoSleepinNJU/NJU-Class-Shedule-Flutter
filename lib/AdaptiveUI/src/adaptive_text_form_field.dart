import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'adaptive_controls.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;

class AdaptiveTextFormField extends FormField<String> {
  AdaptiveTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    String? initialValue,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofocus = false,
    bool enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.inputFormatters,
    this.onTapOutside,
    this.autofillHints,
    super.onSaved,
    super.validator,
    super.autovalidateMode,
  }) : assert(controller == null || initialValue == null),
       super(
         initialValue: controller?.text ?? initialValue ?? '',
         enabled: enabled,
         builder: (field) {
           final state = field as _AdaptiveTextFormFieldState;
           final w = state.widget as AdaptiveTextFormField;
           // Keep validation outside the platform editor so renderer changes
           // preserve the form field and its error/reset state.
           final input = AdaptiveTextField(
             controller: state.controller,
             autofillHints: w.autofillHints,
             onTapOutside: w.onTapOutside,
             focusNode: w.focusNode,
             decoration: (w.decoration ?? const InputDecoration()).copyWith(
               errorText: state.errorText,
             ),
             keyboardType: w.keyboardType,
             textInputAction: w.textInputAction,
             textCapitalization: w.textCapitalization,
             style: w.style,
             textAlign: w.textAlign,
             maxLines: w.maxLines,
             minLines: w.minLines,
             maxLength: w.maxLength,
             obscureText: w.obscureText,
             autocorrect: w.autocorrect,
             enableSuggestions: w.enableSuggestions,
             autofocus: w.autofocus,
             enabled: w.enabled,
             readOnly: w.readOnly,
             onChanged: w.onChanged,
             onSubmitted: w.onFieldSubmitted,
             onTap: w.onTap,
             inputFormatters: w.inputFormatters,
           );
           return Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               input,
               if (platform.PlatformInfo.isIOS && field.errorText != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 6, left: 12),
                   child: Text(
                     field.errorText!,
                     style: TextStyle(
                       color: Theme.of(field.context).colorScheme.error,
                     ),
                   ),
                 ),
             ],
           );
         },
       );
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines, minLines, maxLength;
  final bool obscureText, autocorrect, enableSuggestions, autofocus, readOnly;
  final ValueChanged<String>? onChanged, onFieldSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TapRegionCallback? onTapOutside;
  final List<String>? autofillHints;
  @override
  FormFieldState<String> createState() => _AdaptiveTextFormFieldState();
}

class _AdaptiveTextFormFieldState extends FormFieldState<String> {
  AdaptiveTextFormField get config => widget as AdaptiveTextFormField;
  TextEditingController? _local;
  TextEditingController get controller => config.controller ?? _local!;
  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    if (config.controller == null) {
      _local ??= TextEditingController(text: value);
    }
    controller.addListener(_sync);
  }

  void _sync() {
    if (controller.text != value) didChange(controller.text);
  }

  @override
  void didUpdateWidget(covariant AdaptiveTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != config.controller) {
      final previous = oldWidget.controller ?? _local!;
      previous.removeListener(_sync);
      if (config.controller == null) {
        final oldValue = previous.value;
        _local?.dispose();
        _local = TextEditingController.fromValue(oldValue);
      } else if (_local != null) {
        _local!.dispose();
        _local = null;
      }
      _attach();
      setValue(controller.text);
    }
  }

  @override
  void reset() {
    controller.text = config.initialValue ?? '';
    super.reset();
    config.onChanged?.call(controller.text);
  }

  @override
  void dispose() {
    controller.removeListener(_sync);
    _local?.dispose();
    super.dispose();
  }
}
