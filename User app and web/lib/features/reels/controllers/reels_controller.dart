import 'dart:async';

import 'package:get/get.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/reels/domain/models/reel_model.dart';
import 'package:sixam_mart/features/reels/domain/repositories/reels_repository_interface.dart';
import 'package:sixam_mart/features/reels/domain/services/reels_service_interface.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

class ReelsController extends GetxController {
  final ReelsServiceInterface reelsServiceInterface;
  ReelsController({required this.reelsServiceInterface});

  List<ReelModel>? _reelsList;
  List<ReelModel>? get reelsList => _reelsList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _pageSize;
  int? get pageSize => _pageSize;

  final List<String> _offsetList = <String>[];

  int _offset = 1;
  int get offset => _offset;

  static const int reelPageLimit = 10;

  final Map<int, ReelModel> _reelDetailsMap = <int, ReelModel>{};
  Map<int, ReelModel> get reelDetailsMap => _reelDetailsMap;

  final Map<int, ReelStatsModel> _reelStatsMap = <int, ReelStatsModel>{};
  Map<int, ReelStatsModel> get reelStatsMap => _reelStatsMap;

  final Set<int> _statsLoadingIds = <int>{};

  final Set<int> _likeBusyIds = <int>{};

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // Transient toast rendered inside the reel dialog's own widget tree.
  // Needed because Get.showSnackbar / root-overlay entries render below the
  // HTML <video> platform view on Flutter web, so the message stays invisible.
  static const String transientToastGetId = 'reel_transient_toast';
  String? _transientToastMessage;
  String? get transientToastMessage => _transientToastMessage;
  bool _transientToastIsError = true;
  bool get transientToastIsError => _transientToastIsError;
  Timer? _transientToastTimer;

  void showTransientToast(String message, {bool isError = true, Duration duration = const Duration(seconds: 3)}) {
    if(message.isEmpty) {
      return;
    }
    _transientToastMessage = message;
    _transientToastIsError = isError;
    _transientToastTimer?.cancel();
    _transientToastTimer = Timer(duration, () {
      _transientToastMessage = null;
      update(<String>[transientToastGetId]);
    });
    update(<String>[transientToastGetId]);
  }

  @override
  void onClose() {
    _transientToastTimer?.cancel();
    super.onClose();
  }

  void setOffset(int offset) {
    _offset = offset;
  }

  bool reelListLoadingComplete() {
    if(_pageSize == null || _reelsList == null) {
      return false;
    }
    return _reelsList!.length >= _pageSize!;
  }

  Future<void> getReelsList({int offset = 1, DataSourceEnum dataSource = DataSourceEnum.local, bool notify = true}) async {
    final String offsetKey = offset.toString();

    if(offset == 1) {
      _offsetList.clear();
      _offset = 1;
    }

    if(_offsetList.contains(offsetKey)) {
      if(_isLoading) {
        _isLoading = false;
        if(notify) update();
      }
      return;
    }
    _offsetList.add(offsetKey);

    _isLoading = _reelsList == null;
    if(notify) update();

    final ReelListModel? responseList = await reelsServiceInterface.getReelsList(
      dataSource,
      offset: offset,
      limit: reelPageLimit,
    );

    _prepareReels(responseList, offset);

    if(dataSource == DataSourceEnum.local && offset == 1) {
      await getReelsList(offset: 1, dataSource: DataSourceEnum.client, notify: notify);
    }
  }

  void _prepareReels(ReelListModel? responseList, int offset) {
    if(responseList != null) {
      final List<ReelModel> fetchedReels = responseList.reels ?? <ReelModel>[];
      if(offset == 1 || _reelsList == null) {
        _reelsList = <ReelModel>[];
      }
      _reelsList!.addAll(fetchedReels);
      _pageSize = responseList.totalSize;
      _seedStatsFromReels(fetchedReels);
      if(_currentIndex >= _reelsList!.length) {
        _currentIndex = 0;
      }
    }
    _isLoading = false;
    update();
  }

  Future<void> loadMoreReels() async {
    if(_isLoading || reelListLoadingComplete()) {
      return;
    }
    _offset += 1;
    await getReelsList(offset: _offset, dataSource: DataSourceEnum.client);
  }

  void setCurrentIndex(int index, {bool shouldUpdate = true}) {
    _currentIndex = index;
    if(shouldUpdate) {
      update();
    }
  }

  ReelModel getResolvedReel(ReelModel reel) {
    final int? reelId = reel.reelId;
    if(reelId == null) {
      return reel;
    }
    return reel.mergeWith(_reelDetailsMap[reelId]);
  }

  bool isReelStatsLoading(int reelId) => _statsLoadingIds.contains(reelId);

  ReelStatsModel? getReelStatsFromMap(int reelId) => _reelStatsMap[reelId];

  Future<ReelStatsModel?> getReelStats(int reelId, {bool reload = false}) async {
    final bool isLoggedIn = AuthHelper.isLoggedIn();
    // A cached entry seeded from the list/details payload may lack `is_liked`
    // (list endpoint often omits it). For logged-in users we must still hit the
    // stats endpoint so the heart icon reflects the server's true liked state.
    final bool isLikedUnknown = isLoggedIn
        && _reelStatsMap.containsKey(reelId)
        && _reelStatsMap[reelId]?.isLiked == null;
    if(!reload && !isLikedUnknown && _reelStatsMap.containsKey(reelId)) {
      return _reelStatsMap[reelId];
    }
    // if(_statsLoadingIds.contains(reelId)) {
    //   print('=======here=====2===');
    //   return _reelStatsMap[reelId];
    // }

    // Guest view: drop any `isLiked` carried over from a previous logged-in
    // session so the UI doesn't flash a liked heart while the refresh is in
    // flight. The fresh API response will populate the correct state.
    if(!isLoggedIn) {
      final ReelStatsModel? existing = _reelStatsMap[reelId];
      if(existing != null && existing.isLiked != null) {
        existing.isLiked = null;
      }
    }

    _statsLoadingIds.add(reelId);
    // if(reload) {
    //   update();
    // }
    final ReelStatsModel? responseStats = await reelsServiceInterface.getReelStats(reelId);
    if(responseStats != null) {
      // The stats endpoint may omit `is_liked`; preserve the previously-known value
      // (from list/details response or a prior toggle) so liked state stays correct —
      // but only for logged-in users, so a guest never inherits a prior session's like.
      if(isLoggedIn) {
        final ReelStatsModel? previous = _reelStatsMap[reelId];
        responseStats.isLiked ??= previous?.isLiked;
      } else {
        responseStats.isLiked = false;
      }
      _reelStatsMap[reelId] = responseStats;
    }

    _statsLoadingIds.remove(reelId);
    update();
    return _reelStatsMap[reelId];
  }

  // Seeds the stats map from reel payloads (list/details) so that `isLiked`
  // returned at the reel root or inside `stats` is reflected in the UI before
  // the dedicated stats endpoint is called.
  void _seedStatsFromReels(List<ReelModel> reels) {
    for(final ReelModel reel in reels) {
      final int? reelId = reel.reelId;
      final ReelStatsModel? reelStats = reel.stats;
      if(reelId == null || reelStats == null) {
        continue;
      }
      final ReelStatsModel? existing = _reelStatsMap[reelId];
      if(existing == null) {
        _reelStatsMap[reelId] = ReelStatsModel(
          totalViews: reelStats.totalViews,
          totalLikes: reelStats.totalLikes,
          totalStoreVisits: reelStats.totalStoreVisits,
          isLiked: reelStats.isLiked,
        );
      } else if(existing.isLiked == null && reelStats.isLiked != null) {
        existing.isLiked = reelStats.isLiked;
      }
    }
  }

  bool isReelLikeBusy(int reelId) => _likeBusyIds.contains(reelId);

  // Guests can never have a liked reel — guard against stale `isLiked` cached
  // from a previous logged-in session in this process.
  bool isReelLiked(int reelId) => AuthHelper.isLoggedIn() && _reelStatsMap[reelId]?.isLiked == true;

  Future<bool> toggleReelLike(int reelId) async {
    if(!AuthHelper.isLoggedIn()) {
      showTransientToast('you_are_not_logged_in'.tr);
      return false;
    }
    if(_likeBusyIds.contains(reelId)) {
      return false;
    }

    _likeBusyIds.add(reelId);
    final ReelStatsModel existing = _reelStatsMap[reelId] ?? ReelStatsModel();
    final bool wasLiked = existing.isLiked == true;
    final int baseLikes = existing.totalLikes ?? 0;

    // Optimistic update for instant UI feedback.
    _reelStatsMap[reelId] = ReelStatsModel(
      totalViews: existing.totalViews,
      totalLikes: (baseLikes + (wasLiked ? -1 : 1)).clamp(0, 1 << 31),
      totalStoreVisits: existing.totalStoreVisits,
      isLiked: !wasLiked,
    );
    update();

    final ReelLikeResponseModel likeResponse = await reelsServiceInterface.toggleReelLike(reelId);

    if(likeResponse.response.isSuccess) {
      final ReelStatsModel current = _reelStatsMap[reelId] ?? existing;
      _reelStatsMap[reelId] = ReelStatsModel(
        totalViews: current.totalViews,
        totalLikes: likeResponse.totalLikes ?? current.totalLikes,
        totalStoreVisits: current.totalStoreVisits,
        isLiked: likeResponse.isLiked ?? current.isLiked,
      );
    } else {
      // Revert optimistic change on failure.
      _reelStatsMap[reelId] = existing;
      if(likeResponse.response.message != null && likeResponse.response.message!.isNotEmpty) {
        showTransientToast(likeResponse.response.message!);
      }
    }

    _likeBusyIds.remove(reelId);
    update();
    return likeResponse.response.isSuccess;
  }

  Future<bool> visitReel(int reelId) async {
    return reelsServiceInterface.visitReel(reelId);
  }
}
