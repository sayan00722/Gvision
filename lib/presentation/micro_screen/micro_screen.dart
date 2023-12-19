import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sayan_s_application11/core/app_export.dart';
import 'package:sayan_s_application11/widgets/custom_elevated_button.dart';
import 'package:sayan_s_application11/widgets/custom_icon_button.dart';

class MicroScreen extends StatefulWidget {
  final File imageFile;

  const MicroScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  State<MicroScreen> createState() => _MicroScreenState();
}

class _MicroScreenState extends State<MicroScreen> {
  Future<void> uploadImage(File imageFile) async {
    // Replace 'YOUR_FLASK_API_ENDPOINT' with your actual Flask API endpoint
    var apiUrl = Uri.parse('http://192.168.84.9:5000/grain_char');

    // Create a multipart request using http.MultipartRequest
    var request = http.MultipartRequest('POST', apiUrl);

    // Add the image file to the request as a file field named 'image'
    var image = await http.MultipartFile.fromPath('image', imageFile.path);
    request.files.add(image);

    // Send the request
    try {
      var response = await request.send();

      // Check if the request is successful (status code 200)
      if (response.statusCode == 200) {
        // Handle the successful response
        print('Image uploaded successfully!');
      } else {
        // Handle other status codes if needed
        print('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any error that occurred during the HTTP request
      print('Error uploading image: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    mediaQueryData = MediaQuery.of(context);
    return SafeArea(
      child: Scaffold(
        body: SizedBox(
          width: double.maxFinite,
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: 23.h, vertical: 32.v),
            decoration: AppDecoration.fillBlack.copyWith(
              image: DecorationImage(
                image: AssetImage(ImageConstant.imgScanPage),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomIconButton(
                  height: 60.adaptSize,
                  width: 60.adaptSize,
                  padding: EdgeInsets.all(14.h),
                  alignment: Alignment.centerLeft,
                  onTap: () {
                    onTapBtnArrowLeft(context);
                  },
                  child: CustomImageView(imagePath: ImageConstant.imgArrowLeft),
                ),
                Spacer(),
                _buildPreviewImage(context),
                SizedBox(height: 29.v),
                _buildGrainDetails(context),
                SizedBox(height: 24.v),
                _buildRoundness(context),
                SizedBox(height: 37.v),
                _buildCompactness(context),
                SizedBox(
                    height: 24.v), // Adjusted spacing for the Sorting button
                _buildSorting(context),
                SizedBox(
                    height: 65.v), // Adjusted spacing after the Sorting button
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewImage(BuildContext context) {
    return Container(
      width: mediaQueryData.size.width - 48.h,
      height: mediaQueryData.size.height * 0.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.h),
        image: DecorationImage(
          image: FileImage(widget.imageFile),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildGrainDetails(BuildContext context) {
    return CustomElevatedButton(
        width: 159.h,
        text: "Grain Details",
        margin: EdgeInsets.only(right: 96.h),
        onPressed: () {
          uploadImage(widget.imageFile);
        });
  }

  Widget _buildRoundness(BuildContext context) {
    return CustomElevatedButton(
      width: 159.h,
      text: "Roundness",
      margin: EdgeInsets.only(right: 96.h),
    );
  }

  Widget _buildCompactness(BuildContext context) {
    return CustomElevatedButton(
      width: 159.h,
      text: "Compactness",
      margin: EdgeInsets.only(right: 96.h),
    );
  }

  Widget _buildSorting(BuildContext context) {
    return CustomElevatedButton(
      width: 159.h,
      text: "Sorting",
      margin: EdgeInsets.only(right: 96.h),
    );
  }

  onTapBtnArrowLeft(BuildContext context) {
    Navigator.pop(context);
  }
}
