import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/flights_bloc.dart';
import 'bloc/flights_event.dart';
import 'bloc/flights_state.dart';
import 'bloc/user_bloc.dart';
import 'bloc/user_event.dart';
import 'bloc/user_state.dart';
import 'bloc/favorites_bloc.dart';
import 'bloc/favorites_event.dart';
import 'bloc/favorites_state.dart';
import 'bloc/cart_bloc.dart';
import 'bloc/cart_event.dart';
import 'bloc/cart_state.dart';
import 'bloc/history_bloc.dart';
import 'bloc/history_event.dart';
import 'bloc/history_state.dart';
import 'services/hive_service.dart';
import 'screens/products_list.dart';
import 'screens/favorites.dart';
import 'screens/product_edit.dart';
import 'screens/product_details.dart';
import 'models/user.dart';
// Providers replaced by Blocs

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserBloc()..add(LoadUsers())),
        BlocProvider(create: (_) => FlightsBloc()..add(LoadFlights())),
        BlocProvider(create: (_) => FavoritesBloc()..add(LoadFavorites())),
        BlocProvider(create: (_) => CartBloc()..add(LoadCart())),
        BlocProvider(create: (_) => HistoryBloc()..add(LoadHistory())),
      ],
      child: MaterialApp(
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
      ),
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
          // Переключение на Admin через UserBloc
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Quick switch to Admin',
            onPressed: () {
              context.read<UserBloc>().add(SwitchUser('u_admin'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Switched to Admin'))
              );
            },
          ),
          // Выбор пользователя через UserBloc
          BlocBuilder<UserBloc, UserState>(builder: (context, userState) {
            final List<User> users = userState is UserLoadSuccess ? userState.allUsers : <User>[];
            return PopupMenuButton<String>(
              icon: const Icon(Icons.person_outline),
              onSelected: (userId) {
                context.read<UserBloc>().add(SwitchUser(userId));
              },
              itemBuilder: (ctx) {
                return users
                    .map((User user) => PopupMenuItem<String>(
                          value: user.id,
                          child: Text(user.name),
                        ))
                    .toList();
              },
            );
          })
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
            BlocBuilder<UserBloc, UserState>(builder: (context, userState) {
              final currentUser = userState is UserLoadSuccess ? userState.currentUser : null;
              return Container(
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
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Current user'),
                                content: Text(currentUser?.name ?? 'Unknown'),
                              ),
                            );
                          },
                          child: const Icon(Icons.person_outline, size: 28, color: Colors.grey)),
                    ],
                  )
                );
            }),
            ]
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
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    // Кнопка добавления через UserBloc
                    BlocBuilder<UserBloc, UserState>(builder: (context, userState) {
                      final canEdit = userState is UserLoadSuccess && (userState.isAdmin || userState.isManager);
                      if (canEdit) {
                        return IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            Navigator.push(context, 
                              MaterialPageRoute(builder: (_) => const ProductEditPage())
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    })
                  ],
                ),
              ],
            ),
          ),

          // Список туров со сдвигом вверх
          Transform.translate(
            offset: const Offset(0, 140),
            child: BlocBuilder<FlightsBloc, FlightsState>(
              builder: (context, state) {
                final flights = state is FlightsLoadSuccess ? state.filtered : [];

                if (flights.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: Text('No flights available. Create one to get started!')
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: flights.length,
                  itemBuilder: (context, index) {
                    final flight = flights[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                      ),
                      elevation: 2,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsPage(productId: flight.id)
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.flight, size: 40, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      flight.flightNumber,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      flight.route,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${flight.price.toStringAsFixed(2)} USD',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  BlocBuilder<FavoritesBloc, FavoritesState>(builder: (context, favState) {
                                    final favs = favState is FavoritesLoadSuccess ? favState.favorites : [];
                                    final isFav = favs.any((f) => f.productId == flight.id);
                                    return IconButton(
                                      icon: Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        if (isFav) {
                                          context.read<FavoritesBloc>().add(RemoveFavoriteEvent(flight.id));
                                        } else {
                                          context.read<FavoritesBloc>().add(AddFavoriteEvent(flight.id, flight.flightNumber));
                                        }
                                      },
                                    );
                                  }),
                                  BlocBuilder<UserBloc, UserState>(builder: (context, userState) {
                                    final canEdit = userState is UserLoadSuccess && (userState.isAdmin || userState.isManager);
                                    if (canEdit) {
                                      return PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => 
                                                  ProductEditPage(productId: flight.id),
                                              ),
                                            );
                                          } else if (value == 'delete') {
                                            context.read<FlightsBloc>().add(DeleteFlight(flight.id));
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  })
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
