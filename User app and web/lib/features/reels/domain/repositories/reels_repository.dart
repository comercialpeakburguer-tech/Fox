import 'dart:convert';

import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/reels/domain/models/reel_model.dart';
import 'package:sixam_mart/features/reels/domain/repositories/reels_repository_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ReelsRepository implements ReelsRepositoryInterface {
  final ApiClient apiClient;
  ReelsRepository({required this.apiClient});

  @override
  Future<ReelListModel?> getList({int? offset, int? limit, DataSourceEnum source = DataSourceEnum.local}) async {
    final int effectiveOffset = offset ?? 1;
    final int effectiveLimit = limit ?? 10;
    final String cacheId = '${AppConstants.reelsUri}?offset=$effectiveOffset&limit=$effectiveLimit-${Get.find<SplashController>().module?.id ?? 0}';

    final Map<String, dynamic> query = <String, dynamic>{
      'offset': effectiveOffset.toString(),
      'limit': effectiveLimit.toString(),
      if(!AuthHelper.isLoggedIn()) 'guest_id': AuthHelper.getGuestId(),
    };
    final String uri = Uri.parse(AppConstants.reelsUri).replace(queryParameters: query).toString();

    switch(source) {
      case DataSourceEnum.local:
        final String? cachedResponse = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cachedResponse != null && cachedResponse.isNotEmpty) {
          return _parseReelListModel(jsonDecode(cachedResponse));
        }
        return null;

      case DataSourceEnum.client:
        final Response response = await apiClient.getData(uri);
        if(response.statusCode == 200) {
          await LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(response.body), apiClient.getHeader());
          return _parseReelListModel(response.body);
        }
        return null;
    }
  }

  @override
  Future<ReelStatsModel?> getReelStats(int reelId) async {
    // Fox GO: o backend atual expõe apenas /api/v1/reels.
    // Stats por Reel ficam desativados com retorno seguro até existir endpoint dedicado.
    return null;
  }

  @override
  Future<ReelLikeResponseModel> toggleReelLike(int reelId) async {
    // Fox GO: like de Reel ainda não possui endpoint dedicado no backend atual.
    return ReelLikeResponseModel(response: ResponseModel(false, 'not_available'));
  }

  @override
  Future<bool> visitReel(int reelId) async {
    // Fox GO: visita de Reel ainda não possui endpoint dedicado no backend atual.
    return false;
  }

  ReelListModel _parseReelListModel(dynamic responseBody) {
    if(responseBody is Map<String, dynamic>) {
      final dynamic nestedMap = responseBody['data'] ?? responseBody['content'];
      if(nestedMap is Map<String, dynamic> && _looksLikePaginatedMap(nestedMap)) {
        return ReelListModel.fromJson(nestedMap);
      }
      return ReelListModel.fromJson(responseBody);
    }

    if(responseBody is Map) {
      return _parseReelListModel(Map<String, dynamic>.from(responseBody));
    }

    if(responseBody is List) {
      return ReelListModel(
        totalSize: responseBody.length,
        offset: 1,
        limit: responseBody.length.toString(),
        reels: responseBody.map<ReelModel>((dynamic data) {
          if(data is Map<String, dynamic>) {
            return ReelModel.fromJson(data);
          }
          return ReelModel.fromJson(Map<String, dynamic>.from(data as Map));
        }).where((ReelModel reel) => reel.resolvedThumbnailUrl.isNotEmpty).toList(),
      );
    }

    return ReelListModel(reels: <ReelModel>[]);
  }

  bool _looksLikePaginatedMap(Map<String, dynamic> map) {
    return map.containsKey('total_size')
        || map.containsKey('reels')
        || (map.containsKey('data') && map['data'] is List)
        || (map.containsKey('items') && map['items'] is List);
  }

  dynamic _extractDetailObject(dynamic responseBody) {
    if(responseBody is Map<String, dynamic>) {
      final dynamic detailData = responseBody['data'] ?? responseBody['reel'] ?? responseBody['content'] ?? responseBody['item'];
      if(detailData is Map<String, dynamic>) {
        return detailData;
      }
      if(detailData is Map) {
        return Map<String, dynamic>.from(detailData);
      }
      return responseBody;
    }

    if(responseBody is Map) {
      return Map<String, dynamic>.from(responseBody);
    }

    if(responseBody is List && responseBody.isNotEmpty) {
      final dynamic firstItem = responseBody.first;
      if(firstItem is Map<String, dynamic>) {
        return firstItem;
      }
      if(firstItem is Map) {
        return Map<String, dynamic>.from(firstItem);
      }
    }

    return null;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
