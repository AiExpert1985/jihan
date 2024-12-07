import 'package:flutter/material.dart';
// import 'package:transparent_image/transparent_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:transparent_image/transparent_image.dart';

class TitledImage extends StatelessWidget {
  const TitledImage({required this.imageUrl, required this.title, super.key});

  final String imageUrl;
  final String title;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      elevation: 2,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          //! using cached_image_network to avoid reloading images from firebase (extra cost)
          CachedNetworkImage(
            fit: BoxFit.cover,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            imageUrl: imageUrl,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                Image.memory(kTransparentImage),
            // CircularProgressIndicator(value: downloadProgress.progress),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),

          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Container(
                height: MediaQuery.of(context).size.height * 0.05,
                color: Colors.black45,
                padding: const EdgeInsets.all(5),
                child: Text(
                  title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                )),
          ),
        ],
      ),
    );
  }
}
