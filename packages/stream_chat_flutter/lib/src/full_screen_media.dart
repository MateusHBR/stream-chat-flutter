import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:stream_chat_flutter/src/extension.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:video_player/video_player.dart';

/// Return action for coming back from pages
enum ReturnActionType {
  /// No return action
  none,

  /// Go to reply message action
  reply,
}

/// Callback when show message is tapped
typedef ShowMessageCallback = void Function(Message message, Channel channel);

/// A full screen image widget
class FullScreenMedia extends StatefulWidget {
  /// Instantiate a new FullScreenImage
  const FullScreenMedia({
    Key? key,
    required this.mediaAttachments,
    required this.message,
    this.startIndex = 0,
    String? userName,
    this.onShowMessage,
    this.attachmentActionsModalBuilder,
    this.autoplayVideos = false,
  })  : userName = userName ?? '',
        super(key: key);

  /// The url of the image
  final List<Attachment> mediaAttachments;

  /// Message where attachments are attached
  final Message message;

  /// First index of media shown
  final int startIndex;

  /// Username of sender
  final String userName;

  /// Callback for when show message is tapped
  final ShowMessageCallback? onShowMessage;

  /// Widget builder for attachment actions modal
  /// [defaultActionsModal] is the default [AttachmentActionsModal] config
  /// Use [defaultActionsModal.copyWith] to easily customize it
  final AttachmentActionsBuilder? attachmentActionsModalBuilder;

  /// Auto-play videos when page is opened
  final bool autoplayVideos;

  @override
  _FullScreenMediaState createState() => _FullScreenMediaState();
}

class _FullScreenMediaState extends State<FullScreenMedia>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final PageController _pageController;

  late final _curvedAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  final _opacityTween = Tween<double>(begin: 1, end: 0);
  late final _opacityAnimation = _opacityTween.animate(
    CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    ),
  );

  late final ValueNotifier<int> _currentPage = ValueNotifier(widget.startIndex);

  final videoPackages = <String, VideoPackage>{};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pageController = PageController(initialPage: widget.startIndex);
    for (var i = 0; i < widget.mediaAttachments.length; i++) {
      final attachment = widget.mediaAttachments[i];
      if (attachment.type != 'video') continue;
      final package = VideoPackage(attachment, showControls: true);
      videoPackages[attachment.id] = package;
    }
    initializePlayers();
  }

  Future<void> initializePlayers() async {
    if (videoPackages.isEmpty) {
      return;
    }

    final currentAttachment = widget.mediaAttachments[widget.startIndex];

    await Future.wait(videoPackages.values.map(
      (it) => it.initialize(),
    ));

    if (widget.autoplayVideos && currentAttachment.type == 'video') {
      final package = videoPackages.values
          .firstWhere((e) => e._attachment == currentAttachment);
      package._chewieController?.play();
    }
    setState(() {}); // ignore: no-empty-block
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (val) {
                _currentPage.value = val;

                if (videoPackages.isEmpty) {
                  return;
                }

                final currentAttachment = widget.mediaAttachments[val];

                for (final e in videoPackages.values) {
                  if (e._attachment != currentAttachment) {
                    e._chewieController?.pause();
                  }
                }

                if (widget.autoplayVideos &&
                    currentAttachment.type == 'video') {
                  final controller = videoPackages[currentAttachment.id]!;
                  controller._chewieController?.play();
                }
              },
              itemBuilder: (context, index) {
                final attachment = widget.mediaAttachments[index];
                if (attachment.type == 'image' || attachment.type == 'giphy') {
                  final imageUrl = attachment.imageUrl ??
                      attachment.assetUrl ??
                      attachment.thumbUrl;
                  return AnimatedBuilder(
                    animation: _curvedAnimation,
                    builder: (context, child) => PhotoView(
                      loadingBuilder: (context, image) => const Offstage(),
                      imageProvider: (imageUrl == null &&
                              attachment.localUri != null &&
                              attachment.file?.bytes != null)
                          ? Image.memory(attachment.file!.bytes!).image
                          : CachedNetworkImageProvider(imageUrl!),
                      maxScale: PhotoViewComputedScale.covered,
                      minScale: PhotoViewComputedScale.contained,
                      heroAttributes: PhotoViewHeroAttributes(
                        tag: widget.mediaAttachments,
                      ),
                      backgroundDecoration: BoxDecoration(
                        color: ColorTween(
                          begin: ChannelHeaderTheme.of(context).color,
                          end: Colors.black,
                        ).lerp(_curvedAnimation.value),
                      ),
                      onTapUp: (a, b, c) {
                        if (_animationController.isCompleted) {
                          _animationController.reverse();
                        } else {
                          _animationController.forward();
                        }
                      },
                    ),
                  );
                } else if (attachment.type == 'video') {
                  final controller = videoPackages[attachment.id]!;
                  if (!controller.initialized) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return InkWell(
                    onTap: () {
                      if (_animationController.isCompleted) {
                        _animationController.reverse();
                      } else {
                        _animationController.forward();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 50,
                      ),
                      child: Chewie(
                        controller: controller.chewieController!,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              itemCount: widget.mediaAttachments.length,
            ),
            FadeTransition(
              opacity: _opacityAnimation,
              child: ValueListenableBuilder<int>(
                valueListenable: _currentPage,
                builder: (context, value, child) => Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GalleryHeader(
                      userName: widget.userName,
                      sentAt: context.translations.sentAtText(
                        date: widget.message.createdAt,
                        time: widget.message.createdAt,
                      ),
                      onBackPressed: () {
                        Navigator.of(context).pop();
                      },
                      message: widget.message,
                      currentIndex: value,
                      onShowMessage: () {
                        widget.onShowMessage?.call(
                          widget.message,
                          StreamChannel.of(context).channel,
                        );
                      },
                      attachmentActionsModalBuilder:
                          widget.attachmentActionsModalBuilder,
                    ),
                    if (!widget.message.isEphemeral)
                      GalleryFooter(
                        currentPage: value,
                        totalPages: widget.mediaAttachments.length,
                        mediaAttachments: widget.mediaAttachments,
                        message: widget.message,
                        mediaSelectedCallBack: (val) {
                          _currentPage.value = val;
                          _pageController.animateToPage(
                            val,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    for (final package in videoPackages.values) {
      package.dispose();
    }
    super.dispose();
  }
}

/// Class for packaging up things required for videos
class VideoPackage {
  /// Constructor for creating [VideoPackage]
  VideoPackage(
    this._attachment, {
    bool showControls = false,
    bool autoInitialize = true,
  })  : _showControls = showControls,
        _autoInitialize = autoInitialize,
        _videoPlayerController = _attachment.localUri != null
            ? VideoPlayerController.file(File.fromUri(_attachment.localUri!))
            : VideoPlayerController.network(_attachment.assetUrl!);

  final Attachment _attachment;
  final bool _showControls;
  final bool _autoInitialize;
  final VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  /// Get video player for video
  VideoPlayerController get videoPlayer => _videoPlayerController;

  /// Get [ChewieController] for video
  ChewieController? get chewieController => _chewieController;

  /// Check if controller is initialised
  bool get initialized => _videoPlayerController.value.isInitialized;

  /// Initialize all things required for [VideoPackage]
  Future<void> initialize() => _videoPlayerController.initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoInitialize: _autoInitialize,
          showControls: _showControls,
          aspectRatio: _videoPlayerController.value.aspectRatio,
        );
      });

  /// Add a listener to video player controller
  void addListener(VoidCallback listener) =>
      _videoPlayerController.addListener(listener);

  /// Remove a listener to video player controller
  void removeListener(VoidCallback listener) =>
      _videoPlayerController.removeListener(listener);

  /// Dispose controllers
  Future<void> dispose() {
    _chewieController?.dispose();
    return _videoPlayerController.dispose();
  }
}
