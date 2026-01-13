import 'package:flutter/material.dart';
import '../model/FeedModel.dart';
import 'package:carousel_slider/carousel_slider.dart';

class FeedItem extends StatefulWidget {
  final FeedModel feed;

  const FeedItem({super.key, required this.feed});

  @override
  State<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem> {
  @override
  Widget build(BuildContext context) {
    final colorOnSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 헤더 (프로필 이미지 + 아이디)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(widget.feed.userImage),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.feed.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.more_horiz),
            ],
          ),
        ),

        CarouselSlider.builder(
          itemCount: widget.feed.postImages.length,
          options: CarouselOptions(
            // 1. 비율 설정: 1.0(정사각형) 또는 0.8(4:5 비율) 추천
            aspectRatio: 0.8,

            // 2. 화면에 꽉 차게 설정 (옆에 다음 사진이 안 보이게)
            viewportFraction: 1.0,

            // 3. 사진이 1장일 때는 스크롤 및 자동재생 방지
            enableInfiniteScroll: widget.feed.postImages.length > 1,
            autoPlay: false,
          ),
          itemBuilder: (context, index, realIndex) {
            final String imageUrl = widget.feed.postImages[index]; // 현재 인덱스의 이미지 URL

            return Image.network(
              imageUrl,
              width: double.infinity,
              // 5. BoxFit.cover: 사진이 잘리더라도 영역을 꽉 채움 (인스타 스타일)
              // 만약 사진이 잘리는게 절대 싫다면 BoxFit.contain 사용
              fit: BoxFit.cover,
              // 로딩 중 표시 (선택 사항)
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  color: Colors.grey.shade800,
                  child: Icon(Icons.broken_image, color: Colors.grey.shade600, size: 50),
                );
              },
            );
          },
        ),

        // 3. 액션 버튼 (좋아요, 댓글, 공유, 저장)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.mode_comment_outlined)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.send_outlined)),
                ],
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border)),
            ],
          ),
        ),

        // 4. 좋아요 개수 및 캡션
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '좋아요 ${widget.feed.likes}개',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: colorOnSurface),
                  children: [
                    TextSpan(
                      text: widget.feed.userType == 1 ? '${widget.feed.username}' : widget.feed.businessName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: widget.feed.caption),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.feed.timeAgo,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}