import 'package:flutter/material.dart';

import '../../domain/stop.dart';

class StopFormValue {
  const StopFormValue({required this.label});
  final String label;
}

class StopForm extends StatefulWidget {
  const StopForm({
    super.key,
    this.initial,
    this.submitLabel = 'Adicionar parada',
    required this.onSubmit,
  });

  final Stop? initial;
  final String submitLabel;
  final void Function(StopFormValue value) onSubmit;

  @override
  State<StopForm> createState() => _StopFormState();
}

class _StopFormState extends State<StopForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.initial?.label ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      StopFormValue(label: _addressController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('input-address'),
            controller: _addressController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Endereço',
              hintText: 'Digite o endereço ou CEP...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Informe o endereço';
              return null;
            },
          ),
          const SizedBox(height: 24),
          Semantics(
            button: true,
            label: widget.submitLabel,
            child: FilledButton(
              onPressed: _submit,
              child: Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}
