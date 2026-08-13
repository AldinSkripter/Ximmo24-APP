import 'package:carousel_slider/carousel_slider.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/like_button_widget.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:flutter/material.dart';

class PropertyImageCarousel extends StatelessWidget {
  const PropertyImageCarousel({
    required this.property,
    required this.currentIndex,
    required this.onPageChanged,
    super.key,
    this.heroTag,
  });

  final PropertyModel property;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final videoUrl = property.video?.trim();
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    final imageUrls = <String>[
      if (property.titleImage != null && property.titleImage!.isNotEmpty)
        property.titleImage!,
      ...?property.gallery
          ?.where((element) => !(element.isVideo ?? false))
          .map((e) => e.imageUrl),
    ];

    // Build carousel items: title image first, then video (if exists),
    // then remaining images.
    final carouselItems = <Widget>[
      ...imageUrls.asMap().entries.map((entry) {
        Widget image = CustomImage(
          imageUrl: entry.value,
          width: double.infinity,
          height: 218.rs(context),
          showFullScreenImage: true,
        );
        // Wrap the first image in a Hero for shared-element transition
        if (entry.key == 0 && heroTag != null) {
          image = Hero(tag: heroTag!, child: image);
        }
        return image;
      }),
    ];

    // Insert video after the first image (title image)
    if (hasVideo) {
      final videoWidget = _buildVideoThumbnailItem(videoUrl);
      if (carouselItems.isNotEmpty) {
        carouselItems.insert(1, videoWidget);
      } else {
        carouselItems.add(videoWidget);
      }
    }

    final totalItems = carouselItems.length;

    return SizedBox(
      height: 218.rs(context),
      child: Stack(
        children: [
          if (totalItems > 1)
            Stack(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    autoPlay: !hasVideo,
                    viewportFraction: 1,
                    height: 218.rs(context),
                    onPageChanged: (index, reason) {
                      onPageChanged(index);
                    },
                  ),
                  items: carouselItems,
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: .center,
                    children: List.generate(totalItems, (index) {
                      // Video is at index 1 when images exist, or index 0
                      // when there are no images.
                      final videoIndex = imageUrls.isNotEmpty ? 1 : 0;
                      if (hasVideo && index == videoIndex) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 18,
                            color: Colors.white.withValues(
                              alpha: currentIndex == index ? 0.9 : 0.4,
                            ),
                          ),
                        );
                      }

                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          shape: .circle,
                          color: Colors.white.withValues(
                            alpha: currentIndex == index ? 0.9 : 0.4,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            )
          else if (totalItems == 1)
            carouselItems.first
          else
            Container(
              alignment: Alignment.center,
              child: CustomImage(
                imageUrl: property.titleImage ?? '',
                width: double.infinity,
                height: 218.rs(context),
                showFullScreenImage: true,
                loadingImageHash: property.lowQualityTitleImage,
              ),
            ),
          if (property.id != null)
            PositionedDirectional(
              top: 16.rh(context),
              end: 16.rh(context),
              child: LikeButtonWidget(
                size: 36,
                propertyId: property.id!,
                isFavourite: property.isFavourite == '1',
              ),
            ),
          if (property.isPremium == true ||
              property.allPropData?['is_premium'] == true)
            PositionedDirectional(
              start: 16.rh(context),
              top: 16.rh(context),
              child: Container(
                alignment: Alignment.center,
                child: heroTag != null
                    ? Hero(
                        tag: '$heroTag-premium',
                        child: CustomImage(
                          imageUrl: AppIcons.premium,
                          height: 24.rh(context),
                          width: 24.rw(context),
                        ),
                      )
                    : CustomImage(
                        imageUrl: AppIcons.premium,
                        height: 24.rh(context),
                        width: 24.rw(context),
                      ),
              ),
            ),
          if (property.promoted == true)
            PositionedDirectional(
              bottom: 16.rh(context),
              start: 16.rh(context),
              child: heroTag != null
                  ? Hero(
                      tag: '$heroTag-promoted',
                      child: const PromotedCard(),
                    )
                  : const PromotedCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnailItem(String videoUrl) {
    return CustomVideoPlayer(
      videoUrl: videoUrl,
      autoPlay: true,
    );
  }
}
