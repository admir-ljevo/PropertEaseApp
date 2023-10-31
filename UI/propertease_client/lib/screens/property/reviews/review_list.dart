import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/models/application_user.dart';
import 'package:propertease_client/models/property_rating.dart';
import 'package:propertease_client/models/search_result.dart';
import 'package:propertease_client/providers/rating_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewListScreen extends StatefulWidget {
  int? id;
  ReviewListScreen({super.key, this.id});

  @override
  State<StatefulWidget> createState() => ReviewListScreenState();
}

class ReviewListScreenState extends State<ReviewListScreen> {
  late RatingProvider _ratingProvider;
  SearchResult<PropertyRating>? ratings;
  DateTime? startDate;
  DateTime? endDate;
  String? formattedStartDate;
  String? formattedEndDate;
  int selectedRating = 1;
  TextEditingController commentController = TextEditingController();
  PropertyRating addedRating = PropertyRating();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ratingProvider = context.read<RatingProvider>();
    getUserIdFromSharedPreferences();
    _fetchRatings();
  }

  @override
  void initState() {
    super.initState();
    _ratingProvider = context.read<RatingProvider>();
    getUserIdFromSharedPreferences();
    _fetchRatings();
  }

  String? firstName;
  String? lastName;

  int? userId;
  // Add a GlobalKey for the form
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = int.tryParse(prefs.getString('userId')!)!;
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');
    });
  }

  Future<void> _fetchRatings() async {
    if (formattedStartDate != null && formattedEndDate != null) {
      final Map<String, dynamic> filter = {
        "propertyId": widget.id!,
        "createdFrom": formattedStartDate,
        "createdTo": formattedEndDate,
      };

      SearchResult<PropertyRating> tempRatings =
          await _ratingProvider.getFiltered(filter: filter);
      setState(() {
        ratings = tempRatings;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
        formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate!);
      });

      await _fetchRatings();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
        formattedEndDate = DateFormat('MM-dd-yyyy').format(endDate!);
      });

      await _fetchRatings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reviews")),
      body: Column(
        children: [
          SizedBox(
            height: 60, // Height for the date picker rows
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Start Date:"),
                Text(startDate != null
                    ? DateFormat('MM-dd-yyyy').format(startDate!)
                    : "Not Selected"),
                ElevatedButton(
                  onPressed: () async {
                    await _selectStartDate(context);
                  },
                  child: Text("Select Start Date"),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60, // Height for the date picker rows
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("End Date:"),
                Text(endDate != null
                    ? DateFormat('MM-dd-yyyy').format(endDate!)
                    : "Not Selected"),
                ElevatedButton(
                  onPressed: () async {
                    await _selectEndDate(context);
                  },
                  child: Text("Select End Date"),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Text("Rating:    "),
                Container(
                  width: 200, // Set the width to your desired value
                  child: DropdownButton<int>(
                    value: selectedRating,
                    onChanged: (int? value) {
                      setState(() {
                        selectedRating = value!;
                      });
                    },
                    items: [1, 2, 3, 4, 5].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(labelText: 'Review Comment'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                int rating = selectedRating;
                String comment = commentController.text;
                addedRating.id = 0;
                addedRating.modifiedAt = DateTime.now();
                addedRating.totalRecordsCount = 0;
                addedRating.isDeleted = false;
                addedRating.createdAt = DateTime.now();
                addedRating.propertyId = widget.id!;
                addedRating.rating = double.tryParse(selectedRating.toString());
                addedRating.description = comment;
                addedRating.reviewerId = userId!;
                addedRating.reviewerName = "$firstName $lastName";

                addedRating = await _ratingProvider.addAsync(addedRating);
                setState(() {
                  _fetchRatings();
                  commentController.text = "";
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Review added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Review added successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Add Review"),
          ),
          Expanded(
            child: FutureBuilder<SearchResult<PropertyRating>>(
              future: _ratingProvider.getFiltered(filter: {
                "propertyId": widget.id!,
                "createdFrom": formattedStartDate,
                "createdTo": formattedEndDate
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.result.isEmpty) {
                  return const Center(child: Text('No ratings available.'));
                } else {
                  SearchResult<PropertyRating> ratings = snapshot.data!;
                  return ListView.builder(
                    itemCount: ratings.result.length,
                    itemBuilder: (context, index) {
                      PropertyRating rating = ratings.result[index];
                      return Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  child: ClipOval(
                                    child: rating.reviewer!.person!
                                                .profilePhotoBytes !=
                                            null
                                        ? Image.memory(
                                            base64Decode(rating.reviewer!
                                                .person!.profilePhotoBytes!),
                                            fit: BoxFit.cover,
                                            width: 80,
                                            height: 80,
                                          )
                                        : Image.asset(
                                            "assets/images/user_placeholder.jpg",
                                            width: 80,
                                            height: 80),
                                  ),
                                ),
                              ),
                              Text(
                                "${rating.reviewer?.person?.firstName} ${rating.reviewer?.person?.lastName}",
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ListTile(
                            title: Text(
                              "Rating: ${rating.rating}",
                              style: const TextStyle(fontSize: 22),
                            ),
                            subtitle: Text(
                              "Comment: ${rating.description}",
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit,
                                  size: 40,
                                ),
                                Text(
                                  DateFormat('MM-dd-yyyy')
                                      .format(rating.createdAt!),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            thickness: 2,
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
