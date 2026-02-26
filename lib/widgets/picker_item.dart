
import 'package:flutter/material.dart';

class PickerItem extends StatelessWidget {
  final VoidCallback pickerTap;
  final String cont;
  final Color bgColor, contColor, brdColor; 

  const PickerItem({
    super.key, 
    required this.pickerTap, 
    required this.cont, 
    required this.bgColor, 
    required this.contColor, 
    required this.brdColor
    });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pickerTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bgColor,
          border: Border.all(
            color: brdColor
          )
        ),
        child: Text(cont, style: TextStyle(
          color: contColor, 
          fontWeight: FontWeight.bold, 
          fontSize: 18),),
      ),
    );
  }
}