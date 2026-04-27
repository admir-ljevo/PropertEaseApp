import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/models/application_user.dart';
import 'package:propertease_client/models/person.dart';
import 'package:propertease_client/models/property_rating.dart';
import 'package:propertease_client/providers/rating_provider.dart';
import 'package:provider/provider.dart';
import 'package:propertease_client/utils/authorization.dart';

class ReviewListScreen extends StatefulWidget {
  final int? id;
  final bool canReview;
  final int? reservationId;
  const ReviewListScreen({
    super.key,
    this.id,
    this.canReview = false,
    this.reservationId,
  });

  @override
  State<StatefulWidget> createState() => ReviewListScreenState();
}

class ReviewListScreenState extends State<ReviewListScreen> {
  late RatingProvider _ratingProvider;
  final List<PropertyRating> _ratings = [];
  bool _isLoading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  int _totalCount = 0;
  String? _sortByRating; // null=newest, 'desc'=highest, 'asc'=lowest
  bool _submitting = false;
  PropertyRating? _existingRating;
  bool _checkingExisting = false;
  final ScrollController _scrollController = ScrollController();

  DateTime? startDate;
  DateTime? endDate;
  String? formattedStartDate;
  String? formattedEndDate;
  int selectedRating = 1;
  TextEditingController commentController = TextEditingController();
  PropertyRating addedRating = PropertyRating();
  int? get userId => Authorization.userId;
  String? get firstName => Authorization.firstName;
  String? get lastName => Authorization.lastName;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ratingProvider = context.read<RatingProvider>();
    _scrollController.addListener(_onScroll);
    _fetchRatings();
    if (widget.canReview && widget.reservationId != null) {
      _loadExistingRating();
    }
  }

  Future<void> _loadExistingRating() async {
    if (!mounted) return;
    setState(() => _checkingExisting = true);
    try {
      final result = await _ratingProvider.getFiltered(filter: {
        'propertyId': widget.id!,
        'reviewerId': userId!,
        'reservationId': widget.reservationId!,
        'page': 1,
        'pageSize': 1,
      });
      if (!mounted) return;
      if (result.result.isNotEmpty) {
        final r = result.result.first;
        setState(() {
          _existingRating = r;
          selectedRating = (r.rating ?? 1).round().clamp(1, 5);
          commentController.text = r.description ?? '';
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _checkingExisting = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFilter({int page = 1}) => {
        "propertyId": widget.id!,
        if (formattedStartDate != null) "createdFrom": formattedStartDate,
        if (formattedEndDate != null) "createdTo": formattedEndDate,
        "page": page,
        "pageSize": 10,
        if (_sortByRating != null) "sortByRating": _sortByRating,
      };

  Future<void> _fetchRatings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _page = 1;
      _ratings.clear();
      _hasMore = true;
    });
    try {
      final result = await _ratingProvider.getFiltered(filter: _buildFilter(page: 1));
      if (!mounted) return;
      setState(() {
        _ratings.addAll(result.result);
        _totalCount = result.count;
        _hasMore = _ratings.length < _totalCount;
        _page = 2;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _ratingProvider.getFiltered(filter: _buildFilter(page: _page));
      if (!mounted) return;
      setState(() {
        _ratings.addAll(result.result);
        _hasMore = _ratings.length < _totalCount;
        _page++;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
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
        formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate!);
      });
      await _fetchRatings();
    }
  }

  Widget _buildReviewerAvatar(String? profilePhotoBytes, String? reviewerName) {
    if (profilePhotoBytes != null && profilePhotoBytes.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(base64Decode(profilePhotoBytes)),
        );
      } catch (_) {}
    }
    final initials = _initials(reviewerName);
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFF115892),
      child: Text(
        initials,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reviews")),
      body: CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // ── Form section ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text("Start Date:"),
                      Text(startDate != null
                          ? DateFormat('MM-dd-yyyy').format(startDate!)
                          : "Not Selected"),
                      ElevatedButton(
                        onPressed: () => _selectStartDate(context),
                        child: const Text("Select Start Date"),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text("End Date:"),
                      Text(endDate != null
                          ? DateFormat('MM-dd-yyyy').format(endDate!)
                          : "Not Selected"),
                      ElevatedButton(
                        onPressed: () => _selectEndDate(context),
                        child: const Text("Select End Date"),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Text("Sort by:   "),
                      DropdownButton<String?>(
                        value: _sortByRating,
                        onChanged: (value) {
                          setState(() => _sortByRating = value);
                          _fetchRatings();
                        },
                        items: const [
                          DropdownMenuItem(value: null, child: Text("Newest")),
                          DropdownMenuItem(value: "desc", child: Text("Highest rating")),
                          DropdownMenuItem(value: "asc", child: Text("Lowest rating")),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.canReview) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(
                      _checkingExisting
                          ? 'Loading...'
                          : _existingRating != null
                              ? 'Edit your review'
                              : 'Leave a review',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        const Text("Rating:    "),
                        SizedBox(
                          width: 200,
                          child: DropdownButton<int>(
                            value: selectedRating,
                            onChanged: (int? value) {
                              setState(() => selectedRating = value!);
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
                      decoration:
                          const InputDecoration(labelText: 'Review Comment'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : () async {
                                setState(() => _submitting = true);
                                try {
                                  final description = commentController.text;
                                  final rating = selectedRating.toDouble();

                                  addedRating.id = _existingRating?.id ?? 0;
                                  addedRating.modifiedAt = DateTime.now();
                                  addedRating.totalRecordsCount = 0;
                                  addedRating.isDeleted = false;
                                  addedRating.createdAt = _existingRating?.createdAt ?? DateTime.now();
                                  addedRating.propertyId = widget.id!;
                                  addedRating.rating = rating;
                                  addedRating.description = description;
                                  addedRating.reviewerId = userId!;
                                  addedRating.reviewerName =
                                      "$firstName $lastName";
                                  addedRating.reservationId = widget.reservationId;

                                  final saved =
                                      await _ratingProvider.addAsync(addedRating);
                                  if (!mounted) return;

                                  final person = Person()
                                    ..firstName = firstName
                                    ..lastName = lastName
                                    ..profilePhotoBytes =
                                        Authorization.profilePhotoBytes;
                                  final reviewer =
                                      ApplicationUser(id: userId)..person = person;
                                  final newRating = PropertyRating(
                                    id: saved.id,
                                    createdAt: saved.createdAt ?? _existingRating?.createdAt ?? DateTime.now(),
                                    propertyId: widget.id,
                                    reviewerId: userId,
                                    reviewerName: "$firstName $lastName",
                                    rating: rating,
                                    description: description,
                                    reservationId: widget.reservationId,
                                  )..reviewer = reviewer;

                                  final isUpdate = _existingRating != null;
                                  setState(() {
                                    _existingRating = newRating;
                                    if (isUpdate) {
                                      final idx = _ratings.indexWhere((r) => r.id == newRating.id);
                                      if (idx >= 0) _ratings[idx] = newRating;
                                    } else {
                                      _ratings.insert(0, newRating);
                                      _totalCount++;
                                    }
                                    _submitting = false;
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isUpdate
                                            ? 'Review updated successfully'
                                            : 'Review added successfully'),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() => _submitting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add review: $e'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_existingRating != null ? 'Update Review' : 'Add Review'),
                      ),
                    ),
                  ),
                  const Divider(thickness: 2),
                ],
              ],
            ),
          ),

          // ── Ratings list ─────────────────────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_ratings.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No ratings available.')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _ratings.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final rating = _ratings[index];
                  return Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildReviewerAvatar(
                                rating.reviewer?.person?.profilePhotoBytes,
                                rating.reviewerName),
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
                            const Icon(Icons.edit, size: 40),
                            Text(
                              rating.createdAt != null
                                  ? DateFormat('MM-dd-yyyy')
                                      .format(rating.createdAt!)
                                  : '',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                      const Divider(thickness: 2),
                    ],
                  );
                },
                childCount: _ratings.length + (_hasMore ? 1 : 0),
              ),
            ),
        ],
      ),
    );
  }
}
