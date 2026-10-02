import 'package:prak3_1/prak3.dart' as prak3;
import 'dart:io';

void main(List<String> arguments) {
  int a = 10;
  int b = 20;
  print(a == b);
  print(identical(a, b));

  String nama1 = 'Rakagali';
  String nama2 = 'rakagali';
  print(nama1 == nama2);
  print(identical(nama1, nama2));
}