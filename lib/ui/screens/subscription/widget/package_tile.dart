import 'package:dio/dio.dart';
import 'package:ebroker/data/cubits/payment/payment_intent_cubit.dart';
import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/data/repositories/subscription_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/payment/in_app_purchase/in_app_purchase_manager.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:flutter/material.dart';

class SubscriptionPackageTile extends StatefulWidget {
  const SubscriptionPackageTile({
    required this.onTap,
    required this.package,
    required this.packageFeatures,
    super.key,
  });

  final SubscriptionPackageModel package;
  final List<AllFeature> packageFeatures;
  final VoidCallback onTap;

  @override
  State<SubscriptionPackageTile> createState() =>
      _SubscriptionPackageTileState();
}

class _SubscriptionPackageTileState extends State<SubscriptionPackageTile> {
  InAppPurchaseManager inAppPurchase = InAppPurchaseManager();
  MultipartFile? _bankReceiptFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.color.brightness == Brightness.dark;
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(
        16.rw(context),
        8.rh(context),
        16.rw(context),
        18.rh(context),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            context.color.secondaryColor,
            context.color.secondaryColor.withValues(alpha: isDark ? 0.82 : 0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(26.rw(context)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : context.color.borderColor.withValues(alpha: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: context.color.tertiaryColor.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          buildPackageTitle(),
          Container(
            padding: EdgeInsets.fromLTRB(
              20.rw(context),
              18.rh(context),
              20.rw(context),
              20.rh(context),
            ),
            child: Column(
              children: [
                packageFeaturesAndValidity(),
                buildSeparator(),
                buildPriceAndSubscribe(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPriceAndSubscribe() {
    final packageDuration = HelperUtils.getPackageDuration(
      duration: widget.package.duration,
    );
    final isUnderReview = widget.package.packageStatus == 'review';
    final isRejected = widget.package.packageStatus == 'rejected';
    return Column(
      children: [
        if (isUnderReview) ...[
          Row(
            mainAxisAlignment: .center,
            children: [
              Icon(
                Icons.access_time,
                size: 18.rh(context),
                color: Colors.orangeAccent,
              ),
              SizedBox(width: 4.rw(context)),
              Flexible(
                child: CustomText(
                  'adminVerificationPending'.translate(context),
                  fontSize: context.font.sm,
                  color: Colors.orangeAccent,
                  fontWeight: .w500,
                  maxLines: 2,
                  textAlign: .center,
                ),
              ),
            ],
          ),
        ],
        Container(
          padding: EdgeInsets.all(16.rw(context)),
          margin: EdgeInsets.only(top: 6.rh(context)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                context.color.tertiaryColor.withValues(alpha: 0.12),
                context.color.tertiaryColor.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(20.rw(context)),
            border: Border.all(
              color: context.color.tertiaryColor.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomText(
                      widget.package.price == 0
                          ? 'free'.translate(context)
                          : widget.package.price.toString().priceFormat(
                              context: context,
                            ),
                      fontSize: context.font.xl,
                      color: context.color.textColorDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.rw(context),
                      vertical: 6.rh(context),
                    ),
                    decoration: BoxDecoration(
                      color: context.color.secondaryColor.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: CustomText(
                      '$packageDuration ${packageDuration == '1' ? 'day'.translate(context) : 'days'.translate(context)}',
                      fontSize: context.font.xs,
                      color: context.color.textColorDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.rh(context)),
              if (isUnderReview)
                UiUtils.buildButton(
                  context,
                  height: 46.rh(context),
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      Routes.transactionHistory,
                    );
                  },
                  buttonTitle: 'view'.translate(context),
                )
              else if (isRejected)
                buildUploadReceiptButton(
                  transactionId: widget.package.paymentTransactionId ?? '',
                )
              else
                BlocBuilder<PaymentIntentCubit, PaymentIntentState>(
                  builder: (context, state) {
                    final isLoading = state is PaymentIntentInProgress;
                    return SizedBox(
                      height: 48.rh(context),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : widget.onTap,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: context.color.tertiaryColor,
                          foregroundColor: context.color.buttonColor,
                          disabledBackgroundColor: context.color.tertiaryColor
                              .withValues(alpha: 0.55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.rw(context)),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox.square(
                                dimension: 20.rw(context),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: context.color.buttonColor,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomText(
                                    'subscribe'.translate(context),
                                    fontSize: context.font.sm,
                                    fontWeight: FontWeight.w700,
                                    color: context.color.buttonColor,
                                  ),
                                  SizedBox(width: 8.rw(context)),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 19.rw(context),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSeparator() {
    return Container(
      margin: EdgeInsets.only(top: 18.rh(context), bottom: 18.rh(context)),
      child: MySeparator(
        color: context.color.borderColor.withValues(alpha: 0.7),
        dashWidth: 5,
      ),
    );
  }

  Widget buildPackageTitle() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.rw(context),
        20.rh(context),
        20.rw(context),
        18.rh(context),
      ),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            context.color.tertiaryColor,
            context.color.tertiaryColor.withValues(alpha: 0.76),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44.rw(context),
            height: 44.rh(context),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14.rw(context)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: context.color.buttonColor,
              size: 24.rw(context),
            ),
          ),
          SizedBox(width: 14.rw(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  widget.package.translatedName ?? widget.package.name,
                  fontSize: context.font.lg,
                  color: context.color.buttonColor,
                  fontWeight: FontWeight.w800,
                  maxLines: 2,
                ),
                SizedBox(height: 3.rh(context)),
                CustomText(
                  'subscriptionPlan'.translate(context),
                  fontSize: context.font.xs,
                  color: context.color.buttonColor.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget packageFeaturesAndValidity() {
    return Column(
      children: [
        buildValidity(
          duration: widget.package.duration.toString(),
        ),
        SizedBox(height: 18.rh(context)),
        buildPackageFeatures(
          packageFeatures: widget.packageFeatures,
          package: widget.package,
        ),
      ],
    );
  }

  Widget buildValidity({required String duration}) {
    final packageDuration = HelperUtils.getPackageDuration(
      duration: int.parse(duration),
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.rw(context),
        vertical: 10.rh(context),
      ),
      decoration: BoxDecoration(
        color: context.color.tertiaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.rw(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 19.rw(context),
            color: context.color.tertiaryColor,
          ),
          SizedBox(width: 9.rw(context)),
          Expanded(
            child: CustomText(
              '${'validUntil'.translate(context)} $packageDuration ${packageDuration == '1' ? 'day'.translate(context) : 'days'.translate(context)}',
              fontSize: context.font.xs,
              color: context.color.textColorDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPackageFeatures({
    required List<AllFeature> packageFeatures,
    required SubscriptionPackageModel package,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (context, index) {
        return SizedBox(height: 18.rh(context));
      },
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packageFeatures.length,
      itemBuilder: (context, index) {
        final allFeatures = packageFeatures[index];
        final includedFeatures = package.features
            .where((element) => element.id == allFeatures.id)
            .toList();
        // Check if we have matching features before accessing
        var getLimit = '';
        if (includedFeatures.isNotEmpty) {
          if (includedFeatures[0].limit?.toString() != '0') {
            getLimit =
                includedFeatures[0].limit?.toString() ??
                includedFeatures[0].limitType.toString();
          } else {
            getLimit = includedFeatures[0].limitType.name.translate(context);
          }
        }

        final isIncluded = package.features.any(
          (element) => element.id == allFeatures.id,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24.rw(context),
              height: 24.rh(context),
              decoration: BoxDecoration(
                color: (isIncluded
                        ? context.color.tertiaryColor
                        : context.color.textLightColor)
                    .withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncluded ? Icons.check_rounded : Icons.remove_rounded,
                size: 16.rw(context),
                color: isIncluded
                    ? context.color.tertiaryColor
                    : context.color.textLightColor,
              ),
            ),
            SizedBox(width: 10.rw(context)),
            Expanded(
              child: CustomText(
                '${allFeatures.translatedName ?? allFeatures.name} ${getLimit != '' ? ': ${getLimit.firstUpperCase()}' : ''}',
                fontSize: context.font.xs,
                color: isIncluded
                    ? context.color.textColorDark
                    : context.color.textLightColor,
                fontWeight: isIncluded ? FontWeight.w600 : FontWeight.w500,
                maxLines: 3,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildUploadReceiptButton({
    required String transactionId,
  }) {
    return Flexible(
      child: UiUtils.buildButton(
        context,
        height: 32.rh(context),
        autoWidth: true,
        onPressed: () async {
          final file = await AppFilePicker.pickFile(
            allowedExtensions: [
              'jpeg',
              'png',
              'jpg',
              'pdf',
              'doc',
              'docx',
              'webp',
            ],
          );
          if (file != null) {
            _bankReceiptFile = await MultipartFile.fromFile(
              file.path!,
              filename: file.path!.split('/').last,
            );
          }
          if (_bankReceiptFile == null) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleaseUploadReceipt',
              type: .error,
            );
            return;
          }
          try {
            final result = await SubscriptionRepository().uploadBankReceiptFile(
              paymentTransactionId: transactionId,
              file: _bankReceiptFile!,
            );
            if (result['error'] == false) {
              HelperUtils.showSnackBarMessage(
                context,
                'receiptUploaded',
                type: .success,
              );
              await context
                  .read<FetchSubscriptionPackagesCubit>()
                  .fetchPackages();
            } else {
              HelperUtils.showSnackBarMessage(
                context,
                result['message'].toString(),
                type: .error,
              );
            }
          } on Exception catch (e) {
            HelperUtils.showSnackBarMessage(
              context,
              e.toString(),
              type: .error,
            );
          }
        },
        buttonTitle: 'reUploadReceipt'.translate(context),
      ),
    );
  }
}

class MySeparator extends StatelessWidget {
  const MySeparator({
    super.key,
    this.height = 1,
    this.color = Colors.grey,
    this.isShimmer = false,
    this.dashWidth = 10.0,
  });
  final double height;
  final Color color;
  final bool isShimmer;
  final double dashWidth;

  @override
  Widget build(BuildContext context) {
    if (isShimmer) {
      return SizedBox(
        height: height,
        child: CustomPaint(
          size: const Size(double.infinity, 0),
          painter: _DashLinePainter(
            color: Colors.grey.withValues(alpha: 0.3),
            dashWidth: dashWidth,
            dashHeight: height,
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: const Size(double.infinity, 0),
        painter: _DashLinePainter(
          color: color,
          dashWidth: dashWidth,
          dashHeight: height,
        ),
      ),
    );
  }
}

class _DashLinePainter extends CustomPainter {
  _DashLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashHeight,
  });

  final Color color;
  final double dashWidth;
  final double dashHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = dashHeight
      ..style = .fill;

    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _DashLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashHeight != dashHeight;
}
