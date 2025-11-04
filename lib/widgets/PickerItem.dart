
import 'package:flutter/material.dart';

class PickerItem extends StatefulWidget {
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
  State<PickerItem> createState() => _PickerItemState();
}

class _PickerItemState extends State<PickerItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.pickerTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: widget.bgColor,
          border: Border.all(
            color: widget.brdColor
          )
        ),
        child: Text(widget.cont, style: TextStyle(
          color: widget.contColor, 
          fontWeight: FontWeight.bold, 
          fontSize: 18),),
      ),
    );
  }
}