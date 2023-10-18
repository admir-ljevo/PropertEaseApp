import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/providers/notification_provider.dart';
import 'package:propertease_admin/screens/notifications/notification-detail-screen.dart';
import 'package:propertease_admin/screens/notifications/notification_add_screen.dart';
import 'package:propertease_admin/widgets/master_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/new.dart';

class NewsListWidget extends StatefulWidget {
  const NewsListWidget({super.key});

  @override
  State<NewsListWidget> createState() => NewsListWidgetState();
}

class NewsListWidgetState extends State<NewsListWidget> {
  late NotificationProvider _newsProvider;
  List<New> _news = [];
  List<New> news = [];
  late DateTime? selectedDateStart;
  late DateTime? seletedDateEnd;
  String? formattedStartDate;
  String? formattedEndDate;

  String? firstName;
  String? lastName;
  String photoUrl = 'https://localhost:44340';
  int? roleId;
  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');
      photoUrl = 'https://localhost:44340${prefs.getString('profilePhoto')}';
      roleId = prefs.getInt('roleId')!;
    });
  }

  TextEditingController _searchController = TextEditingController();
  Future<void> _fetchData() async {
    _news = await _newsProvider.get(filter: {
      'Name': _searchController.text,
      'CreatedFrom': formattedStartDate,
      'CreatedTo': formattedEndDate,
    });
    setState(() {
      news = _news;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _newsProvider = context.read<NotificationProvider>();
    getUserIdFromSharedPreferences();
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _newsProvider = context.read<NotificationProvider>();
    getUserIdFromSharedPreferences();
    _fetchData();
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
      _fetchData();
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
      seletedDateEnd = picked;
      formattedEndDate = DateFormat('yyyy-MM-dd').format(seletedDateEnd!);
      _fetchData();
    }
  }

  bool isHovered = false;

  int hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      title_widget: const Text('News list'),
      child: Column(
        children: [
          // First child: Search input field and date pickers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    onChanged: (value) async {
                      await _fetchData();
                    },
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by headline',
                      prefixIcon:
                          Icon(Icons.search), // Add the search icon here
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _selectDateStart(context); // Show date picker dialog
                  },
                  child: const Text('Created from'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _selectDateEnd(context); // Show date picker dialog
                  },
                  child: const Text('Created to'),
                ),
              ),
            ],
          ),

          if (roleId == 1)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationAddScreen(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Add notification"),
                ),
              ),
            ),

          // Second child: Your existing MasterScreenWidget
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: news.length + 1, // +1 for the "News overview" row
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    // This is the "News overview" row
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 100,
                            ),
                            Text(
                              "News overview",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF115892),
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.article,
                              size: 80,
                              color: Color(0xFF115892),
                            ),
                            SizedBox(
                              width: 100,
                            ),
                          ],
                        ),
                        Divider(
                          thickness: 2,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 10.0),
                      ],
                    );
                  }

                  final currentNews = news[index - 1];

                  String truncatedText = currentNews.text ?? "";
                  if (truncatedText.length > 40) {
                    truncatedText = truncatedText.substring(0, 40) + "...";
                  }

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NotificationDetailScreen(
                            notification: currentNews,
                          ),
                        ),
                      );
                    },
                    onHover: (hover) {
                      setState(() {
                        hoveredIndex = hover ? index - 1 : -1;
                      });
                    },
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        border: index - 1 == hoveredIndex
                            ? Border.all(
                                color: Colors.blue,
                                width: 2.0,
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Center(
                                child: Container(
                                  height: 180,
                                  width: 300,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(10.0),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    alignment: Alignment
                                        .center, // Center the image within the box
                                    child: SizedBox(
                                      width: 250, // Set the maximum width
                                      height: 120, // Set the maximum height
                                      child: Image.network(
                                        'https://localhost:44340/${currentNews.image}',
                                        alignment: Alignment
                                            .center, // Center the image within its box
                                        width: double
                                            .infinity, // Allow the image to take the maximum width
                                        height:
                                            110, // Allow the image to take the maximum height
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 231, 231, 231),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit),
                                        Text(
                                          '${currentNews.user?.person?.firstName ?? ""} ${currentNews.user?.person?.lastName ?? ""}',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      currentNews.name ?? "",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      'Posted at: ${currentNews.createdAt}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(truncatedText),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
