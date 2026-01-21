import 'package:flutter/material.dart';
import '../../../models/portfolio_model.dart';
import 'controllers/image_detail_controller.dart';
import 'widgets/image_detail_app_bar.dart';
import 'widgets/image_detail_page_view.dart';
import 'widgets/image_detail_indicator.dart';

class ImageDetailScreen extends StatefulWidget {
  final List<String>? imageUrls; // 하위 호환성을 위해 유지
  final List<PortfolioMedia>? mediaList; // 이미지와 비디오 통합 리스트
  final int initialIndex;

  const ImageDetailScreen({
    super.key,
    this.imageUrls,
    this.mediaList,
    this.initialIndex = 0,
  }) : assert(imageUrls != null || mediaList != null,
            'imageUrls 또는 mediaList 중 하나는 필수입니다.');

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  late final ImageDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImageDetailController();

    // mediaList가 있으면 사용, 없으면 imageUrls를 PortfolioMedia로 변환
    List<PortfolioMedia> mediaList;
    if (widget.mediaList != null) {
      mediaList = widget.mediaList!;
    } else {
      // 하위 호환성: imageUrls를 PortfolioMedia 리스트로 변환
      mediaList = widget.imageUrls!.map((url) => PortfolioMedia(
            type: 'image',
            id: 0,
            imageUrl: url,
            order: 0,
            createdAt: '',
          )).toList();
    }

    _controller.initialize(mediaList, widget.initialIndex);
    // 위젯이 마운트된 후 비디오 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.initializeVideos(
          mounted: mounted,
          setState: _setState,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: const ImageDetailAppBar(),
      body: Stack(
        children: [
          ImageDetailPageView(
            controller: _controller,
            onPageChanged: _setState,
            setState: _setState,
          ),
          ImageDetailIndicator(
            itemCount: _controller.itemCount,
            currentIndex: _controller.currentIndex,
          ),
        ],
      ),
    );
  }
}

