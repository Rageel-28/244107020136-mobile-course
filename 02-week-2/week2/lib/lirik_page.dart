import 'package:flutter/material.dart';

class LirikPage extends StatelessWidget {
  const LirikPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Text(
            'Anak Jaranan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),
          ),
          SizedBox(height: 4),
          Text('Lagu Anak-Anak'),
          SizedBox(height: 24),
          Text(
            'Jaranan, jaranan, jarane jaran teji\n'
            'Sing nunggang Mas Ngabehi sing ngiring para menteri\n'
            'Jrek-jrek nong, jrek-jrek gung srek-kesrek turut lurung\n',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 18, height: 2.0),
          ),
          Text(
            'Gedebuk krincing gedebuk krincing\nprok, prok gedebuk jedher\n'
            'Gedebuk krincing gedebuk krincing\nprok, prok gedebuk jedher\n',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 18, height: 2.0),
          ),
          Text(
            'Jaranan, jaranan, jarane jaran teji\n'
            'Sing nunggang Mas Ngabehi sing ngiring para menteri\n'
            'Jrek-jrek nong, jrek-jrek gung srek-kesrek turut lurung\n',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 18, height: 2.0),
          ),
          Text(
            'Gedebuk krincing gedebuk krincing\n'
            'prok, prok gedebuk jedher\n'
            'Gedebuk krincing gedebuk krincing\n'
            'prok, prok gedebuk jedher\n',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 18, height: 2.0),
          ),
        ],
      ),
    );
  }
}
