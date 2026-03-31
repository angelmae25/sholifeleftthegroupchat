// FILE PATH: lib/widgets/lost_found_item_card.dart
//
// FIX: Image now renders from imageUrl when available.
//      Falls back to the question-mark placeholder only when imageUrl is null/empty.

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class LostFoundItemCard extends StatelessWidget {
  final LostFoundModel item;
  final VoidCallback? onContactOwner;

  const LostFoundItemCard({
    super.key,
    required this.item,
    this.onContactOwner,
  });

  @override
  Widget build(BuildContext context) {
    final isLost      = item.status == LostFoundStatus.lost;
    final statusColor = isLost ? const Color(0xFFB71C1C) : const Color(0xFF2E7D32);
    final statusLabel = isLost ? 'LOST' : 'FOUND';
    final cardClr     = AppTheme.cardColor(context);
    final textMain    = AppTheme.textMain(context);
    final textSub     = AppTheme.textSub(context);
    final borderClr   = AppTheme.borderCol(context);

    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardClr,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ────────────────────────────────────────────────────
            _ItemThumbnail(
              imageUrl:    item.imageUrl,
              hasImage:    hasImage,
              statusColor: statusColor,
            ),
            const SizedBox(width: 14),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: textMain,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Description (optional preview)
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(color: textSub, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Location + date row
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: textSub),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(color: textSub, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: textSub),
                      const SizedBox(width: 3),
                      Text(
                        '${item.date.month}/${item.date.day}',
                        style: TextStyle(color: textSub, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Contact Owner button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onContactOwner,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: statusColor,
                        side: BorderSide(color: statusColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.chat_bubble_outline,
                          size: 16, color: statusColor),
                      label: Text(
                        'Contact Owner',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Thumbnail widget ──────────────────────────────────────────────────────────
class _ItemThumbnail extends StatelessWidget {
  final String? imageUrl;
  final bool    hasImage;
  final Color   statusColor;

  const _ItemThumbnail({
    required this.imageUrl,
    required this.hasImage,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    const size = 80.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: hasImage
            ? Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          // Show a shimmer-style placeholder while loading
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: statusColor.withValues(alpha: 0.08),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                      : null,
                  color: statusColor,
                ),
              ),
            );
          },
          // Fall back to placeholder if image fails to load
          errorBuilder: (_, __, ___) =>
              _Placeholder(statusColor: statusColor),
        )
            : _Placeholder(statusColor: statusColor),
      ),
    );
  }
}

// ── Placeholder (question mark icon) ─────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final Color statusColor;
  const _Placeholder({required this.statusColor});

  @override
  Widget build(BuildContext context) => Container(
    color: statusColor.withValues(alpha: 0.08),
    child: Icon(
      Icons.help_outline_rounded,
      size: 36,
      color: statusColor.withValues(alpha: 0.5),
    ),
  );
}