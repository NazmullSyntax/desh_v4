import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/guide_provider.dart';
import '../../widgets/common/ui_atoms.dart';
import '../../widgets/home/destination_card.dart';
import '../../widgets/home/home_chips_and_cards.dart';
import '../../widgets/home/weather_card.dart';
import '../ai_assistant/ai_assistant_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategory;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(popularPlacesProvider);
    ref.invalidate(trendingPlacesProvider);
    ref.invalidate(divisionsProvider);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final popularAsync = ref.watch(popularPlacesProvider);
    final trendingAsync = ref.watch(trendingPlacesProvider);
    final divisionsAsync = ref.watch(divisionsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('AI Assistant'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16, AppSpacing.screenPadding, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- Header: greeting + emergency button ----
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hi, ${user?.displayName ?? 'Traveler'} 👋', style: Theme.of(context).textTheme.titleLarge),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 2),
                                    Text("Cox's Bazar, Bangladesh", style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.push(AppRoutes.notifications),
                            icon: const Icon(Icons.notifications_outlined),
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.safety),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), shape: BoxShape.circle),
                              child: const Icon(Icons.sos_rounded, color: AppColors.error, size: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ---- Search bar ----
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                        decoration: const InputDecoration(
                          hintText: 'Search destinations, hotels...',
                          prefixIcon: Icon(Icons.search, size: 22),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ---- Weather card ----
                      const WeatherCard(),
                      const SizedBox(height: AppSpacing.sectionGap),

                      // ---- Categories ----
                      CategoryChipRow(
                        selected: _selectedCategory,
                        onSelect: (v) => setState(() => _selectedCategory = v),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),

                      // ---- Popular Destinations ----
                      SectionHeader(title: 'Popular Destinations', actionLabel: 'See all', onActionTap: () => context.push(AppRoutes.guide)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 230,
                  child: popularAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => const Center(child: Text('Could not load destinations')),
                    data: (places) {
                      final filtered = _selectedCategory == null
                          ? places
                          : places.where((p) => p.category.any((c) => c.toLowerCase().contains(_selectedCategory!.toLowerCase().split(' ').first))).toList();
                      if (filtered.isEmpty) {
                        return const EmptyState(icon: Icons.travel_explore, title: 'No matches', subtitle: 'Try a different category');
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => DestinationCard(place: filtered[i]),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sectionGap, AppSpacing.screenPadding, 0),
                  child: SectionHeader(title: 'Explore by Division', actionLabel: 'See all', onActionTap: () => context.push(AppRoutes.guide)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 90,
                  child: divisionsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => const Center(child: Text('Could not load divisions')),
                    data: (divisions) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                      itemCount: divisions.length,
                      itemBuilder: (context, i) => DivisionCard(division: divisions[i]),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sectionGap, AppSpacing.screenPadding, 0),
                  child: SectionHeader(title: 'Trending Places'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 230,
                  child: trendingAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => const Center(child: Text('Could not load trending places')),
                    data: (places) {
                      if (places.isEmpty) {
                        return const EmptyState(icon: Icons.trending_up, title: 'Nothing trending yet', subtitle: 'Check back soon');
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                        itemCount: places.length,
                        itemBuilder: (context, i) => DestinationCard(place: places[i]),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sectionGap, AppSpacing.screenPadding, 0),
                  child: _TravelTipsCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelTipsCard extends StatelessWidget {
  const _TravelTipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.accentDark, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Travel Tip of the Day', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'November to February is the best window to visit most of Bangladesh — cooler weather and clearer skies for sightseeing.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
