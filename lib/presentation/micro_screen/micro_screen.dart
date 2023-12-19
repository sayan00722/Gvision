import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sayan_s_application11/core/app_export.dart';
import 'package:sayan_s_application11/widgets/custom_elevated_button.dart';
import 'package:sayan_s_application11/widgets/custom_icon_button.dart';

class MicroScreen extends StatelessWidget {
  final File imageFile;

  const MicroScreen({Key? key, required this.imageFile}) : super(key: key);

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
          image: FileImage(imageFile),
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
    );
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
