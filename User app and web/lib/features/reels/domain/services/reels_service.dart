import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/reels/domain/models/reel_model.dart';
import 'package:sixam_mart/features/reels/domain/repositories/reels_repository_interface.dart';
import 'package:sixam_mart/features/reels/domain/services/reels_service_interface.dart';


class ReelsService implements ReelsServiceInterface {
  final ReelsRepositoryInterface reelsRepositoryInterface;
  ReelsService({required this.reelsRepositoryInterface});

  @override
  Future<ReelListModel?> getReelsList(DataSourceEnum source, {int offset = 1, int limit = 10}) async {
    return reelsRepositoryInterface.getList(offset: offset, limit: limit, source: source);
  }

  @override
  Future<ReelStatsModel?> getReelStats(int reelId) async {
    return reelsRepositoryInterface.getReelStats(reelId);
  }

  @override
  Future<ReelLikeResponseModel> toggleReelLike(int reelId) async {
    return reelsRepositoryInterface.toggleReelLike(reelId);
  }

  @override
  Future<bool> visitReel(int reelId) async {
    return reelsRepositoryInterface.visitReel(reelId);
  }
}
