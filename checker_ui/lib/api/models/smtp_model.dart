class SMTPModel {
  final String host;
  final int port;
  final String username;
  final String password;
  bool? isValid;
  String? error;

  SMTPModel({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    this.isValid,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'username': username,
    'password': password,
  };
}