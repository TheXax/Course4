import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/product.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/flights_bloc.dart';
import 'bloc/flights_event.dart';
import 'bloc/flights_state.dart';
import 'services/hive_service.dart';
import 'services/remote_config_service.dart';
import 'screens/products_list.dart';
import 'screens/favorites.dart';
import 'screens/product_edit.dart';
import 'screens/product_details.dart';
import 'screens/user_profile.dart';
import 'screens/auth_screen.dart';
import 'providers/user_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/history_provider.dart';
import 'services/analytics_service.dart';
import 'services/messaging_service.dart';
import 'services/auth_service.dart';
import 'services/presence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  await HiveService.init();
  // Initialize Remote Config (non-blocking but we await to have values on first run)
  try {
    await RemoteConfigService.instance.init();
  } catch (_) {}
  // Initialize analytics and messaging (optional)
  try {
    await AnalyticsService.instance.init();
  } catch (_) {}
  try {
    // register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await MessagingService.instance.init();
  } catch (_) {}
  runApp(const TravelApp());
}

class TravelApp extends StatefulWidget {
  const TravelApp({super.key});

  @override
  State<TravelApp> createState() => _TravelAppState();
}

class _TravelAppState extends State<TravelApp> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSub;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = _authService.authStateChanges().listen((user) async {
      _currentUid = user?.uid;
      if (_currentUid != null) {
        await PresenceService.instance.setOnline(_currentUid!);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUid == null) return;
    if (state == AppLifecycleState.resumed) {
      PresenceService.instance.setOnline(_currentUid!);
      PresenceService.instance.updateLastActive(_currentUid!);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      PresenceService.instance.setOffline(_currentUid!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        BlocProvider(create: (_) => FlightsBloc()..add(LoadFlights())),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
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
          '/profile': (_) => const UserProfilePage(),
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
    return ValueListenableBuilder<Color>(
      valueListenable: RemoteConfigService.instance.headerColorNotifier,
      builder: (context, headerColor, _) {
        final bgColor = headerColor.withOpacity(0.08);
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text('Travel App'),
            backgroundColor: headerColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.security),
                tooltip: 'Hive Demo',
                onPressed: () => _showHiveDemoDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'Notifications / Remote Config',
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Notifications & Remote Config'),
                      content: const Text('Enable notifications or fetch Remote Config now.'),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(dCtx);
                            final token = await MessagingService.instance.requestPermissionAndGetToken();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(token == null ? 'No token / permission denied' : 'Token: ${token.substring(0, 8)}...')));
                          },
                          child: const Text('Enable Notifications'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(dCtx);
                            await RemoteConfigService.instance.fetchNow();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remote Config fetched')));
                          },
                          child: const Text('Fetch Remote Config'),
                        ),
                        TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.login),
                tooltip: 'Sign in / Register',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                tooltip: 'Quick switch to Admin',
                onPressed: () {
                  context.read<UserProvider>().switchUser('u_admin');
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switched to Admin')));
                },
              ),
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.person_outline),
                    onSelected: (userId) => userProvider.switchUser(userId),
                    itemBuilder: (ctx) => userProvider.allUsers.map((user) => PopupMenuItem(value: user.id, child: Text(user.name))).toList(),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: Consumer<UserProvider>(builder: (context, userProvider, _) {
            if (userProvider.signedIn) return const SizedBox.shrink();
            return FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())), icon: const Icon(Icons.login), label: const Text('Sign In'));
          }),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(height: 220, width: double.infinity, decoration: BoxDecoration(color: headerColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))), child: const Center(child: Icon(Icons.directions_car, color: Colors.white, size: 100))),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(children: [
                            Card(color: const Color(0xFF3E4EB8), elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), child: Column(children: [Row(children: [Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)), child: const Center(child: Text("One Way", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),), const SizedBox(width: 12), Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white)), child: const Center(child: Text("Round Trip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),)]), const SizedBox(height: 16), _buildInputRow(Icons.flight_takeoff, "From", "Rome, Italy", Colors.white, Colors.white), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.end, children: [const Icon(Icons.swap_vert, color: Colors.white, size: 28)]), const SizedBox(height: 8), _buildInputRow(Icons.flight_land, "To", "Florence, Italy", Colors.white, Colors.white)]))),
                            const SizedBox(height: 10),
                            Card(color: Colors.white, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), child: _buildInputRow(Icons.calendar_today, "Date", "Friday, 10 Sep"))),
                            const SizedBox(height: 10),
                            Card(color: Colors.white, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), child: _buildInputRow(Icons.people, "Passengers", "Adult 02 : child 03"))),
                            const SizedBox(height: 20),
                            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen())), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Search", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))
                          ]),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                Consumer<UserProvider>(builder: (context, userProvider, _) {
                  return Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [GestureDetector(onTap: () => Navigator.pushNamed(context, '/products'), child: const Icon(Icons.search, size: 28, color: Colors.indigo)), GestureDetector(onTap: () => Navigator.pushNamed(context, '/favorites'), child: const Icon(Icons.bookmark_border, size: 28, color: Colors.grey)), GestureDetector(onTap: () { if (userProvider.signedIn) { Navigator.pushNamed(context, '/profile'); } else { Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())); } }, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(userProvider.signedIn ? Icons.person : Icons.login, size: 28, color: userProvider.signedIn ? Colors.indigo : Colors.grey), const SizedBox(height: 4), Text(userProvider.signedIn ? (userProvider.currentUser?.name ?? 'Me') : 'Sign In', style: const TextStyle(fontSize: 10))]))]));
                })
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputRow(IconData icon, String label, String value, [Color? textColor, Color? iconColor]) {
    return Row(children: [Icon(icon, color: iconColor ?? Colors.indigo, size: 30), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor ?? Colors.black54))]))]);
  }

  void _showHiveDemoDialog(BuildContext context) {
    showDialog(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Hive Encryption & Compaction Demo'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Choose a demo to run:'), const SizedBox(height: 12), ElevatedButton(onPressed: () async { Navigator.pop(dialogContext); final result = await HiveService.checkEncryptionStatus(); if (!context.mounted) return; showDialog(context: context, builder: (resultContext) => AlertDialog(title: const Text('Encryption Status'), content: Text(result), actions: [TextButton(onPressed: () => Navigator.pop(resultContext), child: const Text('OK'))])); }, child: const Text('1. Show Encryption Key (stored securely)')), const SizedBox(height: 8), ElevatedButton(onPressed: () async { Navigator.pop(dialogContext); final wrongKey = HiveService.generateNewKey(); final result = await HiveService.tryOpenWithKey(wrongKey); if (!context.mounted) return; showDialog(context: context, builder: (resultContext) => AlertDialog(title: const Text('Wrong Key Test'), content: Text(result), actions: [TextButton(onPressed: () => Navigator.pop(resultContext), child: const Text('OK'))])); }, child: const Text('2. Try Wrong Key (expect error)')), const SizedBox(height: 8), ElevatedButton(onPressed: () async { Navigator.pop(dialogContext); await HiveService.compactBox('products'); if (!context.mounted) return; showDialog(context: context, builder: (resultContext) => AlertDialog(title: const Text('Compaction Result'), content: const Text('Products box has been compacted successfully!'), actions: [TextButton(onPressed: () => Navigator.pop(resultContext), child: const Text('OK'))])) ; }, child: const Text('3. Compact Products Box'))]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))]));
  }
}

/// ----------------- ЭКРАН 2: Результаты (туры из Hive) -----------------
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ValueListenableBuilder<Color>(
            valueListenable: RemoteConfigService.instance.headerColorNotifier,
            builder: (context, color, _) {
              return Container(
                height: 200,
                padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Available Tours",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        if (userProvider.isAdmin || userProvider.isManager) {
                          return IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductEditPage()));
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    )
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<FlightsBloc, FlightsState>(
              builder: (context, state) {
                final fromCache = state is FlightsLoadSuccess && state.fromCache;
                final flights = (state is FlightsLoadSuccess && state.filtered.isNotEmpty)
                    ? state.filtered
                    : Hive.box('products').values.cast<Flight>().toList();

                return Column(
                  children: [
                    if (state is FlightsLoadInProgress)
                      const LinearProgressIndicator(minHeight: 2),
                    if (fromCache)
                      Container(
                        width: double.infinity,
                        color: Colors.orange.shade100,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: const Text(
                          'Offline mode: cached results. Will sync on reconnect.',
                          style: TextStyle(color: Colors.deepOrange),
                        ),
                      ),
                    Expanded(
                      child: flights.isEmpty
                          ? const Center(
                              child: Text('No flights available. Create one to get started!'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              itemCount: flights.length,
                              itemBuilder: (context, index) {
                                final flight = flights[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsPage(productId: flight.id),
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
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  flight.route,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                                              Consumer<FavoritesProvider>(
                                                builder: (context, favoritesProvider, _) {
                                                  final isFav = favoritesProvider.isFavorite(flight.id);
                                                  return ValueListenableBuilder<bool>(
                                                    valueListenable: RemoteConfigService.instance.isLikeEnabledNotifier,
                                                    builder: (context, likeEnabled, _) {
                                                      return IconButton(
                                                        icon: Icon(
                                                          isFav ? Icons.favorite : Icons.favorite_border,
                                                          color: likeEnabled ? Colors.red : Colors.grey,
                                                        ),
                                                        onPressed: likeEnabled
                                                            ? () {
                                                                if (isFav) {
                                                                  favoritesProvider.removeFavorite(flight.id);
                                                                } else {
                                                                  favoritesProvider.addFavorite(
                                                                    flight.id,
                                                                    flight.flightNumber,
                                                                  );
                                                                }
                                                              }
                                                            : () {
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  const SnackBar(
                                                                    content: Text('Likes are disabled by Remote Config'),
                                                                  ),
                                                                );
                                                              },
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              Consumer<UserProvider>(
                                                builder: (context, userProvider, _) {
                                                  if (userProvider.isAdmin || userProvider.isManager) {
                                                    return PopupMenuButton<String>(
                                                      onSelected: (value) async {
                                                        if (value == 'edit') {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) => ProductEditPage(productId: flight.id),
                                                            ),
                                                          );
                                                        } else if (value == 'delete') {
                                                          context.read<FlightsBloc>().add(DeleteFlight(flight.id));
                                                        }
                                                      },
                                                      itemBuilder: (_) => const [
                                                        PopupMenuItem(
                                                          value: 'edit',
                                                          child: Text('Edit'),
                                                        ),
                                                        PopupMenuItem(
                                                          value: 'delete',
                                                          child: Text('Delete'),
                                                        ),
                                                      ],
                                                    );
                                                  }
                                                  return const SizedBox.shrink();
                                                },
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
