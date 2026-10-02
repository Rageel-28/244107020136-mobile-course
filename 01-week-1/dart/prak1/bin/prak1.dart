import 'package:prak1/prak1.dart' as prak1;

void main(List<String> arguments) {
  print('Hello world: ${prak1.calculate()}!');
  var name = 'raka';
  var umur = 20;
  var alamat = 'jl dieng atas';
  var tinggi = '170';
  var iseng  = umur + int.parse(tinggi);
  print('alamat $alamat');
  print('nama $name');
  print('umur $umur');
  print(iseng);
}
