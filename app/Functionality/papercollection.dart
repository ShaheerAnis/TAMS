
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:idms_fyp_app/Home.dart';
import 'package:idms_fyp_app/login_page.dart';


enum CollectionStatus { Collected, Not_Collected }

var paperId;

class PaperCollection extends StatefulWidget {
  static const String routeName = '/paperCollection';
  final String email;
  PaperCollection({required this.email});

  @override
  State<PaperCollection> createState() => _PaperCollectionState();
}



class _PaperCollectionState extends State<PaperCollection> {
  List<Map<String, dynamic>> records = [];
  List<dynamic> sessions = [];
  CollectionStatus? _collectionStatus = CollectionStatus.Not_Collected;

  @override
  void initState() {
    super.initState();
    getPaperCollectiondata();
  }

  Future<Map<String, dynamic>> fetchSession(String email) async {
    final response = await http.get(Uri.parse('http://device-ip:3001/getsession?email=$email'));
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print(response.body);
      final sessionData = List<int>.from(responseData['sessionData']);
      print(sessionData);
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final session = sessionData.firstWhere(
            (s) => s <= currentTime,
        orElse: () => 0,
      );
      print('Returned session from fetchSession(): $session');
      return {'currentSession': session};
    } else {
      throw Exception('Failed to fetch session data');
    }
  }


  Future<List<int>> getSession(String sessionData) async {
    final response = await http.get(Uri.parse(
        'http://device-ip:3001/getsession?session=$sessionData'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['sessionData'] as List<dynamic>;
      return data.cast<int>();
    } else {
      throw Exception('Failed to get session data');
    }
  }


  Future<Map<String,dynamic>> fetchPaperCollectionData(String email) async {
    final url = Uri.parse('http://device-ip:3001/getpapercollectionrecord?email=$email');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  Future<void> getPaperCollectiondata() async {
    try {
      final sessionData = await fetchSession(widget.email);
      final session=sessionData['currentSession'];
      final response = await fetchPaperCollectionData(widget.email);
      final List<dynamic> data = response['data'];
      setState(() {
        records = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print(e);
    }
  }



  void sendPaperCollectionData(String paperId, String selectedStatus) async {
    final response = await http.post(
      Uri.parse('http://device-ip:3001/postpapercollectionrecord'),
      body: {
        'email': widget.email,
        'paperCollectionId': paperId,
        'status': selectedStatus
      },
    );

    if (response.statusCode == 200) {
      print('Paper collection data sent successfully');
    } else {
      print('Error sending paper collection data');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return AlertDialog(
        title: Text('No records found!'),
        content: Text('There are no records to mark attendance for today.'),
        actions: [
          TextButton(
            child: Text('Go back'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    }
    else {
      return Scaffold(
        appBar: AppBar(title: Text('Paper Collection'),
          backgroundColor: Colors.green[600],
          actions: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(15.0),
                child: Text(
                  DateFormat('d MMM').format(DateTime.now()),
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Session')),
                        DataColumn(label: Text('Room')),
                        DataColumn(label: Text('Collection Status')),
                      ],
                      rows: records.map((row) {
                        return DataRow(
                          cells: [
                            DataCell(Text(row['Session'].toString() ?? '')),
                            DataCell(Text(row['Room'] ?? '')),
                            DataCell(Text(row['Status'] ?? '')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    width: 200,
                    child: ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (BuildContext context, int index) {
                        final record = records[index];
                        final paperId = record['ID'].toString();
                        return Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Paper Collection', style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),),
                              RadioListTile<CollectionStatus>(
                                title: const Text('Collected'),
                                value: CollectionStatus.Collected,
                                groupValue: _collectionStatus,
                                activeColor: Colors.green[600],
                                onChanged: (CollectionStatus? value) {
                                  setState(() {
                                    record['Status'] = 'Collected';
                                    _collectionStatus = value;
                                  });
                                },
                              ),
                              RadioListTile<CollectionStatus>(
                                title: const Text('Not Collected'),
                                value: CollectionStatus.Not_Collected,
                                groupValue: _collectionStatus,
                                activeColor: Colors.green[600],
                                onChanged: (CollectionStatus? value) {
                                  setState(() {
                                    record['Status'] = 'Not Collected';
                                    _collectionStatus = value;
                                  });
                                },
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600]),
                                onPressed: () {
                                  if (_collectionStatus ==
                                      CollectionStatus.Collected) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                            title: Text('Are you sure?',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),),
                                            content: Text(
                                                'You are about to mark the paper status as collected.'),
                                            actions: [
                                              TextButton(
                                                child: Text('I understand',
                                                  style: TextStyle(
                                                      color: Colors.green),),
                                                onPressed: () {
                                                  sendPaperCollectionData(paperId, 'Collected');
                                                  Navigator.of(context).pop();
                                                  Navigator.pushNamedAndRemoveUntil(
                                                    context,
                                                    MyHomePage.routeName,
                                                        (route) => route.settings.name == LoginPage.routeName,
                                                    arguments: widget.email,
                                                  );
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      backgroundColor: Colors.green[600],
                                                      content: Text('Collection status marked as collected.'),
                                                      duration: Duration(seconds: 1),
                                                    ),
                                                  );
                                                },
                                              ),

                                              TextButton(
                                                child: Text('Go back',
                                                  style: TextStyle(
                                                      color: Colors.red),),
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop();
                                                },
                                              ),
                                            ],
                                          ),
                                    );
                                  } else if (_collectionStatus ==
                                      CollectionStatus.Not_Collected) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                            title: Text('Are you sure?'),
                                            content: Text(
                                                'You are about to mark the paper status as not collected. This action can not be undone.'),
                                            actions: [
                                              TextButton(
                                                child: Text('I understand',style: TextStyle(color: Colors.green[600]),),
                                                onPressed: () {
                                                  sendPaperCollectionData(
                                                      paperId, 'Not Collected');
                                                  Navigator.of(context)
                                                      .pop();
                                                  Navigator.pushNamedAndRemoveUntil(
                                                    context,
                                                    MyHomePage.routeName,
                                                        (route) => route.settings.name == LoginPage.routeName,
                                                    arguments: widget.email,
                                                  );
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      backgroundColor: Colors
                                                          .green[600],
                                                      content: Text(
                                                          'Collection status marked as not collected.'),
                                                      duration: Duration(
                                                          seconds: 1),
                                                    ),
                                                  );
                                                  Navigator.pop(context);
                                                },
                                              ),
                                              TextButton(
                                                child: Text('Go back',style: TextStyle(color: Colors.red),),
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop();
                                                },
                                              ),
                                            ],
                                          ),
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          AlertDialog(
                                            title: const Text('Missing input!'),
                                            content: SingleChildScrollView(
                                              child: ListBody(
                                                children: <Widget>[
                                                  const Text(
                                                      'Please select one of the options.'),
                                                ],
                                              ),
                                            ),
                                          ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Submit',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )

              ]
          ),
        ),

      );
    }
  }
}




