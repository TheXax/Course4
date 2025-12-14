import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/hive_service.dart';
import 'screens/products_list.dart';
import 'screens/favorites.dart';
import 'screens/product_edit.dart';
import 'screens/product_details.dart';
import 'models/product.dart';
import 'models/favorite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const TravelApp());
}

class TravelApp extends StatefulWidget {
  const TravelApp({super.key});

  @override
  State<TravelApp> createState() => _TravelAppState();
}

class _TravelAppState extends State<TravelApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Travel App",
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[200],
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: const SearchScreen(),
      routes: {
        '/products': (_) => const ProductsListPage(),
        '/favorites': (_) => const FavoritesPage(),
      },
    );
  }
}

/// ----------------- ЭКРАН 1: Поиск -----------------
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: 'Hive Demo (encryption, compact, wrong key)',
            onPressed: () {
              _showHiveDemoDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Quick switch to Admin',
            onPressed: () async {
              final appBox = Hive.box('app');
              appBox.put('currentUserId', 'u_admin');
              if (Navigator.canPop(context)) {
                // nothing
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switched to Admin')));
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            onSelected: (id) async {
              final appBox = Hive.box('app');
              appBox.put('currentUserId', id);
            },
            itemBuilder: (ctx) {
              final users = Hive.box('users');
              return users.keys.map<PopupMenuItem<String>>((k) {
                final u = users.get(k);
                return PopupMenuItem(value: k as String, child: Text((u as dynamic).name ?? k));
              }).toList();
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Верхний синий блок
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF3E4EB8),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: const Center(
                child: Icon(Icons.directions_car,
                    color: Colors.white, size: 100),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                Card(
                  color: const Color(0xFF3E4EB8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Column(
                      children: [
                        // One way / Round trip
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                    child: Text("One Way",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: const Center(
                                    child: Text("Round Trip",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildInputRow(Icons.flight_takeoff, "From",
                            "Rome, Italy", Colors.white, Colors.white),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.swap_vert,
                                color: Colors.white, size: 28),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _buildInputRow(Icons.flight_land, "To",
                            "Florence, Italy", Colors.white, Colors.white),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: _buildInputRow(
                        Icons.calendar_today, "Date", "Friday, 10 Sep"),
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: _buildInputRow(Icons.people, "Passengers",
                        "Adult 02 : child 03"),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ResultsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Search",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                )
              ]),
            ),

            const Spacer(),

            // Bottom nav bar
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/products'),
                      child: const Icon(Icons.search, size: 28, color: Colors.indigo)),
                  GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/favorites'),
                      child: const Icon(Icons.bookmark_border, size: 28, color: Colors.grey)),
                  GestureDetector(
                      onTap: () async {
                        // show current user
                        final appBox = Hive.box('app');
                        final users = Hive.box('users');
                        final current = appBox.get('currentUserId');
                        final user = users.get(current);
                        showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Current user'), content: Text((user as dynamic).name ?? '')));
                      },
                      child: const Icon(Icons.person_outline, size: 28, color: Colors.grey)),
                ],
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(
      IconData icon,
      String label,
      String value, [
        Color? textColor,
        Color? iconColor,
      ]) {
    return Row(children: [
      Icon(icon, color: iconColor ?? Colors.indigo, size: 30),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.black54,
                ),
              ),
            ]),
      )
    ]);
  }

  void _showHiveDemoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hive Encryption & Compaction Demo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a demo to run:'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final result = await HiveService.checkEncryptionStatus();
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (resultContext) => AlertDialog(
                    title: const Text('Encryption Status'),
                    content: Text(result),
                    actions: [TextButton(onPressed: () => Navigator.pop(resultContext), child: const Text('OK'))],
                  ),
                );
              },
              child: const Text('1. Show Encryption Key (stored securely)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final wrongKey = HiveService.generateNewKey();
                final result = await HiveService.tryOpenWithKey(wrongKey);
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (resultContext) => AlertDialog(
                    title: const Text('Wrong Key Test'),
                    content: Text(result),
                    actions: [TextButton(onPressed: () => Navigator.pop(resultContext), child: const Text('OK'))],
                  ),
                );
              },
              child: const Text('2. Try Wrong Key (expect error)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await HiveService.compactBox('products');
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (resultContext) => AlertDialog(
                    title: const Text('Compaction Result'),
                    content: const Text('Products box has been compacted successfully!'),
                    actions: [TextButton(onPressed: () => Navigator.pop(resultContext), child: const Text('OK'))],
                  ),
                );
              },
              child: const Text('3. Compact Products Box'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// ----------------- ЭКРАН 2: Результаты (туры из Hive) -----------------
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late Box productsBox;
  late Box favBox;
  late Box appBox;

  @override
  void initState() {
    super.initState();
    productsBox = Hive.box('products');
    favBox = Hive.box('favorites');
    appBox = Hive.box('app');
  }

  bool isFavorited(String productId, String currentUserId) {
    return favBox.values.cast<Favorite>().any((f) => f.userId == currentUserId && f.productId == productId);
  }

  Future<void> toggleFavorite(String productId, String currentUserId, Product product) async {
    final existingKey = favBox.keys.cast<dynamic>().firstWhere(
      (k) {
        final f = favBox.get(k) as dynamic;
        return f.userId == currentUserId && f.productId == productId;
      },
      orElse: () => null,
    );

    if (existingKey != null) {
      await favBox.delete(existingKey);
      product.isLiked = false;
      await productsBox.put(product.id, product);
    } else {
      await favBox.add(Favorite(userId: currentUserId, productId: productId));
      product.isLiked = true;
      await productsBox.put(product.id, product);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = appBox.get('currentUserId') as String?;
    final usersBox = Hive.box('users');
    final currentUser = currentUserId != null ? usersBox.get(currentUserId) : null;
    final role = currentUser != null ? ((currentUser as dynamic).role as String? ?? 'user') : 'user';
    final canEdit = role == 'admin' || role == 'manager';

    return Scaffold(
      body: Stack(
        children: [
          // Синий header
          Container(
            height: 220,
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF3E4EB8),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Available Tours",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Find your perfect travel",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductEditPage()));
                        },
                      )
                  ],
                ),
              ],
            ),
          ),

          // Список туров со сдвигом вверх
          Transform.translate(
            offset: const Offset(0, 140),
            child: ValueListenableBuilder(
              valueListenable: productsBox.listenable(),
              builder: (context, Box box, _) {
                final keys = box.keys.cast<String>().toList();
                if (keys.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(child: Text('No tours available. Create one to get started!')),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    final Product p = box.get(key) as Product;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(productId: p.id))),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              if (p.imagePath.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(p.imagePath, width: 80, height: 80, fit: BoxFit.cover)
                                )
                              else
                                Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.photo)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(p.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text('${p.price.toStringAsFixed(2)} USD', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.indigo)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(isFavorited(p.id, currentUserId ?? '') ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                                    onPressed: () async {
                                      if (currentUserId != null) {
                                        await toggleFavorite(p.id, currentUserId, p);
                                      }
                                    },
                                  ),
                                  if (canEdit)
                                    PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'edit') {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductEditPage(productId: p.id)));
                                        } else if (v == 'delete') {
                                          await box.delete(p.id);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ],
                                    )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
