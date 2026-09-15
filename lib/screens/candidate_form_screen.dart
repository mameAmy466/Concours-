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
  late final TextEditingController _age;
  late final TextEditingController _birthPlace;
  late final TextEditingController _residence;
  late final TextEditingController _region;
  late final TextEditingController _residenceYears;
  late final TextEditingController _profession;
  late final TextEditingController _experienceYears;
  late final TextEditingController _hafizSince;
  late final TextEditingController _riwaayat;
  late final TextEditingController _daara;
  late final TextEditingController _contact;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final c = widget.candidate;
    _number = TextEditingController(text: c?.number ?? '');
    _firstName = TextEditingController(text: c?.firstName ?? '');
    _lastName = TextEditingController(text: c?.lastName ?? '');
    _age = TextEditingController(text: c?.age?.toString() ?? '');
    _birthPlace = TextEditingController(text: c?.birthPlace ?? '');
    _residence = TextEditingController(text: c?.residence ?? '');
    _region = TextEditingController(text: c?.region ?? '');
    _residenceYears =
        TextEditingController(text: c?.residenceYears?.toString() ?? '');
    _profession = TextEditingController(text: c?.profession ?? '');
    _experienceYears =
        TextEditingController(text: c?.experienceYears?.toString() ?? '');
    _hafizSince = TextEditingController(text: c?.hafizSince ?? '');
    _riwaayat = TextEditingController(text: c?.riwaayat ?? '');
    _daara = TextEditingController(text: c?.daara ?? '');
    _contact = TextEditingController(text: c?.contact ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _number.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _age.dispose();
    _birthPlace.dispose();
    _residence.dispose();
    _region.dispose();
    _residenceYears.dispose();
    _profession.dispose();
    _experienceYears.dispose();
    _hafizSince.dispose();
    _riwaayat.dispose();
    _daara.dispose();
    _contact.dispose();
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
        age: int.tryParse(_age.text.trim()),
        birthPlace: _birthPlace.text.trim(),
        residence: _residence.text.trim(),
        region: _region.text.trim(),
        residenceYears: int.tryParse(_residenceYears.text.trim()),
        profession: _profession.text.trim(),
        experienceYears: int.tryParse(_experienceYears.text.trim()),
        hafizSince: _hafizSince.text.trim(),
        riwaayat: _riwaayat.text.trim(),
        daara: _daara.text.trim(),
        contact: _contact.text.trim(),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _age,
                  enabled: canEdit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Âge'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _birthPlace,
                  enabled: canEdit,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: 'Lieu de naissance'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _residence,
            enabled: canEdit,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Lieu de résidence'),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _region,
                  enabled: canEdit,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Région',
                    helperText: 'Détermine le groupe de qualification.',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _residenceYears,
                  enabled: canEdit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ancienneté dans la région (années)',
                    helperText: 'Utile en cas d’égalité de notes.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _profession,
            enabled: canEdit,
            decoration: const InputDecoration(labelText: 'Métier'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _experienceYears,
            enabled: canEdit,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Expérience (années)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _hafizSince,
            enabled: canEdit,
            decoration: const InputDecoration(labelText: 'Xaafiz depuis'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _riwaayat,
            enabled: canEdit,
            decoration: const InputDecoration(labelText: 'Riwaayat'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _daara,
            enabled: canEdit,
            decoration:
                const InputDecoration(labelText: 'Ressortissant du Daara'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contact,
            enabled: canEdit,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact'),
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
