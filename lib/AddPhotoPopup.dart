import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class AddPhotoPopup extends StatefulWidget {
  final Function(Photo) onPhotoAdded;
  const AddPhotoPopup({Key? key, required this.onPhotoAdded}) : super(key: key);

  @override
  _AddPhotoPopupState createState() => _AddPhotoPopupState();
}

class _AddPhotoPopupState extends State<AddPhotoPopup> {
  final TextEditingController _photographerController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320.0,
        height: 300.0,
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Add photo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _photographerController,
                label: 'Photographer Name:',
                hintText: 'Enter Photographer Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Photographer name is required';
                  }
                  if (value.contains(RegExp(r'[0-9]'))) {
                    return 'Photographer name should not contain numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _imageUrlController,
                label: 'Image URL:',
                hintText: 'Enter Image URL',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Image URL is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description:',
                hintText: 'Enter Description',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 100,
                    height: 30.46,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.orange),
                      ),
                      child: const Text('CANCEL', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 30.46,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _submitted = true;
                        });
                        if (_formKey.currentState!.validate()) {
                          String? photographerName = _photographerController.text;
                          String? imageUrl = _imageUrlController.text;
                          String? description = _descriptionController.text;

                          if (photographerName != null && imageUrl != null && description != null) {
                            Photo photo = Photo(
                              name: photographerName,
                              description: description,
                              imageURL: imageUrl,
                              createdDate: Timestamp.now(),
                              id: '',
                              isLiked: false,
                            );

                            FirebaseService.addPhoto(photo).then((_) {
                              widget.onPhotoAdded(photo);
                              Navigator.of(context).pop();
                            });
                          }
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.orange),
                      ),
                      child: const Text('ADD', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    String? errorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 140.0,
              height: 20.0,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                height: 35.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3.0),
                  border: Border.all(
                    color: const Color(0xFFE5E5E5),
                  ),
                ),
                child: TextFormField(
                  controller: controller,
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFFE5E5E5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
                    isCollapsed: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (_submitted) {
                        errorMessage = validator != null ? validator(value) : null;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    if (validator != null && _submitted) {
                      return validator(value);
                    }
                    return null;
                  },
                ),
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
