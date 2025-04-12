import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/models/smtp_model.dart';
import '../api/smtp_service.dart';

class BatchCheckScreen extends StatefulWidget {
  @override
  _BatchCheckScreenState createState() => _BatchCheckScreenState();
}

class _BatchCheckScreenState extends State<BatchCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  List<SMTPModel> _smtpList = [];
  int _validCount = 0;
  int _invalidCount = 0;
  final _threadsController = TextEditingController(text: '5');

  Future<void> _parseSMTPList(String text) async {
    final lines = text.split('\n');
    setState(() {
      _smtpList = lines.where((line) => line.trim().isNotEmpty).map((line) {
        final parts = line.split('|');
        return SMTPModel(
          host: parts[0].trim(),
          port: int.tryParse(parts[1].trim()) ?? 587,
          username: parts[2].trim(),
          password: parts[3].trim(),
        );
      }).toList();
    });
  }

  Future<void> _checkBatch() async {
    if (_smtpList.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _validCount = 0;
      _invalidCount = 0;
    });

    try {
      final result = await SMTPService.checkBatchSMTP(
        smtpList: _smtpList.map((e) => e.toJson()).toList(),
        threads: int.tryParse(_threadsController.text) ?? 5,
      );

      setState(() {
        _validCount = result['valid_count'];
        _invalidCount = result['invalid_count'];
      });

      // Update individual SMTP status
      for (var valid in result['results']['valid']) {
        final index = _smtpList.indexWhere((s) => 
          s.host == valid['host'] && s.username == valid['username']);
        if (index != -1) {
          _smtpList[index].isValid = true;
        }
      }

      for (var invalid in result['results']['invalid']) {
        final index = _smtpList.indexWhere((s) => 
          s.host == invalid['host'] && s.username == invalid['username']);
        if (index != -1) {
          _smtpList[index].isValid = false;
          _smtpList[index].error = invalid['error'];
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Batch SMTP Checker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Enter SMTP list (host|port|user|pass)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  onChanged: _parseSMTPList,
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _threadsController,
                      decoration: InputDecoration(labelText: 'Threads'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Total: ${_smtpList.length}'),
                ],
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _checkBatch,
                      child: Text('Check ${_smtpList.length} SMTPs'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Chip(
                    label: Text('Valid: $_validCount'),
                    backgroundColor: Colors.green[100],
                  ),
                  Chip(
                    label: Text('Invalid: $_invalidCount'),
                    backgroundColor: Colors.red[100],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _smtpList.length,
                  itemBuilder: (context, index) {
                    final smtp = _smtpList[index];
                    return Card(
                      color: smtp.isValid == null 
                          ? null 
                          : (smtp.isValid! ? Colors.green[50] : Colors.red[50]),
                      child: ListTile(
                        title: Text(smtp.host),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${smtp.username}@${smtp.host}:${smtp.port}'),
                            if (smtp.error != null)
                              Text(smtp.error!, style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        trailing: smtp.isValid == null
                            ? null
                            : Icon(
                                smtp.isValid! ? Icons.check : Icons.close,
                                color: smtp.isValid! ? Colors.green : Colors.red,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}