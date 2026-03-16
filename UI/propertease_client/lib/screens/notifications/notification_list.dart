import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/new.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/master_screen.dart';
import 'notification_details.dart';

const _kPrimary = Color(0xFF115892);

class NewsListWidget extends StatefulWidget {
  const NewsListWidget({super.key});

  @override
  State<NewsListWidget> createState() => _NewsListWidgetState();
}

class _NewsListWidgetState extends State<NewsListWidget> {
  late NotificationProvider _provider;
  List<New> _news = [];
  int _totalCount = 0;
  int _currentPage = 1;
  static const int _pageSize = 6;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  String? _formattedStartDate;
  String? _formattedEndDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = context.read<NotificationProvider>();
    _fetchData(reset: true);
  }

  Future<void> _fetchData({bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await _provider.getFiltered(filter: {
        'Name': _searchController.text,
        if (_formattedStartDate != null) 'CreatedFrom': _formattedStartDate,
        if (_formattedEndDate != null) 'CreatedTo': _formattedEndDate,
        'Page': _currentPage,
        'PageSize': _pageSize,
      });
      if (!mounted) return;
      setState(() {
        if (reset) {
          _news = result.result;
        } else {
          _news.addAll(result.result);
        }
        _totalCount = result.count;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _formattedStartDate = DateFormat('yyyy-MM-dd').format(picked);
      } else {
        _formattedEndDate = DateFormat('yyyy-MM-dd').format(picked);
      }
    });
    _fetchData(reset: true);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _formattedStartDate = null;
      _formattedEndDate = null;
    });
    _fetchData(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      currentIndex: 2,
      titleWidget: const Text('Vijesti'),
      child: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                : _news.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final hasFilters = _formattedStartDate != null ||
        _formattedEndDate != null ||
        _searchController.text.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchController,
            onChanged: (_) => _fetchData(reset: true),
            decoration: InputDecoration(
              hintText: 'Pretraži vijesti...',
              prefixIcon: const Icon(Icons.search, color: _kPrimary, size: 20),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _kPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Date chips row
          Row(
            children: [
              _DateChip(
                label: _formattedStartDate ?? 'Od datuma',
                isActive: _formattedStartDate != null,
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(width: 8),
              _DateChip(
                label: _formattedEndDate ?? 'Do datuma',
                isActive: _formattedEndDate != null,
                onTap: () => _pickDate(isStart: false),
              ),
              if (hasFilters) ...[
                const Spacer(),
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Row(
                    children: [
                      Icon(Icons.close, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Očisti',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.newspaper, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Nema vijesti',
              style:
                  TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildList() {
    final hasMore = _news.length < _totalCount;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _news.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _news.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child: CircularProgressIndicator(color: _kPrimary)),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextButton(
                    onPressed: () {
                      _currentPage++;
                      _fetchData();
                    },
                    child: const Text('Učitaj više',
                        style: TextStyle(color: _kPrimary)),
                  ),
                );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _NewsCard(
            item: _news[index],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => NotificationDetailScreen(
                    notification: _news[index]))),
          ),
        );
      },
    );
  }
}

// ── News card ──────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final New item;
  final VoidCallback onTap;
  const _NewsCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = item;
    final date = n.createdAt != null
        ? DateFormat('dd.MM.yyyy').format(n.createdAt!)
        : '';
    final author =
        '${n.user?.person?.firstName ?? ''} ${n.user?.person?.lastName ?? ''}'
            .trim();
    final preview = (n.text ?? '').length > 100
        ? '${n.text!.substring(0, 100)}...'
        : (n.text ?? '');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: _buildImage(n),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.name ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    preview,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          author.isNotEmpty ? author : '—',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(date,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(New n) {
    if (n.imageBytes != null && n.imageBytes!.isNotEmpty) {
      try {
        return Image.memory(base64Decode(n.imageBytes!), fit: BoxFit.cover);
      } catch (_) {}
    }
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
          child: Icon(Icons.newspaper, size: 48, color: Colors.grey)),
    );
  }
}

// ── Date chip ──────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _DateChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? _kPrimary.withOpacity(0.09) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive ? _kPrimary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 13,
                color: isActive ? _kPrimary : Colors.grey.shade600),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: isActive ? _kPrimary : Colors.grey.shade700,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
