import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter/material.dart';

class TitleHeader extends StatelessWidget {
  const TitleHeader({
    required this.title,
    super.key,
    this.onSeeAll,
    this.enableShowAll,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final bool? enableShowAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 28,
        bottom: 14,
        start: 18,
        end: 18,
      ),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Container(
            width: 4,
            height: 24,
            margin: const EdgeInsetsDirectional.only(end: 10),
            decoration: BoxDecoration(
              color: context.color.tertiaryColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Expanded(
            child: CustomText(
              title,
              fontWeight: .w700,
              fontSize: context.font.lg,
              color: context.color.textColorDark,
              maxLines: 2,
            ),
          ),
          if (enableShowAll ?? true)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                margin: EdgeInsetsDirectional.only(start: 8.rw(context)),
                padding: const EdgeInsetsDirectional.fromSTEB(12, 7, 9, 7),
                decoration: BoxDecoration(
                  color: context.color.tertiaryColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      'seeAll'.translate(context),
                      fontWeight: .w600,
                      fontSize: context.font.xs,
                      color: context.color.tertiaryColor,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: 16,
                      color: context.color.tertiaryColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
