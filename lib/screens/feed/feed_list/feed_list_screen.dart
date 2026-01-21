import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/feed_list_controller.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../widgets/custom_bottom_navigation_bar.dart';
import '../../create/create_screen.dart';
import '../../search_screen.dart';
import '../../activity_screen.dart';
import '../../mypage/mypage_screen.dart';
import 'widgets/feed_list_content.dart';

class FeedListPage extends StatefulWidget {
  const FeedListPage({super.key});

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

class _FeedListPageState extends State<FeedListPage> {
  int _currentIndex = 0; // bottom navigation 현재 인덱스
  late FeedListController _feedController;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _feedController = FeedListController(authProvider);
    _feedController.addListener(_onFeedControllerUpdate);
    // 빌드가 완료된 후에 실행되도록 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex == 0) {
        _feedController.loadFeedList(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _feedController.removeListener(_onFeedControllerUpdate);
    _feedController.dispose();
    super.dispose();
  }

  void _onFeedControllerUpdate() {
    if (mounted) {
      setState(() {});

      // 에러 메시지 표시
      if (_feedController.errorMessage != null &&
          _feedController.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_feedController.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        _feedController.clearError();
      }
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // 등록 화면은 모달로 표시
      _showCreateModal();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 전체 화면 사용 가능
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateScreen(),
    ).then((_) {
      // 모달이 닫힌 후 피드 리스트 새로고침
      if (_currentIndex == 0) {
        _feedController.loadFeedList(reset: true);
      }
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildFeedList();
      case 1:
        return const SearchScreen();
      case 2:
        // 등록 화면은 모달로 표시되므로 여기서는 피드 리스트 표시
        return _buildFeedList();
      case 3:
        return const ActivityScreen();
      case 4:
        return const MyPageScreen();
      default:
        return _buildFeedList();
    }
  }

  Widget _buildFeedList() {
    return FeedListContent(
      controller: _feedController,
      onRefresh: () async {
        await _feedController.loadFeedList(reset: true);
      },
      onCommentAdded: (portfolioId) {
        _feedController.updatePortfolio(portfolioId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 키보드가 올라와도 화면 크기 유지
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        height: 65,
        child: CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

