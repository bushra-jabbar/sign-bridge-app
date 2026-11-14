import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../../core/interfaces/gloss_engine.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.database});

  final AppDatabase database;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  Future<List<SignEntry>> _loadSigns() async {
    final rows = await widget.database.fetchSigns(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );

    return [
      for (final row in rows)
        SignEntry(
          gloss: row['gloss']! as String,
          displayText: row['display_text']! as String,
          category: row['category']! as String,
          clipName: row['clip_name']! as String,
        ),
    ];
  }

  Future<List<String>> _loadCategories() async {
    final rows = await widget.database.database;
    final result = await rows.rawQuery(
      'SELECT DISTINCT category FROM signs WHERE language = ? ORDER BY category ASC',
      ['asl'],
    );
    return ['All', for (final row in result) row['category'] as String];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search signs',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<String>>(
                future: _loadCategories(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? const ['All'];
                  return SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final selected = _selectedCategory == category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<SignEntry>>(
                  future: _loadSigns(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Could not load library: ${snapshot.error}'));
                    }

                    final signs = snapshot.data ?? const <SignEntry>[];
                    if (signs.isEmpty) {
                      return const Center(child: Text('No signs match this filter.'));
                    }

                    return ListView.separated(
                      itemCount: signs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final sign = signs[index];
                        return Card(
                          child: ListTile(
                            title: Text(sign.displayText),
                            subtitle: Text('${sign.category} · ${sign.gloss}'),
                            trailing: const Icon(Icons.play_circle_outline_rounded),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Playing ${sign.gloss}')),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
