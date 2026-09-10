import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/contest_controller.dart';
import '../widgets/widgets.dart';

class CandidateFormScreen extends StatefulWidget {
  const CandidateFormScreen({
    super.key,
    this.candidate,
    this.embedded = false,
  });

  final Candidate? candidate;
  final bool embedded;

  @override
  State<CandidateFormScreen> createState() => _CandidateFormScreenState();
}

class _CandidateFormScreenState extends State<CandidateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _city;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final c = widget.candidate;
    _number = TextEditingController(text: c?.number ?? '');
    _firstName = TextEditingController(text: c?.firstName ?? '');
    _lastName = TextEditingController(text: c?.lastName ?? '');
    _city = TextEditingController(text: c?.city ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _number.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _city.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final contest = ContestScope.of(context);
    final existing = widget.candidate;
    await contest.upsertCandidate(
      Candidate(
        id: existing?.id ?? newId(),
        number: _number.text.trim(),
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        city: _city.text.trim(),
        notes: _notes.text.trim(),
        qualified: existing?.qualified ?? false,
      ),
    );
    if (!mounted) return;
    showInfo(context, existing == null ? 'Candidat enregistré' : 'Candidat mis à jour');
    if (!widget.embedded) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final contest = ContestScope.of(context);
    final canEdit = contest.phase.canEditCandidates;
    final form = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.candidate == null ? 'Nouveau candidat' : 'Fiche candidat',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _number,
            enabled: canEdit,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Numéro / dossard',
              prefixIcon: Icon(Icons.tag),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Numéro obligatoire' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _firstName,
            enabled: canEdit,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Prénom'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Prénom obligatoire' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastName,
            enabled: canEdit,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _city,
            enabled: canEdit,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Ville / catégorie (optionnel)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            enabled: canEdit,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes du jury'),
          ),
          const SizedBox(height: 20),
          if (canEdit)
            FilledButton(
              onPressed: _save,
              child: Text(widget.candidate == null ? 'Enregistrer' : 'Mettre à jour'),
            ),
        ],
      ),
    );

    if (widget.embedded) return form;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.candidate == null ? 'Nouveau candidat' : 'Candidat'),
      ),
      body: form,
    );
  }
}
