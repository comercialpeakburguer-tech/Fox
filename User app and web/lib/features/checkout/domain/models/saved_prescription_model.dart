class SavedPrescriptionModel {
  String? fileName;
  String? imageFullUrl;

  SavedPrescriptionModel({this.fileName, this.imageFullUrl});

  SavedPrescriptionModel.fromJson(Map<String, dynamic> json) {
    fileName = json['file_name'];
    imageFullUrl = json['image_full_url'];
  }

  Map<String, dynamic> toJson() {
    return {'file_name': fileName, 'image_full_url': imageFullUrl};
  }
}
