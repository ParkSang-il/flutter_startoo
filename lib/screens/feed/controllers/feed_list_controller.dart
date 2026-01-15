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
  double? _savedScrollPosition; // 스크롤 위치 저장
  
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
  
  // 스크롤 위치 저장
  void saveScrollPosition() {
    if (scrollController.hasClients) {
      _savedScrollPosition = scrollController.position.pixels;
    }
  }

  // 스크롤 위치 복원
  void restoreScrollPosition() {
    if (_savedScrollPosition == null || !scrollController.hasClients) {
      return;
    }
    
    // 스크롤 위치가 계산될 때까지 대기
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients && _savedScrollPosition != null) {
        final maxScroll = scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          final targetPosition = _savedScrollPosition! > maxScroll 
              ? maxScroll 
              : _savedScrollPosition!;
          scrollController.jumpTo(targetPosition);
          _savedScrollPosition = null; // 복원 후 초기화
        } else {
          // maxScroll이 0이면 아직 렌더링이 안 된 상태이므로 한 번 더 시도
          Future.delayed(const Duration(milliseconds: 200), () {
            if (scrollController.hasClients && _savedScrollPosition != null) {
              final maxScroll = scrollController.position.maxScrollExtent;
              final targetPosition = _savedScrollPosition! > maxScroll 
                  ? maxScroll 
                  : _savedScrollPosition!;
              scrollController.jumpTo(targetPosition);
              _savedScrollPosition = null; // 복원 후 초기화
            }
          });
        }
      }
    });
  }

  // 피드 리스트 로드
  Future<void> loadFeedList({bool reset = false, bool restorePosition = false}) async {
    int pageToLoad;
    
    if (reset) {
      // 새로고침 시 스크롤 위치 저장
      if (restorePosition) {
        saveScrollPosition();
      }
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
    
    // 스크롤 위치 복원
    if (reset && restorePosition) {
      restoreScrollPosition();
    }
  }
  
  // 특정 포트폴리오만 업데이트 (현재 페이지에서 해당 포트폴리오만 다시 받아와서 교체)
  Future<void> updatePortfolio(int portfolioId) async {
    // 현재 페이지를 다시 받아와서 해당 포트폴리오만 찾아서 교체
    final response = await _authProvider.getFeedList(page: _currentPage);
    
    if (response.success && response.data != null) {
      // 현재 페이지의 포트폴리오 목록에서 해당 포트폴리오 찾기
      final updatedPortfolio = response.data!.portfolios.firstWhere(
        (p) => p.id == portfolioId,
        orElse: () => Portfolio(
          id: 0,
          userId: 0,
          title: '',
          description: '',
          workDate: '',
          price: '0.00',
          isPublic: true,
          isSensitive: false,
          views: 0,
          likesCount: 0,
          commentsCount: 0,
          createdAt: '',
          updatedAt: '',
          images: [],
          tags: [],
          user: PortfolioUser(id: 0, username: '', profileImage: '', userType: 0),
          business: PortfolioBusiness(id: 0, userId: 0, businessName: ''),
        ),
      );
      
      // 해당 포트폴리오가 현재 리스트에 있는지 확인하고 교체
      final index = _portfolios.indexWhere((p) => p.id == portfolioId);
      if (index != -1 && updatedPortfolio.id != 0) {
        _portfolios[index] = updatedPortfolio;
        notifyListeners();
      }
    }
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

