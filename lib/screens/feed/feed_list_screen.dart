import 'package:flutter/material.dart';
import 'widgets/feed_item.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_or_register_screen.dart';

class FeedListPage extends StatefulWidget {
  const FeedListPage({super.key});

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

class _FeedListPageState extends State<FeedListPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  final double _appBarHeight = 15.0; // AppBar 높이 더 줄임

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final totalAppBarHeight = _appBarHeight + topPadding;
    
    // 스크롤 위치에 따른 알파값 계산 (0 ~ 1)
    // 스크롤이 0일 때 opacity = 1, 스크롤이 appBarHeight만큼 내려가면 opacity = 0
    final opacity = (1.0 - (_scrollOffset / topPadding)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: true, // SliverAppBar가 SafeArea를 처리하도록
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 인스타그램 스타일 AppBar - 리스트와 함께 스크롤됨
            SliverAppBar(
              expandedHeight: totalAppBarHeight,
              toolbarHeight: _appBarHeight,
              floating: false,
              pinned: false,
              snap: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Opacity(
                  opacity: opacity,
                  child: SizedBox(
                    height: totalAppBarHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 16),
                        Text(
                          'Starttoo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.favorite_border,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Feed List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => FeedItem(index: index),
              childCount: 30,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

