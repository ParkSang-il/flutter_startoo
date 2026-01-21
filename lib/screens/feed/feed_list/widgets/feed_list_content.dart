import 'package:flutter/material.dart';
import '../../controllers/feed_list_controller.dart';
import '../../model/FeedModel.dart';
import '../../widgets/feed_item.dart';
import '../../widgets/feed_item_skeleton.dart';
import '../../../../models/portfolio_model.dart';
import '../../../../utils/image_url_helper.dart';
import 'feed_list_app_bar.dart';

class FeedListContent extends StatelessWidget {
  final FeedListController controller;
  final Future<void> Function() onRefresh;
  final Function(int) onCommentAdded;

  const FeedListContent({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.onCommentAdded,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).colorScheme.onSurface,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          const FeedListAppBar(),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // 초기 로딩 중
                if (controller.isLoading && index == 0) {
                  return const FeedItemSkeleton();
                }

                // 로딩 중이 아니고 인덱스가 범위를 벗어나면 빈 위젯
                if (index >= controller.portfolios.length) {
                  // 추가 로딩 중일 때 로딩 인디케이터 표시
                  if (controller.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                final portfolio = controller.portfolios[index];

                // media 배열을 order 기준으로 정렬 (성능 최적화: 한 번만 정렬)
                final sortedMedia = List<PortfolioMedia>.from(portfolio.media)
                  ..sort((a, b) => a.order.compareTo(b.order));

                // 이미지 URL만 추출 (하위 호환성) - ImageUrlHelper 사용
                final imageUrls = sortedMedia
                    .where((m) => m.isImage && m.imageUrl != null)
                    .map((m) => ImageUrlHelper.buildFeedImageUrl(m.imageUrl))
                    .toList();

                // 첫 번째 미디어 URL (이미지 또는 비디오 썸네일)
                final firstMediaUrl = sortedMedia.isNotEmpty
                    ? (sortedMedia.first.isImage
                        ? ImageUrlHelper.buildFeedImageUrl(
                            sortedMedia.first.imageUrl)
                        : (sortedMedia.first.videoThumbnailUrl ??
                            sortedMedia.first.videoUrl ??
                            ''))
                    : '';

                // firstMediaUrl이 null이면 빈 문자열 사용
                final safeFirstMediaUrl =
                    firstMediaUrl.isNotEmpty ? firstMediaUrl : '';

                // FeedModel 생성 (성능 최적화: const 가능한 부분은 const로)
                final feed = FeedModel(
                  portfolioId: portfolio.id,
                  portfolioOwnerId: portfolio.userId,
                  username: portfolio.user.username,
                  userImage: portfolio.user.profileImage,
                  userType: portfolio.user.userType,
                  postImage: safeFirstMediaUrl,
                  postImages: imageUrls,
                  media: sortedMedia,
                  caption: portfolio.description,
                  likes: portfolio.likesCount,
                  comments: portfolio.commentsCount,
                  timeAgo: portfolio.timeAgo,
                  businessName: portfolio.business.businessName,
                  isLiked: portfolio.isLiked,
                );

                // FeedItem 생성 (성능 최적화: key를 portfolioId로 설정하여 재사용 최적화)
                return FeedItem(
                  key: ValueKey('feed_${portfolio.id}'), // 성능 최적화: key로 위젯 재사용
                  feed: feed,
                  onCommentAdded: () {
                    // 댓글 작성 후 해당 포트폴리오만 업데이트
                    onCommentAdded(feed.portfolioId);
                  },
                );
              },
              childCount: controller.isLoading
                  ? 10
                  : controller.portfolios.length +
                      (controller.isLoadingMore ? 1 : 0),
              addAutomaticKeepAlives: false, // 성능 최적화: 스크롤 밖 위젯은 dispose
              addRepaintBoundaries: true, // 성능 최적화: 위젯 경계에서 리페인트 분리
              addSemanticIndexes: false, // 성능 최적화: 시맨틱 인덱스 비활성화
            ),
          ),
        ],
      ),
    );
  }
}

