import 'dart:io';
import 'dart:typed_data';

import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:propertease_admin/providers/property_reservation_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class RenterReservationReportScreen extends StatefulWidget {
  const RenterReservationReportScreen({super.key});

  @override
  State<StatefulWidget> createState() => RenterReservationReportScreenState();
}

class RenterReservationReportScreenState
    extends State<RenterReservationReportScreen> {
  late PropertyReservationProvider _reservationProvider;
  late UserProvider _userProvider;
  List<ApplicationUser>? users;
  List<PropertyReservation>? reservations;
  DateTime? selectedDateStart = DateTime.now();
  DateTime? selectedDateEnd = DateTime.now();
  String? formattedStartDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? formattedEndDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  ApplicationUser? _selectedUser;
  int? userId;
  int? selectedId;
  String? firstName;
  String? lastName;
  int? roleId;
  PDFDocument? pdfDocument;
  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = int.tryParse(prefs.getString('userId')!)!;
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');
      roleId = prefs.getInt('roleId')!;

      print(userId);
    });
  }

  double getReservationsPriceSum() {
    return reservations!.fold(0, (sum, element) => sum + element.totalPrice!);
  }

  double getReservationsPriceAverage() {
    if (reservations == null || reservations!.isEmpty) {
      return 0; // Handle the case where there are no reservations or reservations is null to avoid division by zero.
    }

    double sum =
        reservations!.fold(0.0, (sum, element) => sum + element.totalPrice!);
    return sum / reservations!.length;
  }

  Future<Uint8List> generatePDF() async {
    final pdf = pw.Document();

    if (reservations != null) {
      // Add "Renter: $firstName $lastName" and "Date created: ${DateTime.now()}" as text
      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                pw.Text("Renter Reservation Report",
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ]),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Reservations from: $formattedStartDate",
                      style: pw.TextStyle(fontSize: 12)),
                  pw.Text("Reservations to: $formattedEndDate",
                      style: pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      "Renter: ${_selectedUser?.person?.firstName} ${_selectedUser?.person?.lastName}",
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      "Date created: ${DateFormat('MM-dd-yyyy').format(DateTime.now())}",
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'Renter',
                  'Client',
                  'Reservation',
                  'Total Price',
                  'Payment Date',
                  'Property Name',
                  'Rent Type',
                ],
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.blue),
                cellStyle: const pw.TextStyle(fontSize: 12),
                data: reservations!
                    .map((reservation) => [
                          ("${_selectedUser?.person?.firstName} ${_selectedUser?.person?.lastName}"),
                          ("${reservation.client?.person?.firstName} ${reservation.client?.person?.lastName}"),
                          reservation.reservationNumber.toString(),
                          ("${reservation.totalPrice} BAM"),
                          (DateFormat('MM-dd-yyyy')
                              .format(reservation.dateOfOccupancyStart!)),
                          reservation.property?.name,
                          reservation.isDaily! ? 'Daily' : 'Monthly',
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Column(children: [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Number of Reservations:",
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text("${reservations!.length}",
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Total Price:",
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text("${getReservationsPriceSum()} BAM",
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Average Reservation Price:",
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text("${getReservationsPriceAverage()} BAM",
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
              ]),
            ];
          },
        ),
      );

      // Generate the PDF as bytes
      final pdfBytes = await pdf.save();

      return pdfBytes;
    } else {
      return Uint8List(
          0); // Return an empty byte array in case of data fetching failure
    }
  }

  void showSnackBar(BuildContext context, String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8), // Adjust the duration as needed
        action: SnackBarAction(
          label: 'Close',
          onPressed: scaffoldMessenger.hideCurrentSnackBar,
        ),
      ),
    );
  }

  _fetchReservations() async {
    var fetchedReservations = await _reservationProvider.getFiltered(filter: {
      'renterId': selectedId,
      'dateOccupancyStartedStart': selectedDateStart,
      'dateOccupancyStartedEnd': selectedDateEnd,
    });
    setState(() {
      reservations = fetchedReservations.result;
    });
  }

  Future<void> _setInitialUser(int id) async {
    try {
      var fetchedUser = await _userProvider.GetEmployeeById(id);

      setState(() {
        _selectedUser = fetchedUser;
        selectedId = fetchedUser.id;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  _fetchUsers() async {
    var fetchedUsers = await _userProvider.getEmployees();

    setState(() {
      users = fetchedUsers;
      _selectedUser = users?.firstWhere((user) => user.id == userId);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _reservationProvider = context.read<PropertyReservationProvider>();
    _userProvider = context.read<UserProvider>();

    _fetchUsers();
    getUserIdFromSharedPreferences();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _reservationProvider = context.read<PropertyReservationProvider>();
    _userProvider = context.read<UserProvider>();

    _fetchUsers();
    getUserIdFromSharedPreferences();
  }

  Future<void> _selectDateStart(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != DateTime.now()) {
      selectedDateStart = picked;

      formattedStartDate = DateFormat('yyyy-MM-dd').format(selectedDateStart!);
      _fetchReservations();
    }
  }

  Future<void> _selectDateEnd(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != DateTime.now()) {
      selectedDateEnd = picked;
      formattedEndDate = DateFormat('yyyy-MM-dd').format(selectedDateEnd!);
      _fetchReservations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'User: $firstName $lastName',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            "Reservation Report",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        _selectDateStart(context);
                                      },
                                      child: const Text('Reservation start'),
                                    ),
                                    const Text(
                                      'Start Date:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      formattedStartDate!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Column(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        _selectDateEnd(context);
                                      },
                                      child: const Text('Reservation end'),
                                    ),
                                    const Text(
                                      'End Date:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      formattedEndDate!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              var fetchedUser =
                                  await _userProvider.GetEmployeeById(userId!);

                              setState(() {
                                selectedId = userId;
                                _selectedUser = users?.firstWhere(
                                  (user) => user.id == userId,
                                );
                              });
                              await _fetchReservations();
                              final pdfBytes = await generatePDF();
                              if (pdfBytes.isNotEmpty) {
                                try {
                                  final directory =
                                      await getApplicationDocumentsDirectory();
                                  final fileName =
                                      '${_selectedUser?.person?.firstName}_report_${DateFormat('MM_dd_yyyy_hh_mm').format(DateTime.now())}.pdf';
                                  final file =
                                      File('${directory.path}/$fileName');

                                  await file.writeAsBytes(pdfBytes);

                                  showSnackBar(context,
                                      "File downloaded successfully at ${directory.path}");

                                  // Load the PDF for preview
                                  final document =
                                      await PDFDocument.fromFile(file);
                                  setState(() {
                                    pdfDocument = document;
                                  });
                                } catch (e) {
                                  // Handle errors, e.g., permission issues
                                  print('Error: $e');
                                }
                              }
                            },
                            icon: Icon(Icons.download), // Add the icon here
                            label: Text('Download Report'),
                          ),
                          if (pdfDocument != null)
                            PDFViewer(document: pdfDocument!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (roleId == 1)
                Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'User: ${_selectedUser?.person?.firstName} ${_selectedUser?.person?.lastName} ',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              "Reservation Report",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Column(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          _selectDateStart(context);
                                        },
                                        child: const Text('Reservation start'),
                                      ),
                                      const Text(
                                        'Start Date:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        formattedStartDate!,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Column(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          _selectDateEnd(context);
                                        },
                                        child: const Text('Reservation end'),
                                      ),
                                      const Text(
                                        'End Date:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        formattedEndDate!,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width:
                                            400, // Replace with your desired width
                                        child: DropdownButtonFormField<
                                            ApplicationUser?>(
                                          value: _selectedUser,
                                          onChanged:
                                              (ApplicationUser? newValue) {
                                            setState(() {
                                              _selectedUser = newValue;
                                              selectedId = newValue?.id;
                                            });
                                          },
                                          items: (users ?? []).map<
                                              DropdownMenuItem<
                                                  ApplicationUser?>>(
                                            (ApplicationUser? user) {
                                              if (user != null) {
                                                return DropdownMenuItem<
                                                    ApplicationUser?>(
                                                  value: user,
                                                  child: Text(
                                                      "${user.person?.firstName} ${user.person?.lastName}"),
                                                );
                                              } else {
                                                return const DropdownMenuItem<
                                                    ApplicationUser?>(
                                                  value: null,
                                                  child: Text('Undefined'),
                                                );
                                              }
                                            },
                                          ).toList(),
                                          decoration: const InputDecoration(
                                            labelText: 'Renter',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () async {
                                setState(() {
                                  selectedId = _selectedUser!.id;
                                });
                                await _fetchReservations();
                                final pdfBytes = await generatePDF();
                                if (pdfBytes.isNotEmpty) {
                                  try {
                                    final directory =
                                        await getApplicationDocumentsDirectory();
                                    final fileName =
                                        '${_selectedUser?.person?.firstName}_report_${DateFormat('MM_dd_yyyy_hh_mm').format(DateTime.now())}.pdf';
                                    final file =
                                        File('${directory.path}/$fileName');

                                    await file.writeAsBytes(pdfBytes);

                                    showSnackBar(context,
                                        "File downloaded successfully at ${directory.path}");

                                    // Load the PDF for preview
                                    final document =
                                        await PDFDocument.fromFile(file);
                                    setState(() {
                                      pdfDocument = document;
                                    });
                                  } catch (e) {
                                    // Handle errors, e.g., permission issues
                                    print('Error: $e');
                                  }
                                }
                              },
                              icon: Icon(Icons.download), // Add the icon here
                              label: Text('Download Report'),
                            ),
                            if (pdfDocument != null)
                              PDFViewer(document: pdfDocument!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
