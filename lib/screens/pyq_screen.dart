import 'package:flutter/material.dart';
import '../services/amizone_service.dart';
import '../services/scraper_service.dart';

enum LibrarySortOption {
  titleAsc,
  titleDesc,
  codeAsc,
  type,
}

class PYQScreen extends StatefulWidget {
  const PYQScreen({super.key});

  @override
  State<PYQScreen> createState() => _PYQScreenState();
}

class _PYQScreenState extends State<PYQScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSubject = 'All';
  String _searchQuery = '';
  LibrarySortOption _sortOption = LibrarySortOption.titleAsc;
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ScrapedResource> _applySorting(List<ScrapedResource> items) {
    final list = List<ScrapedResource>.from(items);
    switch (_sortOption) {
      case LibrarySortOption.titleAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case LibrarySortOption.titleDesc:
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case LibrarySortOption.codeAsc:
        list.sort((a, b) => a.subjectCode.compareTo(b.subjectCode));
        break;
      case LibrarySortOption.type:
        list.sort((a, b) => a.fileType.compareTo(b.fileType));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ScraperService.instance,
      builder: (context, _) {
        final theme = Theme.of(context);
        final scraper = ScraperService.instance;
        final allItems = scraper.items;

        final subjectList = [
          'All',
          ...({for (final item in allItems) item.subjectCode}.toList()..sort()),
        ];
        final selectedSubject =
            subjectList.contains(_selectedSubject) ? _selectedSubject : 'All';

        // Apply filters
        List<ScrapedResource> filtered = allItems;

        if (selectedSubject != 'All') {
          filtered = filtered.where((i) => i.subjectCode == selectedSubject).toList();
        }

        if (_searchQuery.isNotEmpty) {
          filtered = filtered
              .where((i) =>
                  i.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  i.subjectCode.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        final sortedFiltered = _applySorting(filtered);

        final pyqs = sortedFiltered
            .where((i) =>
                i.fileType.toLowerCase().contains('pyq') ||
                i.title.toLowerCase().contains('major') ||
                i.title.toLowerCase().contains('minor') ||
                i.title.toLowerCase().contains('paper'))
            .toList();

        final notes = sortedFiltered
            .where((i) =>
                i.fileType.toLowerCase().contains('notes') ||
                i.title.toLowerCase().contains('module') ||
                i.title.toLowerCase().contains('lec'))
            .toList();

        final books = sortedFiltered
            .where((i) =>
                i.fileType.toLowerCase().contains('book') ||
                i.title.toLowerCase().contains('book') ||
                i.title.toLowerCase().contains('edition') ||
                i.title.toLowerCase().contains('soln'))
            .toList();

        final labs = sortedFiltered
            .where((i) =>
                i.fileType.toLowerCase().contains('lab') ||
                i.title.toLowerCase().contains('derivation') ||
                i.title.toLowerCase().contains('practical'))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Library & PYQs',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                tooltip: 'Sort items',
                onPressed: () => _showSortModal(context),
              ),
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sync catalog',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await scraper.syncFromNexacad(
                    enrolledCodes:
                        AmizoneService.instance.courses.map((c) => c.subjectCode).toList(),
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(scraper.statusMessage ?? 'Synced!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.amberAccent,
              indicatorWeight: 3,
              labelColor: Colors.amberAccent,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'All (${sortedFiltered.length})'),
                Tab(text: 'PYQs (${pyqs.length})'),
                Tab(text: 'Notes (${notes.length})'),
                Tab(text: 'Books (${books.length})'),
                Tab(text: 'Labs (${labs.length})'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Amizone Portal Official Card
              _buildAmizoneBanner(context),

              // Search Bar & Subject Filter
              Container(
                color: theme.cardColor,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search notes, PYQs, Major papers...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              setState(() {
                                _searchCtrl.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Subject Filter Chips
              Container(
                color: theme.cardColor,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: subjectList.map((sub) {
                      final isSelected = selectedSubject == sub;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            sub,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          onSelected: (val) {
                            if (val) setState(() => _selectedSubject = sub);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (scraper.isLoading) const LinearProgressIndicator(),

              // Items View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResourceList(sortedFiltered),
                    _buildResourceList(pyqs),
                    _buildResourceList(notes),
                    _buildResourceList(books),
                    _buildResourceList(labs),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort Library Resources',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.sort_by_alpha),
                  title: const Text('Title (A-Z)'),
                  trailing: _sortOption == LibrarySortOption.titleAsc
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = LibrarySortOption.titleAsc);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sort_by_alpha),
                  title: const Text('Title (Z-A)'),
                  trailing: _sortOption == LibrarySortOption.titleDesc
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = LibrarySortOption.titleDesc);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Subject Code (A-Z)'),
                  trailing: _sortOption == LibrarySortOption.codeAsc
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = LibrarySortOption.codeAsc);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Resource Type'),
                  trailing: _sortOption == LibrarySortOption.type
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = LibrarySortOption.type);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmizoneBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school, color: Colors.amberAccent, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amizone Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Courses, Attendance, Marks & Faculty',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.indigo.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text(
              'Open',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            onPressed: () => ScraperService.instance.openAmizone(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceList(List<ScrapedResource> items) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 50, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Text(
              'No items found matching your filters.',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final progress = _downloadProgress[item.id];

        final isPyq = item.fileType.toLowerCase().contains('pyq') ||
            item.title.toLowerCase().contains('major') ||
            item.title.toLowerCase().contains('minor');

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isDownloaded
                  ? Colors.green.withValues(alpha: 0.4)
                  : theme.dividerColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.subjectCode,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPyq ? Colors.purple.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.fileType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPyq ? Colors.purple : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.estimatedSize.isNotEmpty)
                      Text(
                        item.estimatedSize,
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (item.subjectName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.subjectName,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
                const SizedBox(height: 10),
                if (progress != null) ...[
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (item.pdfUrl.isNotEmpty)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: const Icon(Icons.preview_outlined, size: 16),
                        label: const Text('Preview', style: TextStyle(fontSize: 12)),
                        onPressed: () => ScraperService.instance.openUrl(item.pdfUrl),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: item.isDownloaded
                            ? Colors.green
                            : theme.colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: Icon(
                        item.isDownloaded ? Icons.check : Icons.download_outlined,
                        size: 16,
                      ),
                      label: Text(
                        item.isDownloaded ? 'Downloaded' : 'Download',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _downloadItem(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadItem(ScrapedResource item) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloadProgress[item.id] = 0.2);

    final file = await ScraperService.instance.downloadToFile(
      item,
      onProgress: (p) {
        if (mounted) setState(() => _downloadProgress[item.id] = p);
      },
    );

    if (mounted) {
      setState(() => _downloadProgress.remove(item.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text(file != null ? 'Downloaded ${item.title}' : 'Download opened in browser.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
