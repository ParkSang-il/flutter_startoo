import 'package:flutter/material.dart';
import '../../../models/portfolio_model.dart';
import '../../../providers/auth_provider.dart';

class FeedListController extends ChangeNotifier {
  final AuthProvider _authProvider;
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<Portfolio> _portfolios = [];
  int _currentPage = 1;
  int _lastPage = 1;
  final ScrollController scrollController = ScrollController();
  
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  List<Portfolio> get portfolios => _portfolios;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  
  FeedListController(this._authProvider) {
    scrollController.addListener(_onScroll);
  }
  
  // 스크롤 감지하여 페이징 처리
  void _onScroll() {
    if (!scrollController.hasClients) return;
    
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    
    // 스크롤이 80% 이상 내려갔을 때 다음 페이지 로드
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.8) {
      if (!_isLoadingMore && !_isLoading && _currentPage < _lastPage) {
        loadFeedList(reset: false);
      }
    }
  }
  
  // 피드 리스트 로드
  Future<void> loadFeedList({bool reset = false}) async {
    int pageToLoad;
    
    if (reset) {
      // 새로고침 시 첫 페이지로 리셋
      pageToLoad = 1;
      _currentPage = 1;
      _isLoading = true;
      _portfolios = [];
      notifyListeners();
    } else {
      // 다음 페이지 로드
      if (_isLoadingMore || _currentPage >= _lastPage) {
        return;
      }
      pageToLoad = _currentPage + 1;
      _isLoadingMore = true;
      notifyListeners();
    }

    final response = await _authProvider.getFeedList(page: pageToLoad);

    _isLoading = false;
    _isLoadingMore = false;
    
    if (response.success && response.data != null) {
      _errorMessage = null;
      if (reset) {
        // 새로고침 시 리스트 교체
        _portfolios = response.data!.portfolios;
      } else {
        // 다음 페이지 추가
        _portfolios.addAll(response.data!.portfolios);
      }
      
      // 페이징 정보 업데이트
      _currentPage = response.data!.pagination.currentPage;
      _lastPage = response.data!.pagination.lastPage;
    } else {
      // 에러 발생 시
      _errorMessage = response.message.isNotEmpty 
          ? response.message 
          : '피드 리스트를 불러오는데 실패했습니다.';
      if (reset) {
        _portfolios = [];
      }
    }
    
    notifyListeners();
  }
  
  // 에러 메시지 표시 (컨텍스트 필요 시 별도 처리)
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }
}

