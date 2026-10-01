import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';

/// The facts a place reported, one row each, with how it decided.
///
/// Facts in [needed] that the place lacks are marked, so a page can show
/// at a glance what stops it.
class FactsView extends StatelessWidget {
  const FactsView({super.key, required this.facts, this.needed = const {}});

  final Facts facts;
  final Set<String> needed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in Fact.all)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  facts.has(f)
                      ? Icons.check_circle
                      : Icons.remove_circle_outline,
                  size: 16,
                  color: facts.has(f)
                      ? scheme.primary
                      : needed.contains(f)
                      ? scheme.error
                      : scheme.outline,
                ),
                const SizedBox(width: 8),
                SizedBox(width: 112, child: Text(f)),
                Expanded(
                  child: Text(
                    facts.masked.contains(f)
                        ? 'switched off on this page'
                        : facts.notes[f] ?? 'not reported',
                    style: small,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A titled card used by every page.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.titleMedium),
            if (subtitle != null) Text(subtitle!, style: t.bodySmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// The fallback a page takes, in the UI rather than only in a comment.
class Fallback extends StatelessWidget {
  const Fallback(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
