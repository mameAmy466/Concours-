import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../models/models.dart';
import '../state/contest_controller.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _qualify;
  late final TextEditingController _apiUrl;
  late List<TextEditingController> _criteriaNames;
  late bool _combine;
  bool _ready = false;
  bool _testingApi = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final contest = ContestScope.of(context);
    _name = TextEditingController(text: contest.name);
    _qualify = TextEditingController(text: '${contest.qualifyCount}');
    _apiUrl = TextEditingController(text: contest.apiBaseUrl);
    _combine = contest.combineRounds;
    _criteriaNames = [
      for (final c in contest.criteria) TextEditingController(text: c.name),
    ];
    _ready = true;
  }

  @override
  void dispose() {
    if (_ready) {
      _name.dispose();
      _qualify.dispose();
      _apiUrl.dispose();
      for (final c in _criteriaNames) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    final contest = ContestScope.of(context);
    final qualify = int.tryParse(_qualify.text.trim()) ?? contest.qualifyCount;
    final nextCriteria = <Criterion>[];
    for (var i = 0; i < contest.criteria.length; i++) {
      final current = contest.criteria[i];
      nextCriteria.add(
        Criterion(
          id: current.id,
          name: _criteriaNames[i].text.trim().isEmpty
              ? current.name
              : _criteriaNames[i].text.trim(),
          maxScore: current.maxScore,
        ),
      );
    }
    try {
      await contest.updateSettings(
        contestName: _name.text,
        qualify: qualify,
        combine: _combine,
        nextCriteria: nextCriteria,
      );
      if (mounted) showInfo(context, 'Réglages enregistrés');
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contest = ContestScope.of(context);
    final locked = contest.phase != ContestPhase.setup &&
        contest.scores.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionTitle('Concours'),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom du concours'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qualify,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nombre de finalistes (Tour 2)',
              helperText: 'Les mieux notés du Tour 1 passent en finale.',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Classement final = Tour 1 + Tour 2'),
            subtitle: const Text(
              'Sinon, seul le Tour 2 compte pour le classement final.',
            ),
            value: _combine,
            onChanged: (v) => setState(() => _combine = v),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Critères de notation', small: true),
          if (locked)
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 8),
              child: Text(
                'Les critères restent éditables en nom, mais le barème est figé une fois les notes commencées.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 8),
          for (final controller in _criteriaNames) ...[
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Critère'),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton(onPressed: _save, child: const Text('Enregistrer')),
          const SizedBox(height: 28),
          const SectionTitle('Serveur / API', small: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: contest.apiConnected
                  ? AppColors.goldSoft.withValues(alpha: 0.45)
                  : AppColors.sand.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              contest.apiConnected
                  ? 'Connecté — les données sont partagées.'
                  : 'Hors ligne — les données restent sur cet appareil.',
              style: TextStyle(
                color: contest.apiConnected ? AppColors.navy : AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL de l’API',
              hintText: 'http://127.0.0.1:8000',
              helperText:
                  'Téléphone : IP du Mac (ex. http://192.168.x.x:8000). Émulateur : http://10.0.2.2:8000.',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _testingApi
                      ? null
                      : () async {
                          setState(() => _testingApi = true);
                          final contest = ContestScope.of(context);
                          await contest.setApiBaseUrl(_apiUrl.text);
                          final ok = await contest.testApiConnection();
                          if (!context.mounted) return;
                          setState(() => _testingApi = false);
                          showInfo(
                            context,
                            ok
                                ? 'Connexion API réussie'
                                : 'Serveur injoignable',
                          );
                        },
                  child: Text(_testingApi ? 'Test…' : 'Tester'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await ContestScope.of(context).setApiBaseUrl(_apiUrl.text);
                    if (context.mounted) {
                      showInfo(context, 'URL du serveur enregistrée');
                    }
                  },
                  child: const Text('Enregistrer l’URL'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Nouveau concours ?',
                message:
                    'Toutes les données (candidats, notes, résultats) seront effacées.',
                confirmLabel: 'Tout effacer',
              );
              if (ok && context.mounted) {
                await ContestScope.of(context).resetContest();
                if (context.mounted) {
                  showInfo(context, 'Concours réinitialisé');
                }
              }
            },
            child: const Text('Réinitialiser le concours'),
          ),
        ],
      ),
    );
  }
}
