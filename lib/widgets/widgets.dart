import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme.dart';

String formatScore(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

class NumberBadge extends StatelessWidget {
  const NumberBadge({super.key, required this.number, this.large = false});

  final String number;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 60.0 : 46.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3F4E47), AppColors.navy],
        ),
        borderRadius: BorderRadius.circular(large ? 18 : 14),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        number.isEmpty ? '—' : number,
        style: outfit(
          color: AppColors.goldSoft,
          fontWeight: FontWeight.w700,
          fontSize: large ? 20 : 16,
        ),
      ),
    );
  }
}

class PhaseChip extends StatelessWidget {
  const PhaseChip({super.key, required this.phase});

  final ContestPhase phase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        phase.label,
        style: outfit(
          color: AppColors.navyDark,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.small = false});

  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: small
          ? Theme.of(context).textTheme.titleLarge
          : Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.icon,
  });

  final String label;
  final String value;
  final String? hint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sand),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.navy),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: outfit(
                    color: AppColors.muted,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: displaySerif(
              color: AppColors.navy,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint!,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.goldSoft.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.navy),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class CandidateTile extends StatelessWidget {
  const CandidateTile({
    super.key,
    required this.candidate,
    this.trailing,
    this.subtitle,
    this.selected = false,
    this.onTap,
  });

  final Candidate candidate;
  final Widget? trailing;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8EFE4) : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.gold : AppColors.sand,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected ? AppShadows.soft : null,
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: NumberBadge(number: candidate.number),
        title: Text(
          candidate.fullName,
          style: outfit(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          [
            if (candidate.city.isNotEmpty) candidate.city,
            if (subtitle != null) subtitle,
          ].join(' · '),
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        trailing: trailing,
      ),
    );
  }
}

class ScorePanel extends StatefulWidget {
  const ScorePanel({
    super.key,
    required this.candidate,
    required this.round,
    required this.criteria,
    required this.initial,
    required this.readOnly,
    required this.onSave,
  });

  final Candidate candidate;
  final int round;
  final List<Criterion> criteria;
  final Map<String, double> initial;
  final bool readOnly;
  final Future<void> Function(Map<String, double> values) onSave;

  @override
  State<ScorePanel> createState() => _ScorePanelState();
}

class _ScorePanelState extends State<ScorePanel> {
  late Map<String, double> _values;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _values = {
      for (final c in widget.criteria)
        c.id: widget.initial[c.id] ?? (c.maxScore / 2),
    };
  }

  @override
  void didUpdateWidget(covariant ScorePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidate.id != widget.candidate.id ||
        oldWidget.round != widget.round) {
      _values = {
        for (final c in widget.criteria)
          c.id: widget.initial[c.id] ?? (c.maxScore / 2),
      };
    }
  }

  double get _total =>
      widget.criteria.fold(0, (sum, c) => sum + (_values[c.id] ?? 0));

  double get _max =>
      widget.criteria.fold(0, (sum, c) => sum + c.maxScore);

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_values);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy, Color(0xFF4F6355)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              NumberBadge(number: widget.candidate.number, large: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.candidate.fullName,
                      style: displaySerif(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cream,
                      ),
                    ),
                    Text(
                      'Tour ${widget.round}${widget.candidate.city.isNotEmpty ? ' · ${widget.candidate.city}' : ''}',
                      style: outfit(
                        color: AppColors.goldSoft,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatScore(_total),
                    style: displaySerif(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cream,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/ ${formatScore(_max)}',
                    style: outfit(
                      color: AppColors.goldSoft,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              for (final criterion in widget.criteria)
                _CriterionSlider(
                  criterion: criterion,
                  value: _values[criterion.id] ?? 0,
                  enabled: !widget.readOnly,
                  onChanged: (v) => setState(() => _values[criterion.id] = v),
                ),
              const SizedBox(height: 12),
              if (!widget.readOnly)
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Enregistrement…' : 'Enregistrer la note'),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'La notation est verrouillée pour cette étape.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CriterionSlider extends StatelessWidget {
  const _CriterionSlider({
    required this.criterion,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final Criterion criterion;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  criterion.name,
                  style: outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${formatScore(value)} / ${formatScore(criterion.maxScore)}',
                  style: outfit(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(0, criterion.maxScore),
            min: 0,
            max: criterion.maxScore,
            divisions: (criterion.maxScore * 2).round(),
            label: formatScore(value),
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class RankingList extends StatelessWidget {
  const RankingList({
    super.key,
    required this.rows,
    this.showQualify = false,
  });

  final List<RankedRow> rows;
  final bool showQualify;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Pas encore de classement',
        message: 'Les notes apparaîtront ici dès qu’un candidat sera noté.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = rows[index];
        final podium = row.rank <= 3;
        return Container(
          decoration: BoxDecoration(
            color: row.rank == 1
                ? const Color(0xFFE8EFE4)
                : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: row.rank == 1 ? AppColors.gold : AppColors.sand,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: podium ? AppColors.gold : AppColors.navy,
              foregroundColor: AppColors.cream,
              child: Text(
                '${row.rank}',
                style: outfit(fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(
              row.candidate.fullName,
              style: outfit(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                'N° ${row.candidate.number}',
                if (!row.complete) 'Note incomplète',
                if (showQualify && row.qualified) 'Qualifié Tour 2',
              ].join(' · '),
            ),
            trailing: Text(
              row.complete ? formatScore(row.total) : '—',
              style: displaySerif(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> copyRanking(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Classement copié')),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.danger),
  );
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
