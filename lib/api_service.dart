import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum SortBy { CreatedTimeOldToNew, CreatedTimeNewToOld, PhotographerName, Favorites }
enum FilterBy { All, PhotographerName, Favorites }

class FirebaseService {
  static final CollectionReference _photoCollection =
      FirebaseFirestore.instance.collection('photos');

  static Stream<List<Photo>> getAllPhotosStream({
    required SortBy sortBy,
    required FilterBy filterBy,
    String? selectedPhotographerName,
  }) {
    Query query = _photoCollection;
    query = _applySortingAndFiltering(query, sortBy, filterBy,
        selectedPhotographerName: selectedPhotographerName);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Photo.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  static Query _applySortingAndFiltering(
    Query query,
    SortBy sortBy,
    FilterBy filterBy, {
    String? selectedPhotographerName,
  }) {
    switch (sortBy) {
      case SortBy.CreatedTimeOldToNew:
        query = query.orderBy('createdDate', descending: false);
        break;
      case SortBy.CreatedTimeNewToOld:
        query = query.orderBy('createdDate', descending: true);
        break;
      case SortBy.PhotographerName:
        query = query.orderBy('name');
        break;
      case SortBy.Favorites:
        query = query.orderBy('isLiked', descending: true);
        break;
    }

    switch (filterBy) {
      case FilterBy.All:
        break;
      case FilterBy.PhotographerName:
        query = query.where('photographerName', isEqualTo: selectedPhotographerName);
        break;
      case FilterBy.Favorites:
        query = query.where('isLiked', isEqualTo: true);
        break;
    }

    return query;
  }

  static Future<String> addPhoto(Photo photo) async {
    try {
      DocumentReference documentReference =
          await _photoCollection.add(photo.toJson());
      String documentId = documentReference.id;
      print('Photo added successfully with ID: $documentId');
      return documentId;
    } catch (e) {
      print('Error adding photo: $e');
      throw e;
    }
  }

  static Future<void> deletePhoto(String photoId) async {
    try {
      await _photoCollection.doc(photoId).delete();
      print('Photo deleted successfully');
    } catch (e) {
      print('Error deleting photo: $e');
      throw e;
    }
  }

  static Future<void> updateLikeStatus(String photoId, bool isLiked) async {
    try {
      await _photoCollection.doc(photoId).update({'isLiked': isLiked});
      print('Like status updated successfully for photo with ID: $photoId');
    } catch (e) {
      print('Error updating like status: $e');
      throw e;
    }
  }

  static Stream<List<Photo>> getPhotosByPhotographerStream(
      String? photographerName) {
    return _photoCollection
        .where('name', isEqualTo: photographerName)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Photo.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  static Stream<List<Photo>> getAllPhotosSortedByField(String field,
      {bool descending = false}) {
    return _photoCollection
        .orderBy(field, descending: descending)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Photo.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  static Future<List<String>> getAllPhotographerNames() async {
    try {
      final QuerySnapshot querySnapshot = await _photoCollection.get();
      final List<String> photographerNames = [];
      querySnapshot.docs.forEach((doc) {
        final String? photographerName = doc['name'];
        if (photographerName != null &&
            !photographerNames.contains(photographerName)) {
          photographerNames.add(photographerName);
        }
      });
      return photographerNames;
    } catch (e) {
      print('Error fetching photographer names: $e');
      return [];
    }
  }

  static Stream<List<Photo>> getLikedPhotosStream(bool isLiked) {
    return _photoCollection
        .where('isLiked', isEqualTo: isLiked)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Photo.fromFirestore(data, doc.id);
      }).toList();
    });
  }
}

class Photo {
  final String? id;
  final String? name;
  final String? description;
  final String? imageURL;
  final Timestamp? createdDate;
  bool isLiked;

  Photo({
    this.id,
    this.name,
    this.description,
    this.imageURL,
    this.createdDate,
    this.isLiked = false,
  });

  factory Photo.fromFirestore(Map<String, dynamic> json, String id) {
    return Photo(
      id: id,
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageURL: json['imageURL'] as String?,
      createdDate: json['createdDate'] as Timestamp?,
      isLiked: json['isLiked'] is bool
          ? json['isLiked'] as bool
          : (json['isLiked'] == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    Timestamp timestamp = Timestamp.now();
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageURL': imageURL,
      'createdDate': timestamp,
      'isLiked': isLiked,
    };
  }
}
