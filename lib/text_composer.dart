import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  const TextComposer({super.key, required this.sendMessage});

  final Function({String? message, File? imgFile}) sendMessage;

  @override
  State<TextComposer> createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  TextEditingController _textController = TextEditingController();
  bool _isComposing = false;

  void _reset() {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
              onPressed: () async {
                final XFile? imgFile =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (imgFile == null) {
                  return;
                }
                File fileSend = File(imgFile.path);
                widget.sendMessage(imgFile: fileSend);
              },
              icon: Icon(Icons.photo_camera)),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration:
                  InputDecoration.collapsed(hintText: 'Enviar Messagem'),
              onChanged: (text) {
                setState(() {
                  _isComposing = text.isNotEmpty;
                });
              },
              onSubmitted: (text) {
                widget.sendMessage(message: text);
                _textController.clear();
                _reset();
              },
            ),
          ),
          IconButton(
            onPressed: _isComposing
                ? () {
                    widget.sendMessage(message: _textController.text);
                    _reset();
                  }
                : null,
            icon: Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
