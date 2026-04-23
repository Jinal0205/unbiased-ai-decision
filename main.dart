import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MaterialApp(home: FairnessDashboard()));

class FairnessDashboard extends StatefulWidget {
  @override
  _FairnessDashboardState createState() => _FairnessDashboardState();
}

class _FairnessDashboardState extends State<FairnessDashboard> {
  String _result = "No Audit Performed";
  double _score = 0.0;
  bool _loading = false;

  Future<void> runAudit() async {
    setState(() => _loading = true);
    // REPLACE WITH YOUR DEPLOYED CLOUD RUN URL
    final url = Uri.parse('https://fairness-service-yourid.a.run.app/analyze');
    
    try {
      final response = await http.post(url, 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "data": [
            {"protected_attr": 1, "decision": 1},
            {"protected_attr": 1, "decision": 1},
            {"protected_attr": 0, "decision": 0}, // Simulating bias
            {"protected_attr": 0, "decision": 1}
          ]
        })
      );
      final data = jsonDecode(response.body);
      setState(() {
        _score = data['disparate_impact_score'];
        _result = data['status'];
      });
    } catch (e) {
      setState(() => _result = "Error connecting to API");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SDG 10: Fairness Guardian")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Real-Time Bias Score", style: TextStyle(fontSize: 18)),
            Text("$_score", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              color: _result == "FAIR" ? Colors.green : Colors.red,
              child: Text(_result, style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 30),
            _loading ? CircularProgressIndicator() : ElevatedButton(
              onPressed: runAudit, 
              child: Text("Test Live Model Fairness")
            ),
          ],
        ),
      ),
    );
  }
}