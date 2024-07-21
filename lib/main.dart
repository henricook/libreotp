import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:otp/otp.dart';
import 'package:faker/faker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> jsonData = await readJsonFile();
  runApp(LibreOTPApp(jsonData));
}

class LibreOTPApp extends StatelessWidget {
  final Map<String, dynamic> jsonData;

  LibreOTPApp(this.jsonData);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LibreOTP v0.1',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Dashboard(jsonData: jsonData),
    );
  }
}

class Dashboard extends StatefulWidget {
  final Map<String, dynamic> jsonData;
  final bool demoMode;

  const Dashboard({super.key, required this.jsonData, this.demoMode = true});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _sortAscending = true;
  late Map<String, List<Map<String, dynamic>>> _originalGroupedData;
  late Map<String, List<Map<String, dynamic>>> _filteredGroupedData;
  late Map<String, String> _groupNames;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, Timer?> _timers = {};
  bool _showNotification = false;
  late String _dataDirectory;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_updateSearchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timers.values.forEach((timer) => timer?.cancel());
    super.dispose();
  }

  void _initializeData() async {
    Map<String, dynamic> data = widget.jsonData;

    if (widget.demoMode) {
      data = _applyDemoMode(data);
    }

    _originalGroupedData = _groupByGroupId(data);
    _filteredGroupedData = Map.from(_originalGroupedData);
    _groupNames = _getGroupNames(data);

    _dataDirectory = (await getApplicationDocumentsDirectory()).path;
  }

  Map<String, dynamic> _applyDemoMode(Map<String, dynamic> data) {
    final faker = Faker();
    final services = List<Map<String, dynamic>>.from(data['services']);
    final groups = List<Map<String, dynamic>>.from(data['groups']);

    for (var group in groups) {
      group['name'] = faker.food.dish();
    }

    for (var service in services) {
      service['name'] = faker.person.name();
      service['otp'] ??= {};
      service['otp']['account'] = faker.internet.email();
      service['otp']['issuer'] = 'XXXX';
    }

    return {
      'services': services,
      'groups': groups,
    };
  }

  void _updateSearchQuery() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredGroupedData = _filterData(_originalGroupedData, _searchQuery);
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupByGroupId(Map<String, dynamic> jsonData) {
    List<Map<String, dynamic>> services = List<Map<String, dynamic>>.from(jsonData['services']);
    List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonData['groups']);

    Map<String, List<Map<String, dynamic>>> groupedData = {};

    for (var group in groups) {
      String groupId = group['id'];
      groupedData[groupId] = services.where((service) => service['groupId'] == groupId).toList()
        ..sort((a, b) => (a['order']['position'] ?? 0).compareTo(b['order']['position'] ?? 0));
    }

    // Add ungrouped services to a synthetic group
    groupedData['Ungrouped'] = services.where((service) => service['groupId'] == null).toList()
      ..sort((a, b) => (a['order']['position'] ?? 0).compareTo(b['order']['position'] ?? 0));

    return groupedData;
  }

  Map<String, String> _getGroupNames(Map<String, dynamic> jsonData) {
    List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonData['groups']);

    Map<String, String> groupNames = {};

    for (var group in groups) {
      groupNames[group['id']] = group['name'];
    }

    // Add synthetic "Ungrouped" group name
    groupNames['Ungrouped'] = 'Ungrouped';

    return groupNames;
  }

  Map<String, List<Map<String, dynamic>>> _filterData(Map<String, List<Map<String, dynamic>>> data, String query) {
    if (query.isEmpty) {
      return Map.from(data);
    }
    Map<String, List<Map<String, dynamic>>> filteredData = {};
    data.forEach((groupId, services) {
      List<Map<String, dynamic>> filteredServices = services.where((service) {
        return (service['name'] ?? '').toLowerCase().contains(query) ||
            (service['otp']?['account'] ?? '').toLowerCase().contains(query) ||
            (service['otp']?['issuer'] ?? '').toLowerCase().contains(query);
      }).toList();
      if (filteredServices.isNotEmpty) {
        filteredData[groupId] = filteredServices;
      }
    });
    return filteredData;
  }

  void _sort<T>(Comparable<T> Function(Map<String, dynamic> row) getField, bool ascending) {
    setState(() {
      _filteredGroupedData.forEach((key, value) {
        value.sort((a, b) {
          if (!ascending) {
            final Map<String, dynamic> c = a;
            a = b;
            b = c;
          }
          final Comparable<T> aValue = getField(a);
          final Comparable<T> bValue = getField(b);
          return Comparable.compare(aValue, bValue);
        });
      });
      _sortAscending = ascending;
    });
  }

  void _updateRow(String groupId, int index) {
    final service = _filteredGroupedData[groupId]![index];
    final String secret = service['secret'];
    final int length = int.parse(service['otp']?['digits']?.toString() ?? "6");
    final int interval = service['otp']?['period'] ?? 30; // Default period to 30 seconds if not provided

    final String algorithmStr = service['otp']?['algorithm'] ?? "SHA1";
    Algorithm algorithm;
    switch (algorithmStr.toUpperCase()) {
      case 'SHA256':
        algorithm = Algorithm.SHA256;
        break;
      case 'SHA512':
        algorithm = Algorithm.SHA512;
        break;
      case 'SHA1':
      default:
        algorithm = Algorithm.SHA1;
    }

    // Use UTC time for TOTP generation
    final int currentTimeMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
    final int currentTimeSeconds = currentTimeMillis ~/ 1000;
    final int timeRemaining = interval - (currentTimeSeconds % interval);
    final String newCode = OTP.generateTOTPCodeString(
      secret,
      currentTimeMillis,
      length: length,
      algorithm: algorithm,
      interval: interval,
      isGoogle: true, // Ensures correct handling of base32 secrets
    );

    setState(() {
      service['otp_code'] = newCode;
      service['validity'] = '${timeRemaining}s';
    });

    Clipboard.setData(ClipboardData(text: service['otp_code']));
    setState(() {
      _showNotification = true;
    });
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showNotification = false;
      });
    });

    _timers['$groupId-$index']?.cancel();
    _timers['$groupId-$index'] = Timer.periodic(Duration(seconds: 1), (timer) {
      final secondsLeft = int.tryParse(service['validity']?.replaceAll('s', '') ?? '0') ?? 0;
      if (secondsLeft > 1) {
        setState(() {
          service['validity'] = '${secondsLeft - 1}s';
        });
      } else {
        setState(() {
          service['otp_code'] = '';
          service['validity'] = '';
        });
        timer.cancel();
      }
    });
  }

  List<DataColumn> _buildColumns() {
    return const <DataColumn>[
      DataColumn(
        label: Expanded(
          child: Text(
            'Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      DataColumn(
        label: Expanded(
          child: Text(
            'Account',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      DataColumn(
        label: Text(
          'Issuer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: Text(
          'OTP Value',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: Text(
          'Validity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }

  DataRow _buildGroupRow(String groupName) {
    return DataRow(
      color: MaterialStateProperty.all(Colors.grey.shade200),
      cells: [
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              groupName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          placeholder: true,
        ),
        DataCell.empty,
        DataCell.empty,
        DataCell.empty,
        DataCell.empty,
      ],
    );
  }

  void _showDataDirectory(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Data Directory'),
          content: Text('Path to the Documents folder:\n\n$_dataDirectory'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About LibreOTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LibreOTP v0.1'),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: 'https://github.com/henricook/libreotp')),
                child: Text(
                  'https://github.com/henricook/libreotp',
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('LibreOTP v0.1'),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.folder_open),
                        title: Text('Show Data Directory'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _showDataDirectory(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.info),
                        title: Text('About'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _showAboutDialog(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (_filteredGroupedData == null || _groupNames == null) {
            return Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        border: const OutlineInputBorder(),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _updateSearchQuery();
                          },
                        )
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.all(8.0), // Reduced padding
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            showCheckboxColumn: false, // Hides the checkboxes
                            sortAscending: _sortAscending,
                            sortColumnIndex: 1, // The index of the column to sort by (in this case, account)
                            columns: _buildColumns(),
                            rows: _filteredGroupedData.entries.expand((entry) {
                              String groupName = _groupNames[entry.key] ?? 'Unknown Group';
                              return [
                                _buildGroupRow(groupName),
                                ...entry.value.map((service) => DataRow(
                                  cells: <DataCell>[
                                    DataCell(
                                      Container(
                                        width: constraints.maxWidth * 0.25, // Adjust width for Name column
                                        child: Text(service['name'] ?? ''),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        width: constraints.maxWidth * 0.25, // Adjust width for Account column
                                        child: Text(service['otp']?['account'] ?? ''),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        width: constraints.maxWidth * 0.1, // Adjust width for Issuer column
                                        child: Text(service['otp']?['issuer'] ?? ''),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        width: constraints.maxWidth * 0.1, // Adjust width for OTP Value column
                                        child: Text(service['otp_code'] ?? ''),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        width: constraints.maxWidth * 0.05, // Adjust width for Validity column
                                        child: Text(service['validity'] ?? ''),
                                      ),
                                    ),
                                  ],
                                  onSelectChanged: (bool? selected) {
                                    if (selected == true) {
                                      _updateRow(entry.key, entry.value.indexOf(service));
                                    }
                                  },
                                ))
                              ];
                            }).toList(),
                            dataRowHeight: 28.0, // Reduced row height
                            headingRowHeight: 40.0, // Header row height
                            dividerThickness: 0.5, // Thinner divider
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showNotification)
                Positioned(
                  bottom: constraints.maxHeight * 0.05,
                  left: constraints.maxWidth * 0.25,
                  right: constraints.maxWidth * 0.25,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'OTP Code Copied to Clipboard!',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path + '/LibreOTP';
}

Future<File> get _localFile async {
  final path = await _localPath;
  debugPrint('Path = ' + path);
  return File('$path/data.json');
}

Future<Map<String, dynamic>> readJsonFile() async {
  try {
    final file = await _localFile;
    if (await file.exists()) {
      String contents = await file.readAsString();
      return jsonDecode(contents);
    } else {
      // Handle the case where the file does not exist
      return {'services': [], 'groups': []};
    }
  } catch (e) {
    // Handle errors
    return {'services': [], 'groups': []};
  }
}

Future<void> writeJsonFile(Map<String, dynamic> jsonData) async {
  final file = await _localFile;
  await file.writeAsString(jsonEncode(jsonData));
}
