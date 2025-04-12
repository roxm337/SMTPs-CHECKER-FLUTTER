import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '/api/smtp_service.dart';

class SMTPCheckerScreen extends StatefulWidget {
  @override
  _SMTPCheckerScreenState createState() => _SMTPCheckerScreenState();
}

class _SMTPCheckerScreenState extends State<SMTPCheckerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  // Controllers
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '587');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _checkSMTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final result = await SMTPService.checkSMTP(
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text,
      );

      setState(() => _result = result);
      Fluttertoast.showToast(
        msg: result['status'] == 'success' 
            ? 'SMTP is valid!' 
            : 'SMTP check failed',
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SMTP Checker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _hostController,
                  decoration: InputDecoration(labelText: 'SMTP Host'),
                  validator: (value) => 
                      value!.isEmpty ? 'Enter SMTP host' : null,
                ),
                TextFormField(
                  controller: _portController,
                  decoration: InputDecoration(labelText: 'Port'),
                  keyboardType: TextInputType.number,
                  validator: (value) => 
                      value!.isEmpty ? 'Enter port number' : null,
                ),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                  validator: (value) => 
                      value!.isEmpty ? 'Enter username' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => 
                      value!.isEmpty ? 'Enter password' : null,
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _checkSMTP,
                        child: Text('Check SMTP'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                if (_result != null) ...[
                  SizedBox(height: 30),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Result:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _result!['status'] == 'success'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text('Host: ${_result!['data']['host']}'),
                          Text('Port: ${_result!['data']['port']}'),
                          Text('Valid: ${_result!['data']['valid']}'),
                          if (_result!['data']['error'] != null)
                            Text('Error: ${_result!['data']['error']}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}