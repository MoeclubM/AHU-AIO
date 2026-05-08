class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = '登录已过期，请重新登录']);

  @override
  String toString() => message;
}
