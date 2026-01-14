import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/FeedModel.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../image_detail_screen.dart';
import '../../../utils/tag_helper.dart';
import '../../../utils/number_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/snackbar_helper.dart';
import 'comment_modal.dart';

class FeedItem extends StatefulWidget {
  final FeedModel feed;
  const FeedItem({super.key, required this.feed});

  @override
  State<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem> {
  bool _isExpanded = false;
  static const int _maxLines = 3; // 최대 표시 줄 수
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.feed.isLiked;
    _likesCount = widget.feed.likes;
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.toggleLike(widget.feed.portfolioId, _isLiked);

    if (mounted) {
      setState(() {
        _isLiking = false;
      });

      if (response.success && response.data != null) {
        setState(() {
          _isLiked = response.data!.isLiked;
          _likesCount = response.data!.likesCount;
        });
      } else {
        SnackBarHelper.showError(context, response.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorOnSurface = Theme.of(context).colorScheme.onSurface;
    final caption = widget.feed.caption;
    final needsExpansion = _needsExpansion(caption);

    return Padding(
      // ⭕️ EdgeInsets.only 사용
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측: 프로필 이미지 & 스레드 라인
            Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.feed.userImage),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(width: 12),

            // 우측: 콘텐츠 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 헤더 (이름 + 시간 + 더보기)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.feed.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.feed.timeAgo,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                      Icon(Icons.more_horiz, color: Colors.grey.shade500),
                    ],
                  ),

                  // 2. 캡션
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCaptionText(caption, colorOnSurface),
                        if (needsExpansion)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Text(
                                    _isExpanded ? '접기' : '더 보기',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 3. 이미지 슬라이더 (Carousel)
                  if (widget.feed.postImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: CarouselSlider.builder(
                        itemCount: widget.feed.postImages.length,
                        options: CarouselOptions(
                          aspectRatio: 1.0,
                          viewportFraction: 0.9,
                          enableInfiniteScroll: widget.feed.postImages.length > 1,
                          padEnds: false,
                        ),
                        itemBuilder: (context, index, realIndex) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ImageDetailScreen(
                                    imageUrls: widget.feed.postImages,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.feed.postImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // 4. 액션 버튼
                  Row(
                    children: [
                      _buildLikeButton(),
                      _buildCommentButton(),
                      _buildActionButton(Icons.repeat),
                      _buildActionButton(Icons.send_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 태그를 하이라이트한 텍스트 위젯
  Widget _buildCaptionText(String text, Color defaultColor) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return RichText(
      text: TagHelper.buildTagHighlightTextSpan(
        text: text,
        baseStyle: TextStyle(color: defaultColor, fontSize: 14),
      ),
      maxLines: _isExpanded ? null : _maxLines,
      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  // 텍스트가 확장이 필요한지 확인
  bool _needsExpansion(String text) {
    if (text.isEmpty) return false;
    
    // TextPainter를 사용하여 실제 렌더링된 줄 수 확인
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14),
      ),
      maxLines: _maxLines,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: double.infinity);
    
    // 실제 줄 수가 maxLines보다 많으면 확장 필요
    return textPainter.didExceedMaxLines;
  }

  Widget _buildLikeButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: _isLiking ? null : _toggleLike,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLiking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 22,
                    color: _isLiked ? Colors.red : Colors.white,
                  ),
            const SizedBox(width: 4),
            Text(
              NumberFormatter.formatCount(_likesCount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CommentModal(
              portfolioId: widget.feed.portfolioId,
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mode_comment_outlined, size: 22, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              NumberFormatter.formatCount(widget.feed.comments),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon) {
    return Padding(
      // ⭕️ EdgeInsets.only(right: ...)로 수정 완료
      padding: const EdgeInsets.only(right: 16.0),
      child: Icon(icon, size: 22, color: Colors.white),
    );
  }
}