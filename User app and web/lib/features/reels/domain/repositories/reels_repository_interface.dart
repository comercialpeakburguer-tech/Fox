import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/reels/domain/models/reel_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class ReelsRepositoryInterface extends RepositoryInterface {
  @override
  Future<ReelListModel?> getList({int? offset, int? limit, DataSourceEnum source = DataSourceEnum.local});

  Future<ReelStatsModel?> getReelStats(int reelId);

  Future<ReelLikeResponseModel> toggleReelLike(int reelId);

  Future<bool> visitReel(int reelId);
}

class ReelLikeResponseModel {
  final ResponseModel response;
  final bool? isLiked;
  final int? totalLikes;

  ReelLikeResponseModel({required this.response, this.isLiked, this.totalLikes});
}
