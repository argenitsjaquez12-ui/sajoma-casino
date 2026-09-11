import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const gold = Color(0xFFD4AF37);
const bg = Color(0xFF090909);

void main() => runApp(const SajomaApp());

class SajomaApp extends StatelessWidget {
  const SajomaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SAJOMA CASINO',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Splash(),
    );
  }
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Casino()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold, width: 3),
              ),
              child: const Icon(Icons.casino, size: 65, color: gold),
            ),
            const SizedBox(height: 22),
            const Text(
              'SAJOMA',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 7,
                color: gold,
              ),
            ),
            const Text(
              'CASINO',
              style: TextStyle(fontSize: 16, letterSpacing: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class Casino extends StatefulWidget {
  const Casino({super.key});

  @override
  State<Casino> createState() => _CasinoState();
}

class _CasinoState extends State<Casino> {
  int balance = 125680;
  int tab = 0;
  int level = 1;
  int xp = 0;
  int wins = 0;
  int missions = 0;
  String name = 'Jugador';
  bool bonus = false;
  final Random rng = Random();
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final savedHistory = p.getString('history');
    setState(() {
      balance = p.getInt('balance') ?? 125680;
      name = p.getString('name') ?? 'Jugador';
      bonus = p.getBool('bonus') ?? false;
      level = p.getInt('level') ?? 1;
      xp = p.getInt('xp') ?? 0;
      wins = p.getInt('wins') ?? 0;
      missions = p.getInt('missions') ?? 0;
      if (savedHistory != null) {
        history = List<Map<String, dynamic>>.from(jsonDecode(savedHistory));
      }
    });
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('balance', balance);
    await p.setString('name', name);
    await p.setBool('bonus', bonus);
    await p.setInt('level', level);
    await p.setInt('xp', xp);
    await p.setInt('wins', wins);
    await p.setInt('missions', missions);
    await p.setString('history', jsonEncode(history));
  }

  void move(int amount, String event, {bool win = false}) {
    setState(() {
      balance = max(0, balance + amount);
      history.insert(0, {
        'e': event,
        'd': amount,
        't': DateTime.now().toIso8601String(),
      });
      if (history.length > 100) history.removeLast();
      xp += 10;
      if (win) {
        wins++;
        xp += 20;
      }
      while (xp >= 100) {
        level++;
        xp -= 100;
      }
    });
    save();
  }

  void snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void claimBonus() {
    if (bonus) {
      snack('El bono de hoy ya fue reclamado.');
      return;
    }
    setState(() => bonus = true);
    move(500, 'Bono diario +500');
    snack('¡Bono diario de 500 monedas!');
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      home(),
      History(history: history),
      missionsPage(),
      profile(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SAJOMA CASINO',
          style: TextStyle(color: gold, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: editName, icon: const Icon(Icons.person_outline)),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '🪙 $balance',
                style: const TextStyle(color: gold, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.casino_outlined), selectedIcon: Icon(Icons.casino), label: 'Casino'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Misiones'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget home() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: gold,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bienvenido, $name', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      Text('Nivel $level • $xp/100 XP', style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
                IconButton(onPressed: claimBonus, icon: Icon(Icons.card_giftcard, color: bonus ? Colors.grey : gold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SALDO VIRTUAL', style: TextStyle(color: Colors.white60, letterSpacing: 2)),
                Text('$balance 🪙', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: gold)),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: xp / 100, minHeight: 7),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('JUEGOS', style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 2)),
        game('🎰', 'Tragamonedas', 'Premio hasta 1,000', slots),
        game('🎡', 'Ruleta', 'Premio especial en 7', roulette),
        game('🃏', 'Blackjack', 'Contra la casa', blackjack),
        game('♠️', 'Póker', 'Duelo virtual', poker),
      ],
    );
  }

  Widget game(String icon, String title, String subtitle, VoidCallback action) {
    return Card(
      margin: const EdgeInsets.only(top: 9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: Text(icon, style: const TextStyle(fontSize: 32)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: gold),
        onTap: action,
      ),
    );
  }

  Widget missionsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('TORNEOS Y MISIONES', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Completa objetivos para ganar XP y monedas virtuales.', style: TextStyle(color: Colors.white60)),
        mission('🎁', 'Bono diario', 'Reclama tu bono de hoy', bonus, claimBonus),
        mission('🎰', 'Jugador activo', 'Juega 5 partidas', missions >= 5, () {
          if (missions < 5) {
            setState(() => missions++);
            move(0, 'Misión: partida $missions/5');
          } else {
            snack('Misión completada.');
          }
        }),
        mission('🏆', 'Primera victoria', 'Gana una partida', wins > 0, () {
          snack(wins > 0 ? '¡Completada!' : 'Juega hasta conseguir una victoria.');
        }),
        const SizedBox(height: 15),
        const Card(
          child: ListTile(
            leading: Icon(Icons.emoji_events, color: gold),
            title: Text('Torneo virtual semanal'),
            subtitle: Text('Clasificación por XP • Sin dinero real'),
          ),
        ),
      ],
    );
  }

  Widget mission(String icon, String title, String subtitle, bool done, VoidCallback action) {
    return Card(
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 27)),
        title: Text(title),
        subtitle: Text(done ? 'Completada' : subtitle),
        trailing: done ? const Icon(Icons.check_circle, color: Colors.greenAccent) : FilledButton(onPressed: action, child: const Text('JUGAR')),
      ),
    );
  }

  Widget profile() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 10),
        const Center(child: CircleAvatar(radius: 52, backgroundColor: gold, child: Icon(Icons.person, size: 58, color: Colors.black))),
        const SizedBox(height: 14),
        Center(child: Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
        Center(child: Text('Nivel $level', style: const TextStyle(color: gold))),
        const SizedBox(height: 25),
        ListTile(leading: const Icon(Icons.account_balance_wallet, color: gold), title: const Text('Monedas virtuales'), trailing: Text('$balance')),
        ListTile(leading: const Icon(Icons.emoji_events, color: gold), title: const Text('Victorias'), trailing: Text('$wins')),
        ListTile(leading: const Icon(Icons.star, color: gold), title: const Text('Experiencia'), trailing: Text('$xp / 100')),
        ListTile(leading: const Icon(Icons.edit, color: gold), title: const Text('Cambiar nombre'), onTap: editName),
        const SizedBox(height: 20),
        const Center(child: Text('SAJOMA CASINO • Entretenimiento virtual', style: TextStyle(color: Colors.white38))),
      ],
    );
  }

  void editName() {
    final controller = TextEditingController(text: name);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Perfil'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nombre de jugador')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              setState(() => name = controller.text.trim().isEmpty ? 'Jugador' : controller.text.trim());
              save();
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void buyCoins() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('COMPRAR MONEDAS'),
        content: const Text(
          'Monedas virtuales para jugar. No tienen valor monetario y no se pueden retirar.',
        ),
        actions: [
          _coinPack('10,000', 10000, '0.99'),
          _coinPack('50,000', 50000, '3.99'),
          _coinPack('150,000', 150000, '9.99'),
          _coinPack('500,000', 500000, '19.99'),
        ],
      ),
    );
  }

  Widget _coinPack(String amount, int coins, String price) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () {
            Navigator.pop(context);
            // Demo: adds virtual coins. Connect Apple/Google billing
            // before publishing real-money in-app purchases.
            move(coins, 'Compra virtual: +$amount monedas');
            snack('Se añadieron $amount monedas virtuales.');
          },
          child: Text('$amount monedas  •  \$$price'),
        ),
      ),
    );
  }

  void offerCoinsAfterLoss() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) buyCoins();
    });
  }

  void slots() {
    if (balance < 100) {
      snack('No tienes suficientes monedas.');
      buyCoins();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        List<String> reels = ['🍒', '🍋', '7️⃣'];
        bool busy = false;
        return StatefulBuilder(
          builder: (context, update) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('TRAGAMONEDAS', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: reels.map((x) => Text(x, style: const TextStyle(fontSize: 50))).toList()),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () {
                            update(() => busy = true);
                            Future.delayed(const Duration(milliseconds: 500), () {
                              final values = ['🍒', '🍋', '🔔', '⭐', '7️⃣']..shuffle(rng);
                              final result = [values[0], values[1], values[2]];
                              final reward = result[0] == result[1] && result[1] == result[2]
                                  ? 1000
                                  : (result[0] == result[1] || result[1] == result[2] || result[0] == result[2] ? 250 : -100);
                              update(() {
                                reels = result;
                                busy = false;
                              });
                              move(reward, 'Tragamonedas: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
                               if (reward < 0) offerCoinsAfterLoss();
                            });
                          },
                    child: const Text('GIRAR • 100 🪙'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void roulette() {
    if (balance < 100) {
      snack('No tienes suficientes monedas.');
      buyCoins();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('RULETA'),
        content: const Text('La ruleta virtual gira al pulsar JUGAR. El 7 entrega +500 monedas.'),
        actions: [
          FilledButton(
            onPressed: () {
              final number = rng.nextInt(37);
              final reward = number == 7 ? 500 : -100;
              move(reward, 'Ruleta: $number (${reward >= 0 ? '+' : ''}$reward)', win: reward > 0);
               if (reward < 0) offerCoinsAfterLoss();
              Navigator.pop(context);
            },
            child: const Text('JUGAR • 100 🪙'),
          ),
        ],
      ),
    );
  }

  void blackjack() {
    if (balance < 100) {
      snack('No tienes suficientes monedas.');
      buyCoins();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('BLACKJACK'),
        content: const Text('Partida rápida virtual. Gana la mayor puntuación sin superar 21.'),
        actions: [
          FilledButton(
            onPressed: () {
              final player = 2 + rng.nextInt(20);
              final house = 2 + rng.nextInt(20);
              final reward = player > 21 ? -100 : (house > 21 || player > house ? 100 : (player == house ? 0 : -100));
              move(reward, 'Blackjack: $player / $house (${reward >= 0 ? '+' : ''}$reward)', win: reward > 0);
               if (reward < 0) offerCoinsAfterLoss();
              Navigator.pop(context);
            },
            child: const Text('JUGAR • 100 🪙'),
          ),
        ],
      ),
    );
  }

  void poker() {
    if (balance < 100) {
      snack('No tienes suficientes monedas.');
      buyCoins();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PÓKER'),
        content: const Text('Duelo virtual rápido. Mayor fuerza gana.'),
        actions: [
          FilledButton(
            onPressed: () {
              final player = 1 + rng.nextInt(100);
              final opponent = 1 + rng.nextInt(100);
              final reward = player > opponent ? 150 : (player == opponent ? 0 : -100);
              move(reward, 'Póker: $player vs $opponent (${reward >= 0 ? '+' : ''}$reward)', win: reward > 0);
               if (reward < 0) offerCoinsAfterLoss();
              Navigator.pop(context);
            },
            child: const Text('JUGAR • 100 🪙'),
          ),
        ],
      ),
    );
  }
}

class History extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const History({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('Todavía no hay movimientos.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      itemBuilder: (_, index) {
        final item = history[index];
        final amount = item['d'] as int;
        return Card(
          child: ListTile(
            leading: Icon(amount >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: amount >= 0 ? Colors.greenAccent : Colors.redAccent),
            title: Text(item['e'] as String),
            subtitle: Text((item['t'] as String).replaceFirst('T', ' ').split('.').first),
            trailing: Text('${amount >= 0 ? '+' : ''}$amount', style: TextStyle(fontWeight: FontWeight.bold, color: amount >= 0 ? Colors.greenAccent : Colors.redAccent)),
          ),
        );
      },
    );
  }
}
