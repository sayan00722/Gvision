import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sayan_s_application11/core/app_export.dart';
import 'package:sayan_s_application11/widgets/custom_elevated_button.dart';
import 'package:sayan_s_application11/widgets/custom_icon_button.dart';

class MicroOneScreen extends StatelessWidget {
  final File imageFile;

  const MicroOneScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackgroundImage(),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 23.h, vertical: 32.v),
                child: Column(
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
                      child: CustomImageView(
                          imagePath: ImageConstant.imgArrowLeft),
                    ),
                    _buildPreviewImage(context),
                    SizedBox(height: 29.v),
                    _buildGrainDetails(context),
                    SizedBox(height: 24.v),
                    _buildButtonWithMargin(context, "Spe. Gra.", 96.h),
                    SizedBox(height: 24.v),
                    _buildRoundness(context),
                    SizedBox(height: 37.v),
                    _buildButtonWithMargin(context, "Lustre", 96.h),
                    SizedBox(height: 24.v),
                    _buildCompactness(context),
                    SizedBox(height: 24.v),
                    _buildSorting(context),
                    SizedBox(
                      height: 65.v,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ImageConstant.imgScanPage),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPreviewImage(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: MediaQuery.of(context).size.height * 0.4,
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
      text: "Geo. Disc.",
      margin: EdgeInsets.only(right: 96.h),
    );
  }

  Widget _buildButtonWithMargin(
      BuildContext context, String text, double marginValue) {
    return CustomElevatedButton(
      width: 159.h,
      text: text,
      margin: EdgeInsets.only(right: marginValue),
    );
  }

  Widget _buildRoundness(BuildContext context) {
    return CustomElevatedButton(
      width: 159.h,
      text: "Texture",
      margin: EdgeInsets.only(right: 96.h),
    );
  }

  Widget _buildCompactness(BuildContext context) {
    return CustomElevatedButton(
      width: 159.h,
      text: "Lustre",
      margin: EdgeInsets.only(right: 96.h),
    );
  }

  Widget _buildSorting(BuildContext context) {
    return CustomElevatedButton(
      width: 159.h,
      text: "Colour",
      margin: EdgeInsets.only(right: 96.h),
    );
  }

  onTapBtnArrowLeft(BuildContext context) {
    Navigator.pop(context);
  }
}
