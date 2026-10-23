import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Paleta ya rangi zinazoendana na bluu ya Sayuni.
/// Rangi zote husomeka vizuri kwenye mandhari nyeupe.
abstract class ModuleAccents {
  static const List<Color> palette = <Color>[
    Color(0xFF0D52CD), // Buluu ya Sayuni
    Color(0xFF0284C7), // Sky deep
    Color(0xFF0E9E8F), // Teal
    Color(0xFF7C3AED), // Violet
    Color(0xFF16A34A), // Green
    Color(0xFFDB2777), // Rose
  ];

  static Color at(int index) => palette[index % palette.length];
}

/// Takwimu ndogo (pill) inayowekwa chini ya banner.
class ModuleBannerStat {
  const ModuleBannerStat(this.value, this.label);
  final String value;
  final String label;
}

/// Banner ya juu ya skrini za ndani: kichwa, maelezo, icon ya 3D na takwimu.
class ModuleBanner extends StatelessWidget {
  const ModuleBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    this.gradient = const <Color>[Color(0xFF0D52CD), Color(0xFF0A2540)],
    this.stats = const <ModuleBannerStat>[],
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String imageAsset;
  final List<Color> gradient;
  final List<ModuleBannerStat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 13, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gradient.first.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 9),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      eyebrow.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 9,
                        letterSpacing: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.5,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.84),
                        fontSize: 11.5,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (BuildContext c, Object e, StackTrace? s) => const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          if (stats.isNotEmpty) ...<Widget>[
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.map((ModuleBannerStat s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.24)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        s.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        s.label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kichwa cha sehemu ndani ya skrini (eyebrow + mstari wa rangi).
class ModuleSectionLabel extends StatelessWidget {
  const ModuleSectionLabel({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.trailing,
  });

  final String label;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              letterSpacing: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
