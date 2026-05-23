import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/reels/domain/models/reel_model.dart';
import 'package:sixam_mart/features/reels/domain/repositories/reels_repository_interface.dart';

abstract class ReelsServiceInterface {
  Future<ReelListModel?> getReelsList(DataSourceEnum source, {int offset = 1, int limit = 10});
  Future<ReelStatsModel?> getReelStats(int reelId);
  Future<ReelLikeResponseModel> toggleReelLike(int reelId);
  Future<bool> visitReel(int reelId);
}
