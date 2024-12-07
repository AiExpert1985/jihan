import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/values/constants.dart' as constants;
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tablets/src/common/values/gaps.dart';

class ImageSlider extends ConsumerWidget {
  const ImageSlider({this.imageUrls = const [constants.defaultImageUrl], super.key});
  final List<String>? imageUrls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatedImageUrls = ref.watch(imagePickerProvider);
    int displayedUrlIndex = updatedImageUrls.length - 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CarouselSlider(
          items: updatedImageUrls
              .map(
                (url) => CachedNetworkImage(
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height,
                  imageUrl: url,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      // Image.memory(kTransparentImage),
                      CircularProgressIndicator(value: downloadProgress.progress),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              )
              .toList(),
          options: CarouselOptions(
            onPageChanged: (index, reason) => displayedUrlIndex = index,
            height: 150,
            autoPlay: false,
            initialPage: -1, // initially display last image
          ),
        ),
        VerticalGap.m,
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            onPressed: () => ref.read(imagePickerProvider.notifier).addImage(),
            icon: const AddImageIcon(),
          ),
          IconButton(
            onPressed: () => ref.read(imagePickerProvider.notifier).removeImage(displayedUrlIndex),
            icon: const DeleteIcon(),
          )
        ])
      ],
    );
  }
}
