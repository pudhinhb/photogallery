import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

import 'api_service.dart';
import 'AddPhotoPopup.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MainScreen(),
  ));
}

enum SortBy { CreatedTimeOldToNew, CreatedTimeNewToOld, PhotographerName, Favorites }
enum FilterBy { All, PhotographerName, Favorites }

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Stream<List<Photo>> _photoListStream;
  List<Photo> _filteredPhotos = [];
  SortBy _sortBy = SortBy.CreatedTimeOldToNew;
  FilterBy _filterBy = FilterBy.All;
  String? _selectedPhotographerName;

  @override
  void initState() {
    super.initState();
    _photoListStream = _getAllPhotos();
  }

  Stream<List<Photo>> _getAllPhotos() {
    Query query = FirebaseFirestore.instance.collection('photos');


    query = _applySortingAndFiltering(query);

    return query.snapshots().map((snapshot) {
      _filteredPhotos.clear();
      snapshot.docs.forEach((doc) {
        _filteredPhotos.add(Photo.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      });
      return _filteredPhotos;
    });
  }
 Query _applySortingAndFiltering(Query query) {
  switch (_sortBy) {
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

  switch (_filterBy) {
    case FilterBy.All:
      break;
    case FilterBy.PhotographerName:
      query = query.where('photographerName', isEqualTo: _selectedPhotographerName);
      break;
    case FilterBy.Favorites:
      query = query.where('isLiked', isEqualTo: true);
      break;
  }

  return query;
}


  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.of(context).size.width > 600 ? 5 : 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Photo Gallery',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey[850],
        actions: [
          _buildSortMenuButton(),
          _buildFilterMenuButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Photo>>(
          stream: _photoListStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              _filteredPhotos = snapshot.data!;
              return GridView.builder(
                itemCount: _filteredPhotos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return GridItem(
                    photo: _filteredPhotos[index],
                    onDelete: () {
                      _showDeleteAlert(context, _filteredPhotos[index]);
                    },
                    onLike: (bool newLikeStatus) async {
                      try {
                        await FirebaseService.updateLikeStatus(
                          _filteredPhotos[index].id!,
                          newLikeStatus,
                        );

                        setState(() {
                          List<Photo> updatedPhotos = List.from(_filteredPhotos);

                          if (newLikeStatus) {
                            updatedPhotos.insert(0, updatedPhotos.removeAt(index));
                          } else {
                            int firstUnlikedIndex = updatedPhotos.indexWhere((photo) => !photo.isLiked);
                            if (firstUnlikedIndex != -1) {
                              updatedPhotos.insert(firstUnlikedIndex, updatedPhotos.removeAt(index));
                            }
                          }

                          _filteredPhotos = updatedPhotos;
                        });
                      } catch (e) {
                        print('Error updating like status: $e');
                      }
                    },
                    onGridCellTapped: () {
                      _openFullScreenImage(context, _filteredPhotos[index]);
                    },
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openAddPhotoDialog(context);
        },
        tooltip: 'Add Photo',
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSortMenuButton() {
    return Tooltip(
      message: 'Sort',
      child: PopupMenuButton<SortBy>(
        itemBuilder: (BuildContext context) => <PopupMenuEntry<SortBy>>[
          PopupMenuItem<SortBy>(
            value: SortBy.CreatedTimeOldToNew,
            child: RadioListTile<SortBy>(
              title: const Text('By Created Time (Old to New)'),
              value: SortBy.CreatedTimeOldToNew,
              groupValue: _sortBy,
              onChanged: (SortBy? value) {
                setState(() {
                  _sortBy = value!;
                  _photoListStream = _getAllPhotos();
                });
                Navigator.pop(context);
              },
            ),
          ),
          PopupMenuItem<SortBy>(
            value: SortBy.CreatedTimeNewToOld,
            child: RadioListTile<SortBy>(
              title: const Text('By Created Time (New to Old)'),
              value: SortBy.CreatedTimeNewToOld,
              groupValue: _sortBy,
              onChanged: (SortBy? value) {
                setState(() {
                  _sortBy = value!;
                  _photoListStream = _getAllPhotos();
                });
                Navigator.pop(context);
              },
            ),
          ),
          PopupMenuItem<SortBy>(
            value: SortBy.PhotographerName,
            child: RadioListTile<SortBy>(
              title: const Text('By Photographer Name'),
              value: SortBy.PhotographerName,
              groupValue: _sortBy,
              onChanged: (SortBy? value) {
                setState(() {
                  _sortBy = value!;
                  _photoListStream = _getAllPhotos();
                });
                Navigator.pop(context);
              },
            ),
          ),
          PopupMenuItem<SortBy>(
            value: SortBy.Favorites,
            child: RadioListTile<SortBy>(
              title: const Text('By Favorites'),
              value: SortBy.Favorites,
              groupValue: _sortBy,
              onChanged: (SortBy? value) {
                setState(() {
                  _sortBy = value!;
                   _photoListStream = _getAllPhotos();
                });
                Navigator.pop(context);
              },
            ),
          ),
        ],
        icon: Icon(Icons.sort),
      ),
    );
  }

  Widget _buildFilterMenuButton() {
    return Tooltip(
      message: 'Filter',
      child: PopupMenuButton<FilterBy>(
        itemBuilder: (BuildContext context) => <PopupMenuEntry<FilterBy>>[
          const PopupMenuItem<FilterBy>(
            value: FilterBy.All,
            child: Text('All'),
          ),
          const PopupMenuItem<FilterBy>(
            value: FilterBy.PhotographerName,
            child: Text('Photographer Name'),
          ),
          const PopupMenuItem<FilterBy>(
            value: FilterBy.Favorites,
            child: Text('Favorites'),
          ),
        ],
        onSelected: (FilterBy result) {
          setState(() {
            _filterBy = result;
            if (_filterBy == FilterBy.PhotographerName) {
              _showPhotographersSubMenu(context);
            } else if (_filterBy == FilterBy.Favorites) {
              _showFavoritePhotosSubMenu(context);
            } else {
              _photoListStream = _getAllPhotos();
            }
          });
        },
        icon: Icon(Icons.filter_list),
      ),
    );
  }

  void _openAddPhotoDialog(BuildContext context) async {
    await showDialog<Photo>(
      context: context,
      builder: (BuildContext context) {
        return AddPhotoPopup(
          onPhotoAdded: (addedPhoto) {},
        );
      },
    );
  }

  void _showDeleteAlert(BuildContext context, Photo photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Container(
            width: 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Are you sure you want to delete this photo?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 35,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.orange),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseService.deletePhoto(photo.id!);
                            setState(() {
                              _filteredPhotos.remove(photo);
                            });
                            Navigator.of(context).pop(true);
                          } catch (e) {
                            print('Error deleting photo: $e');
                            Navigator.of(context).pop(false);
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.red),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          'DELETE',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFavoritePhotosSubMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter By Favorites'),
          content: Container(
            width: 180,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: Text('Liked'),
                  onTap: () {
                    setState(() {
                      _photoListStream = FirebaseService.getLikedPhotosStream(true);
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('Unliked'),
                  onTap: () {
                    setState(() {
                      _photoListStream = FirebaseService.getLikedPhotosStream(false);
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPhotographersSubMenu(BuildContext context) {
    FirebaseService.getAllPhotographerNames().then((photographerNames) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Filter By Photographer Name'),
            content: Container(
              width: 180,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var photographerName in photographerNames)
                    ListTile(
                      title: Text(photographerName ?? 'Unknown'),
                      onTap: () {
                        setState(() {
                          _photoListStream = FirebaseService.getPhotosByPhotographerStream(photographerName);
                        });
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _openFullScreenImage(BuildContext context, Photo photo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FullScreenImage(photo: photo)),
    );
  }
}

class GridItem extends StatelessWidget {
  final Photo photo;
  final VoidCallback onDelete;
  final Function(bool) onLike;
  final Function onGridCellTapped;

  const GridItem({
    Key? key,
    required this.photo,
    required this.onDelete,
    required this.onLike,
    required this.onGridCellTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onGridCellTapped();
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Stack(
            children: [
              Image.network(
                photo.imageURL ?? 'unknown',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Positioned(
                bottom: 0,
                left: -10,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDescription(photo.description),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFormattedDate(photo.createdDate),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.black.withOpacity(0.0),
                  child: Text(
                    '-by ${photo.name ?? 'Unknown'}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  onPressed: () {
                    onLike(!photo.isLiked);
                  },
                  icon: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      photo.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: photo.isLiked ? Colors.orange : Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDescription(String? description) {
    if (description != null) {
      final words = description.split(' ');
      const maxLength = 2;
      if (words.length > maxLength) {
        return '${words.sublist(0, maxLength).join(' ')}...';
      } else {
        return words.join(' ');
      }
    } else {
      return '';
    }
  }

  String _getFormattedDate(Timestamp? date) {
    if (date != null) {
      final formattedDate = DateFormat('d MMMM y').format(date.toDate());
      return formattedDate;
    } else {
      return '';
    }
  }
}

class FullScreenImage extends StatelessWidget {
  final Photo photo;

  const FullScreenImage({Key? key, required this.photo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Screen Image'),
      ),
      body: Center(
        child: Image.network(
          photo.imageURL ?? 'unknown',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
