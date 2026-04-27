import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/providers/notification_provider.dart';
import 'package:propertease_admin/screens/notifications/notification-detail-screen.dart';
import 'package:propertease_admin/screens/notifications/notification_add_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:propertease_admin/widgets/master_screen.dart';
import 'package:provider/provider.dart';

import '../../models/new.dart';

const _kPrimary = Color(0xFF115892);

class NewsListWidget extends StatefulWidget {
  const NewsListWidget({super.key});

  @override
  State<NewsListWidget> createState() => NewsListWidgetState();
}

class NewsListWidgetState extends State<NewsListWidget> {
  late NotificationProvider _newsProvider;
  List<New> news = [];
  int _currentPage = 1;
  int _totalCount = 0;
  bool _isLoading = false;
  final int _pageSize = 10;

  String? _formattedStartDate;
  String? _formattedEndDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newsProvider = context.read<NotificationProvider>();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _newsProvider.get(filter: {
        'Name': _searchController.text,
        if (_formattedStartDate != null) 'CreatedFrom': _formattedStartDate,
        if (_formattedEndDate != null) 'CreatedTo': _formattedEndDate,
        'Page': _currentPage,
        'PageSize': _pageSize,
      });
      if (!mounted) return;
      setState(() {
        news = result.result;
        _totalCount = result.totalCount > 0 ? result.totalCount : result.count;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
      _currentPage = 1;
    });
    _fetchData();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _formattedStartDate = null;
      _formattedEndDate = null;
      _currentPage = 1;
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_totalCount / _pageSize).ceil().clamp(1, 9999);
    return MasterScreenWidget(
      titleWidget: const Text('Vijesti'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(context),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : news.isEmpty
                    ? _buildEmpty()
                    : _buildNewsList(),
          ),
          if (!_isLoading && news.isNotEmpty)
            _buildPagination(totalPages),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() => _currentPage = 1);
                _fetchData();
              },
              decoration: InputDecoration(
                hintText: 'Pretraži po naslovu...',
                prefixIcon: const Icon(Icons.search, color: _kPrimary),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Date from
          _DateFilterChip(
            label: _formattedStartDate != null
                ? 'Od: $_formattedStartDate'
                : 'Od datuma',
            isActive: _formattedStartDate != null,
            onTap: () => _pickDate(isStart: true),
          ),
          const SizedBox(width: 8),
          // Date to
          _DateFilterChip(
            label: _formattedEndDate != null
                ? 'Do: $_formattedEndDate'
                : 'Do datuma',
            isActive: _formattedEndDate != null,
            onTap: () => _pickDate(isStart: false),
          ),
          if (_formattedStartDate != null || _formattedEndDate != null || _searchController.text.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              tooltip: 'Očisti filtere',
              onPressed: _clearFilters,
            ),
          ],
          const Spacer(),
          if (Authorization.isAdmin)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              icon: const Icon(Icons.add),
              label: const Text('Dodaj vijest'),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => const NotificationAddScreen()))
                  .then((_) => _fetchData()),
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
          Icon(Icons.newspaper, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Nema vijesti',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: news.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _NewsCard(
          item: news[index],
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (_) =>
                      NotificationDetailScreen(notification: news[index])))
              .then((_) => _fetchData()),
          onDeleted: _fetchData,
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _fetchData();
                  }
                : null,
          ),
          Text(
            '$_currentPage / $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _fetchData();
                  }
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            'Ukupno: $_totalCount',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── News card (horizontal) ─────────────────────────────────────────────────────

class _NewsCard extends StatefulWidget {
  final New item;
  final VoidCallback onTap;
  final VoidCallback onDeleted;
  const _NewsCard({required this.item, required this.onTap, required this.onDeleted});

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _hovered = false;

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<NotificationProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši vijest'),
        content: Text('Da li ste sigurni da želite obrisati "${widget.item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await provider.deleteNews(widget.item.id!);
      widget.onDeleted();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Greška pri brisanju: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.item;
    final date = n.createdAt != null
        ? DateFormat('dd.MM.yyyy').format(n.createdAt!)
        : '';
    final author =
        '${n.user?.person?.firstName ?? ''} ${n.user?.person?.lastName ?? ''}'.trim();
    final preview = (n.text ?? '').length > 120
        ? '${n.text!.substring(0, 120)}...'
        : (n.text ?? '');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? _kPrimary : Colors.grey.shade200,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hovered ? 0.08 : 0.04),
                blurRadius: _hovered ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14)),
                child: SizedBox(
                  width: 180,
                  height: 120,
                  child: _buildImage(n),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preview,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(author.isNotEmpty ? author : '—',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today_outlined,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(date,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_right,
                        color: _hovered ? _kPrimary : Colors.grey.shade300),
                    if (Authorization.isAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red.shade300,
                        tooltip: 'Obriši vijest',
                        onPressed: () => _confirmDelete(context),
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

  Widget _buildImage(New n) {
    if (n.image != null && n.image!.isNotEmpty) {
      return Image.network(
        '${AppConfig.serverBase}/${n.image}',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade100,
        child: const Center(
            child: Icon(Icons.newspaper, size: 40, color: Colors.grey)),
      );
}

// ── Date filter chip ───────────────────────────────────────────────────────────

class _DateFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _DateFilterChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _kPrimary.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive ? _kPrimary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14,
                color: isActive ? _kPrimary : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13,
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
