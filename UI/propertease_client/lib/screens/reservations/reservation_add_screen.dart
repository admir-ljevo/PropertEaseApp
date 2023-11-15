import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:propertease_client/models/property_reservation.dart';
import 'package:propertease_client/providers/property_reservation_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/property.dart';
import 'paypal_payment_screen.dart';

class ReservationAddScreen extends StatefulWidget {
  Property? property;
  ReservationAddScreen({super.key, this.property});

  @override
  State<StatefulWidget> createState() => ReservationAddScreenState();
}

class ReservationAddScreenState extends State<ReservationAddScreen> {
  EventList<Event> markedDatesList = EventList<Event>(events: {});
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late PropertyReservationProvider _reservationProvider;
  List<PropertyReservation>? _reservations;
  int selectedGuests = 1;
  double totalPrice = 0;
  DateTime? startDate;
  DateTime? endDate;
  Map<DateTime, List<dynamic>> markedDates = {};
  bool isLoading = true;
  bool isMonthly = false;
  bool isDaily = false;
  bool isActive = false;
  late int renterId;
  int numberOfMonths = 0;
  int numberOfDays = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void setTotalPrice() {
    if (widget.property!.isMonthly!)
      totalPrice = widget.property!.monthlyPrice! * numberOfMonths;
    if (widget.property!.isDaily!)
      totalPrice = widget.property!.dailyPrice! * numberOfDays;
    setState(() {
      _priceController.text = totalPrice.toString();
    });
  }

  int? userId;
  // Add a GlobalKey for the form
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = int.tryParse(prefs.getString('userId')!)!;
    });
  }

  Future<void> addReservation() async {
    try {
      PropertyReservation reservation = PropertyReservation();
      reservation.id = 0;
      reservation.clientId = userId;
      reservation.renterId = renterId;
      reservation.propertyId = widget.property!.id;
      reservation.totalPrice = totalPrice;
      reservation.dateOfOccupancyEnd = endDate;
      reservation.isActive = isActive;
      reservation.isMonthly = isMonthly;
      reservation.isDaily = isDaily;
      reservation.numberOfGuests = selectedGuests;
      reservation.createdAt = DateTime.now();
      reservation.modifiedAt = DateTime.now();
      reservation.dateOfOccupancyStart = startDate;
      reservation.numberOfMonths = numberOfMonths;
      reservation.numberOfDays = numberOfDays;
      reservation.description = _descriptionController.text;
      reservation.reservationNumber = "#0001";
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PayPalScreen(
            totalPrice: totalPrice,
          ),
        ),
      );
      await _reservationProvider.addAsync(reservation);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Reservation added sucessfully"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
    }
  }

  int calculateNumberOfMonths(DateTime? startDate, DateTime? endDate) {
    if (startDate != null && endDate != null) {
      int years = endDate.year - startDate.year;
      int months = endDate.month - startDate.month;
      int days = endDate.day - startDate.day - 1;

      if (days < 0) {
        months -= 1;
        days += DateTime(startDate.year, startDate.month + 1, 0).day;
      }

      int numberOfMonths = years * 12 + months + (days > 0 ? 1 : 0);
      return numberOfMonths;
    }
    return 0; // Return a default value when dates are not available
  }

  int calculateNumberOfDays(DateTime? startDate, DateTime? endDate) {
    if (startDate != null && endDate != null) {
      int numberOfDays = endDate.difference(startDate).inDays;
    }
    return numberOfDays;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime initialDate = startDate ?? currentDate;

    // Check if the initial date satisfies the selectableDayPredicate
    while (!(await _isDateSelectable(initialDate))) {
      initialDate = initialDate.add(const Duration(days: 1));
    }

    final DateTime picked = (await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: currentDate,
      lastDate: DateTime(2101),
      selectableDayPredicate: (DateTime date) {
        return _isDateSelectable(date);
      },
    ))!;

    if (picked != startDate) {
      setState(() {
        startDate = picked;
        if (widget.property!.isMonthly!)
          numberOfMonths = calculateNumberOfMonths(startDate, endDate);
        if (widget.property!.isDaily!)
          numberOfDays = calculateNumberOfDays(startDate, endDate);
        setTotalPrice();
      });
    }
  }

  bool _isDateSelectable(DateTime date) {
    // Add your logic to determine which dates should be selectable/marked
    if (_reservations != null) {
      for (final reservation in _reservations!) {
        if (date.isAfter(reservation.dateOfOccupancyStart!) &&
            date.isBefore(reservation.dateOfOccupancyEnd!)) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime startDateValue = startDate ??
        DateTime(2023); // Use the selected start date as a reference
    final DateTime minEndDate = startDateValue
        .add(const Duration(days: 30)); // Calculate the minimum end date
    final DateTime currentDate = DateTime.now();

    DateTime? initialDate =
        minEndDate.isAfter(currentDate) ? minEndDate : currentDate;

    while (!selectableDayPredicate(initialDate!, minEndDate)) {
      initialDate = initialDate.add(const Duration(days: 1));
    }

    DateTime? pickedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Container(
            width: double.maxFinite,
            child: CalendarDatePicker(
              initialDate: initialDate!,
              firstDate: minEndDate,
              lastDate: DateTime(2101),
              selectableDayPredicate: (DateTime date) {
                return selectableDayPredicate(date, minEndDate);
              },
              onDateChanged: (DateTime date) {
                pickedDate = date;
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );

    if (pickedDate != null && pickedDate != endDate) {
      setState(() {
        endDate = pickedDate;
        if (widget.property!.isMonthly!) {
          numberOfMonths = calculateNumberOfMonths(startDate, endDate);
        }
        if (widget.property!.isDaily!)
          numberOfDays = calculateNumberOfDays(startDate, endDate);
        setTotalPrice();
      });
    }
  }

  bool selectableDayPredicate(DateTime date, DateTime minEndDate) {
    return date.isAfter(minEndDate);
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _reservationProvider = context.read<PropertyReservationProvider>();
    fetchReservations();
    getUserIdFromSharedPreferences();
    isMonthly = widget.property!.isMonthly!;
    isDaily = widget.property!.isDaily!;
    isActive = true;
    renterId = widget.property!.applicationUserId!;

    _priceController.text = totalPrice.toString();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _reservationProvider = context.read<PropertyReservationProvider>();
    fetchReservations();
    getUserIdFromSharedPreferences();
    isActive = true;

    isMonthly = widget.property!.isMonthly!;
    isDaily = widget.property!.isDaily!;
    renterId = widget.property!.applicationUserId!;
    _priceController.text = totalPrice.toString();
  }

  Future<void> fetchReservations() async {
    setState(() {
      isLoading = true;
    });

    try {
      var tempReservations = await _reservationProvider
          .getFiltered(filter: {"propertyId": widget.property!.id});

      setState(() {
        _reservations = tempReservations.result;
        isLoading = false;
      });
    } catch (e) {
      print(e.toString());
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New reservation"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Property name:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.property?.name ?? '',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "City:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.property?.city?.name ?? '',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Address:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.property?.address ?? '',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16.0), // Add some spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Number of Guests:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: 100,
                    color: const Color.fromRGBO(238, 238, 238, 1),
                    child: DropdownButton<int>(
                      value: selectedGuests,
                      items: List.generate(
                        widget.property!.capacity!,
                        (index) => index + 1,
                      ).map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedGuests = newValue!;
                          print(selectedGuests);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0), // Add some spacing

              if (widget.property?.isMonthly == true)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Reservation Type:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Monthly",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              if (widget.property?.isDaily == true)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Reservation Type:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Daily",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              const SizedBox(height: 16.0), // Add some spacing

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Start Date:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    startDate != null
                        ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                        : 'Select a date',
                    style: const TextStyle(fontSize: 18),
                  ),
                  ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.blue),
                      ),
                      onPressed: () {
                        _selectStartDate(context);
                      },
                      child: const Row(
                        children: [
                          Text(
                            "Pick a date",
                            style: TextStyle(color: Colors.white),
                          ),
                          Icon(
                            Icons.date_range,
                            color: Colors.white,
                            size: 22,
                          )
                        ],
                      )),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "End Date:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    endDate != null
                        ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
                        : 'Select a date',
                    style: const TextStyle(fontSize: 18),
                  ),
                  ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.blue),
                      ),
                      onPressed: startDate != null
                          ? () => _selectEndDate(context)
                          : null,
                      child: const Row(
                        children: [
                          Text(
                            "Pick a date",
                            style: TextStyle(color: Colors.white),
                          ),
                          Icon(
                            Icons.date_range,
                            color: Colors.white,
                            size: 22,
                          )
                        ],
                      )),
                ],
              ),
              if (widget.property!.isMonthly!)
                TextField(
                    enabled: false,
                    decoration: const InputDecoration(
                      labelStyle: TextStyle(color: Colors.black, fontSize: 22),
                      labelText: 'Monthly price (BAM)',
                    ),
                    controller: TextEditingController(
                        text: widget.property!.monthlyPrice.toString() ?? ''),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                    )),
              if (widget.property!.isDaily!)
                TextField(
                    enabled: false,
                    decoration: const InputDecoration(
                      labelStyle: TextStyle(color: Colors.black, fontSize: 22),
                      labelText: 'Daily price (BAM)',
                    ),
                    controller: TextEditingController(
                        text: widget.property!.dailyPrice.toString() ?? ''),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                    )),
              TextField(
                  enabled: false,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(color: Colors.black, fontSize: 22),
                    labelText: 'Total price(BAM)',
                  ),
                  controller: _priceController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                  )),
              TextField(
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(color: Colors.black, fontSize: 22),
                    labelText: 'Additional information',
                  ),
                  controller: _descriptionController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                  )),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.blue),
                      ),
                      onPressed: endDate != null
                          ? () async => {await addReservation()}
                          : null,
                      child: const Text(
                        "Add reservation",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
