import 'package:flutter/material.dart';
import '../services/amizone_service.dart';
import '../services/scraper_service.dart';

class PYQScreen extends StatefulWidget {
  const PYQScreen({super.key});

  @override
  State<PYQScreen> createState() => _PYQScreenState();
}

class _PYQScreenState extends State<PYQScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSubject = 'All';
  String _searchQuery = '';
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ScraperService.instance,
      builder: (context, _) {
        final scraper = ScraperService.instance;
        final allItems = scraper.items;

        // Subject chips follow whatever the scraper actually found.
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

        final pyqs = filtered
            .where((i) =>
                i.fileType.toLowerCase().contains('pyq') ||
                i.title.toLowerCase().contains('major') ||
                i.title.toLowerCase().contains('minor') ||
                i.title.toLowerCase().contains('paper'))
            .toList();

        final notes = filtered
            .where((i) =>
                i.fileType.toLowerCase().contains('notes') ||
                i.title.toLowerCase().contains('module') ||
                i.title.toLowerCase().contains('lec'))
            .toList();

        final books = filtered
            .where((i) =>
                i.fileType.toLowerCase().contains('book') ||
                i.title.toLowerCase().contains('book') ||
                i.title.toLowerCase().contains('edition') ||
                i.title.toLowerCase().contains('soln'))
            .toList();

        final labs = filtered
            .where((i) =>
                i.fileType.toLowerCase().contains('lab') ||
                i.title.toLowerCase().contains('derivation') ||
                i.title.toLowerCase().contains('practical'))
            .toList();


        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.indigo.shade800,
            title: const Text(
              'Library & PYQs (NexAcad + Amizone)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sync with NexAcad',
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
                Tab(text: 'All (${filtered.length})'),
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
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search notes, PYQs, Major papers (e.g. 2024, C++, BST)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
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
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Subject Filter Chips
              Container(
                color: Colors.white,
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
                              color: isSelected ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.indigo.shade800,
                          backgroundColor: Colors.grey.shade100,
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
                    _buildResourceList(filtered),
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

  Widget _buildAmizoneBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.indigo.shade800],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.15),
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
              color: Colors.white.withOpacity(0.15),
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
                  'Amizone Student Intranet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Official portal: Attendance, Marks & Faculty',
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
              'Open Amizone',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            onPressed: () => ScraperService.instance.openAmizone(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceList(List<ScrapedResource> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No items found matching your filters.',
              style: TextStyle(color: Colors.grey.shade600),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isDownloaded
                  ? Colors.green.shade200
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPyq ? Colors.red.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPyq ? Icons.picture_as_pdf : Icons.description,
                        color: isPyq ? Colors.red.shade700 : Colors.blue.shade700,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.subjectCode,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.fileType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.estimatedSize,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              if (item.isDownloaded) ...[
                                const Spacer(),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (progress != null && progress < 1.0) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 4),
                  Text(
                    'Downloading: ${(progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 15),
                      label: const Text(
                        'View Online (0 MB)',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () => ScraperService.instance.openUrl(item.pdfUrl),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.isDownloaded
                            ? Colors.green.shade700
                            : Colors.indigo.shade800,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        item.isDownloaded ? Icons.folder_open : Icons.download,
                        size: 14,
                      ),
                      label: Text(
                        item.isDownloaded ? 'Open File' : 'Download',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _handleDownload(context, item),
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

  void _handleDownload(BuildContext context, ScrapedResource item) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting download for ${item.title}...'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() => _downloadProgress[item.id] = 0.3);

    // Trigger direct system download manager
    final success = await ScraperService.instance.triggerDirectDownload(item);

    setState(() => _downloadProgress.remove(item.id));

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading ${item.title} to your phone Downloads!'),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not trigger download. Check network permissions.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

}
