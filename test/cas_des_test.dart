import 'package:flutter_test/flutter_test.dart';
import 'package:ahu_aio/auth/cas_des.dart';

void main() {
  test('CAS DES matches upstream login.js vectors', () {
    expect(CasDes.encrypt('1'), 'FF175F03E46ADFCE');
    expect(CasDes.encrypt('1234'), 'C1BB5938DF9F2190');
    expect(CasDes.encrypt('abcd'), 'A9CF2704230383D1');
  });
}
