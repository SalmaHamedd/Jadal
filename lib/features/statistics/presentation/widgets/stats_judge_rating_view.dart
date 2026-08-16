import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/judge_rating_model.dart';
import 'stats_theme.dart';

/// The judge's average rating received.
/// Aggregates only: the payload carries no rater ids, names or comments, and
/// nothing here can identify who rated what.
class StatsJudgeRatingView extends StatelessWidget {
  final JudgeRatingStat data;
  const StatsJudgeRatingView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    if (!data.hasRatings) {
      return _Empty(
        message: data.reason == 'no_ratings_received'
            ? loc.statsRatingEmptyNoRatings
            : loc.statsRatingEmptyNeverJudged,
      );
    }

    final avg = data.avgRating!;
    final delta = data.peerDelta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: avg),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              v.toStringAsFixed(2),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                fontSize: 44,
                color: JadalColors.primaryOrange,
              ),
            ),
          ),
        ),
        // Stars are rendered from `rating_scale`, never a hardcoded 5 — the
        // backend publishes the scale precisely so a future 1–10 move needs no
        // app release.
        Center(child: _Stars(value: avg, min: data.scaleMin, max: data.scaleMax)),
        const SizedBox(height: 4),
        Center(
          child: Text(
            loc.statsRatingsCount(data.ratingsCount),
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: StatsTheme.textSecondary(context)),
          ),
        ),
        if (data.isLowSample) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              loc.statsRatingTooFew,
              style: AppTextStyles.small(context).copyWith(
                fontStyle: FontStyle.italic,
                color: JadalColors.primaryOrange,
              ),
            ),
          ),
        ],
        if (delta != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  // Arrow + sign, not colour alone.
                  signedWithArrow(delta, decimals: 2),
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: delta >= 0
                        ? JadalColors.positiveGreen
                        : JadalColors.negativeRed,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  loc.statsPeerAverage(data.peerAverage!.toStringAsFixed(2)),
                  style: AppTextStyles.small(
                    context,
                  ).copyWith(color: StatsTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
        ],
        if (data.debatesJudged > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              loc.statsRatingCoverage(data.debatesRated, data.debatesJudged),
              textAlign: TextAlign.center,
              style: AppTextStyles.small(
                context,
              ).copyWith(color: StatsTheme.textSecondary(context)),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          loc.statsRatingDistribution,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w800,
            color: StatsTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 10),
        _Distribution(data: data),
        // The trend only means anything with more than one populated period.
        if (data.buckets.length >= 2) ...[
          const SizedBox(height: 20),
          Text(
            loc.statsRatingTrend,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w800,
              color: StatsTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 10),
          for (final b in data.buckets) _BucketRow(bucket: b, data: data),
        ],
      ],
    );
  }
}

/// Star row sized from the payload's scale.
class _Stars extends StatelessWidget {
  final double value;
  final int min;
  final int max;
  const _Stars({required this.value, required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    final count = (max - min + 1).clamp(1, 10);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Star `i` (0-based) stands for the rating value `min + i`, so it is
        // full once the average reaches that value.
        // The thresholds used to be offset by +0.75/+0.25, which meant a
        // perfect 5.0 on a 1–5 scale needed 5.75 to light the last star — so
        // top marks rendered as four stars. Comparing against the star's own
        // value fixes both ends: 1.0 lights exactly one, 5.0 lights all five.
        for (var i = 0; i < count; i++)
          Icon(
            value >= min + i
                ? Icons.star_rounded
                : value >= min + i - 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: 20,
            color: JadalColors.primaryOrange,
          ),
      ],
    );
  }
}

/// A fixed histogram — the payload always includes every point on the scale,
/// zeros included, so no gap-filling is needed here.
class _Distribution extends StatelessWidget {
  final JudgeRatingStat data;
  const _Distribution({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxCount = data.maxDistributionCount;
    return Column(
      children: [
        for (var v = data.scaleMax; v >= data.scaleMin; v--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Row(
                    children: [
                      Text(
                        '$v',
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: StatsTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: JadalColors.primaryOrange,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: maxCount == 0
                          ? 0
                          : (data.distribution[v] ?? 0) / maxCount,
                      minHeight: 10,
                      backgroundColor: StatsTheme.textSecondary(
                        context,
                      ).withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(
                        JadalColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${data.distribution[v] ?? 0}',
                    textAlign: TextAlign.end,
                    style: AppTextStyles.small(
                      context,
                    ).copyWith(color: StatsTheme.textSecondary(context)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BucketRow extends StatelessWidget {
  final JudgeRatingBucket bucket;
  final JudgeRatingStat data;
  const _BucketRow({required this.bucket, required this.data});

  @override
  Widget build(BuildContext context) {
    final avg = bucket.avgRating;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              bucket.label,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w700,
                color: StatsTheme.textPrimary(context),
              ),
            ),
          ),
          Text(
            // A quiet month is `null`, not 0 — "nobody rated me" is not
            // "everybody rated me zero", so it renders as a dash.
            avg == null
                ? '—'
                : '${avg.toStringAsFixed(2)}  ·  ${context.loc.statsRatingsCount(bucket.ratingsCount)}',
            style: AppTextStyles.small(context).copyWith(
              fontWeight: FontWeight.w700,
              color: avg == null
                  ? StatsTheme.textSecondary(context)
                  : StatsTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Icon(
            Icons.star_outline_rounded,
            size: 48,
            color: JadalColors.judgesGrey,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              context,
            ).copyWith(color: StatsTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }
}
