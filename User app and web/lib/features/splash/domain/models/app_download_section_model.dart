class AppDownloadSectionModel {
  int? downloadUserAppSectionStatus;
  String? downloadUserAppTitle;
  DownloadUserAppLinks? downloadUserAppLinks;

  AppDownloadSectionModel({
    this.downloadUserAppSectionStatus,
    this.downloadUserAppTitle,
    this.downloadUserAppLinks,
  });

  AppDownloadSectionModel.fromJson(Map<String, dynamic> json) {
    downloadUserAppSectionStatus = int.tryParse(json['download_user_app_section_status']?.toString() ?? '0');
    downloadUserAppTitle = json['download_user_app_title'];
    downloadUserAppLinks = json['download_user_app_links'] != null ? DownloadUserAppLinks.fromJson(json['download_user_app_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['download_user_app_section_status'] = downloadUserAppSectionStatus;
    data['download_user_app_title'] = downloadUserAppTitle;
    if(downloadUserAppLinks != null) {
      data['download_user_app_links'] = downloadUserAppLinks!.toJson();
    }
    return data;
  }
}

class DownloadUserAppLinks {
  String? playstoreUrl;
  String? appleStoreUrl;

  DownloadUserAppLinks({
    this.playstoreUrl,
    this.appleStoreUrl,
  });

  DownloadUserAppLinks.fromJson(Map<String, dynamic> json) {
    playstoreUrl = json['playstore_url'];
    appleStoreUrl = json['apple_store_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['playstore_url'] = playstoreUrl;
    data['apple_store_url'] = appleStoreUrl;
    return data;
  }
}
