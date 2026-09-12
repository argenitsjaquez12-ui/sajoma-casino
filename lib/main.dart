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
        colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
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
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Casino()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino, size: 82, color: gold),
            SizedBox(height: 18),
            Text('SAJOMA', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 7, color: gold)),
            Text('CASINO', style: TextStyle(fontSize: 16, letterSpacing: 9)),
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
    final saved = p.getString('history');
    if (!mounted) return;
    setState(() {
      balance = p.getInt('balance') ?? 125680;
      name = p.getString('name') ?? 'Jugador';
      bonus = p.getBool('bonus') ?? false;
      level = p.getInt('level') ?? 1;
      xp = p.getInt('xp') ?? 0;
      wins = p.getInt('wins') ?? 0;
      missions = p.getInt('missions') ?? 0;
      if (saved != null) {
        history = List<Map<String, dynamic>>.from(jsonDecode(saved));
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
      history.insert(0, {'e': event, 'd': amount, 't': DateTime.now().toIso8601String()});
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void claimBonus() {
    if (bonus) {
      snack('El bono de hoy ya fue reclamado.');
      return;
    }
    setState(() => bonus = true);
    move(500, 'Bono diario +500');
    snack('Bono diario: +500 monedas virtuales.');
  }

  void buyCoins() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('COMPRAR MONEDAS'),
        content: const Text('Monedas virtuales para jugar. No tienen valor monetario y no se pueden retirar.'),
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
            move(coins, 'Compra virtual: +$amount monedas');
            snack('Se añadieron $amount monedas virtuales.');
          },
          child: Text('$amount monedas  -  \$$price'),
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

  bool canBet(int amount) {
    if (balance < amount) {
      snack('No tienes suficientes monedas.');
      buyCoins();
      return false;
    }
    return true;
  }

  void showGame(String title, Widget Function(VoidCallback close) content) {
    late VoidCallback close;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        close = () => Navigator.pop(dialogContext);
        return AlertDialog(
          title: Text(title, style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(child: content(close)),
        );
      },
    );
  }

  void showResult(String title, String text, int reward) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text('$text\n\n${reward > 0 ? 'GANASTE +$reward' : reward < 0 ? 'PERDISTE ${reward.abs()}' : 'EMPATE'} COINS'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CONTINUAR')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[home(), historyPage(), missionsPage(), profile()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAJOMA CASINO', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text('$balance COINS', style: const TextStyle(color: gold, fontWeight: FontWeight.bold))),
          ),
          IconButton(onPressed: buyCoins, icon: const Icon(Icons.add_circle, color: gold)),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.casino), label: 'Casino'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Misiones'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget home() {
    final games = <Map<String, dynamic>>[
      {'title': 'FIRE FRONTIER', 'genre': 'Slots', 'icon': Icons.local_fire_department, 'action': slots, 'a': Color(0xFF7A1E12), 'b': Color(0xFFFFB300)},
      {'title': 'GOLDEN 7', 'genre': 'Slots', 'icon': Icons.filter_7, 'action': slots, 'a': Color(0xFF4A1A00), 'b': Color(0xFFFFD54F)},
      {'title': 'FORTUNE GOD', 'genre': 'Slots', 'icon': Icons.sentiment_very_satisfied, 'action': slots, 'a': Color(0xFF7B1FA2), 'b': Color(0xFFFFA000)},
      {'title': 'MONEY MOUSE', 'genre': 'Slots', 'icon': Icons.paid, 'action': slots, 'a': Color(0xFF8B0000), 'b': Color(0xFFFFD700)},
      {'title': 'CLOVER GOLD', 'genre': 'Slots', 'icon': Icons.eco, 'action': slots, 'a': Color(0xFF075E3D), 'b': Color(0xFF9CCC65)},
      {'title': 'BIG BASS', 'genre': 'Slots', 'icon': Icons.waves, 'action': slots, 'a': Color(0xFF075985), 'b': Color(0xFF22D3EE)},
      {'title': 'DEMON POTS', 'genre': 'Slots', 'icon': Icons.whatshot, 'action': slots, 'a': Color(0xFF6A1020), 'b': Color(0xFFFF1744)},
      {'title': 'PHARAOH GOLD', 'genre': 'Slots', 'icon': Icons.account_balance, 'action': slots, 'a': Color(0xFF6D4C00), 'b': Color(0xFFFFC107)},
      {'title': 'CASH VAULT', 'genre': 'Slots', 'icon': Icons.account_balance_wallet, 'action': slots, 'a': Color(0xFF003B2F), 'b': Color(0xFF00C853)},
      {'title': 'FORTUNE ACE', 'genre': 'Slots', 'icon': Icons.style, 'action': slots, 'a': Color(0xFF5D1020), 'b': Color(0xFFD4AF37)},
      {'title': 'ZOMBIE NIGHT', 'genre': 'Slots', 'icon': Icons.nightlight_round, 'action': slots, 'a': Color(0xFF16213E), 'b': Color(0xFF6A1B9A)},
      {'title': 'RABBIT GARDEN', 'genre': 'Slots', 'icon': Icons.cruelty_free, 'action': slots, 'a': Color(0xFF3E2723), 'b': Color(0xFFFF8A65)},
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('SAJOMA', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 2, color: gold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(22), border: Border.all(color: gold.withOpacity(.45))),
                      child: Row(children: [
                        const Icon(Icons.monetization_on, color: gold, size: 18),
                        const SizedBox(width: 6),
                        Text('$balance', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                      ]),
                    ),
                    IconButton(onPressed: buyCoins, icon: const Icon(Icons.add_circle, color: gold)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 118,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(colors: [Color(0xFF211000), Color(0xFF5A3A00), Color(0xFF17110A)]),
                    border: Border.all(color: gold.withOpacity(.45)),
                  ),
                  child: Stack(children: [
                    Positioned(right: 18, top: 10, child: Icon(Icons.auto_awesome, size: 90, color: gold.withOpacity(.12))),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('BONO DIARIO', style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                        const SizedBox(height: 5),
                        const Text('Gira y recibe monedas virtuales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        SizedBox(height: 34, child: FilledButton.icon(onPressed: claimBonus, icon: const Icon(Icons.card_giftcard, size: 18), label: const Text('RECLAMAR'))),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip('Popular', true),
                      _chip('Slots', false),
                      _chip('Ruleta', false),
                      _chip('Blackjack', false),
                      _chip('Poker', false),
                      _chip('Más juegos', false),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Row(children: [
                  Expanded(child: Text('JUEGOS POPULARES', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
                  Icon(Icons.search, color: gold),
                ]),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final g = games[i];
                return _slotTile(g['title'] as String, g['genre'] as String, g['icon'] as IconData, g['action'] as VoidCallback, g['a'] as Color, g['b'] as Color);
              },
              childCount: games.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 9,
              mainAxisSpacing: 12,
              childAspectRatio: .66,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Column(children: [
              game(Icons.album, 'Ruleta', 'Ruleta virtual', roulette),
              game(Icons.style, 'Blackjack', '21 contra la casa', blackjack),
              game(Icons.diamond, 'Baccarat', 'Jugador, banca o empate', baccarat),
              game(Icons.casino_outlined, 'Craps', 'Dados virtuales', craps),
              game(Icons.grid_3x3, 'Keno', 'Elige 10 numeros', keno),
              game(Icons.style_outlined, 'Video Poker', 'Mano de cinco cartas', videoPoker),
              game(Icons.emoji_events, 'Carrera de caballos', 'Elige tu caballo', horses),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        label: Text(label),
        selectedColor: gold,
        backgroundColor: const Color(0xFF171717),
        side: BorderSide(color: selected ? gold : Colors.white12),
        labelStyle: TextStyle(color: selected ? Colors.black : Colors.white70, fontWeight: FontWeight.w700),
        onSelected: (_) {},
      ),
    );
  }

  Widget _slotTile(String title, String genre, IconData icon, VoidCallback action, Color a, Color b) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: action,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
              ),
              child: Stack(children: [
                Positioned(right: -10, top: -12, child: Icon(Icons.auto_awesome, size: 70, color: Colors.white.withOpacity(.15))),
                Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 48, color: Colors.white),
                  const SizedBox(height: 7),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, shadows: [Shadow(blurRadius: 5)])),
                ])),
              ]),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(9, 7, 9, 2), child: Text(genre, style: const TextStyle(color: Colors.white54, fontSize: 10))),
          Padding(padding: const EdgeInsets.fromLTRB(9, 0, 9, 9), child: Text(title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
        ]),
      ),
    );
  }

  Widget game(IconData icon, String title, String subtitle, VoidCallback action) {
    return Card(
      margin: const EdgeInsets.only(top: 9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: Icon(icon, size: 31, color: gold),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: gold),
        onTap: action,
      ),
    );
  }

  Widget historyPage() {
    if (history.isEmpty) {
      return const Center(child: Text('Aun no hay movimientos.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final h = history[i];
        final d = (h['d'] as num).toInt();
        return Card(
          child: ListTile(
            leading: Icon(d >= 0 ? Icons.add_circle : Icons.remove_circle, color: d >= 0 ? Colors.greenAccent : Colors.redAccent),
            title: Text(h['e'].toString()),
            trailing: Text('${d >= 0 ? '+' : ''}$d'),
          ),
        );
      },
    );
  }

  Widget missionsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('MISIONES', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Completa objetivos para ganar XP y monedas virtuales.', style: TextStyle(color: Colors.white60)),
        mission('Bono diario', 'Reclama tu bono de hoy', bonus, claimBonus),
        mission('Jugador activo', 'Juega 5 partidas', missions >= 5, () {
          if (missions < 5) {
            setState(() => missions++);
            save();
            snack('Partida registrada: $missions/5');
          } else {
            snack('Mision completada.');
          }
        }),
        mission('Primera victoria', 'Gana una partida', wins > 0, () => snack(wins > 0 ? 'Completada.' : 'Juega hasta conseguir una victoria.')),
        const SizedBox(height: 15),
        const Card(child: ListTile(leading: Icon(Icons.emoji_events, color: gold), title: Text('Torneo virtual semanal'), subtitle: Text('Clasificacion por XP - Sin dinero real'))),
      ],
    );
  }

  Widget mission(String title, String subtitle, bool done, VoidCallback action) {
    return Card(
      child: ListTile(
        leading: Icon(done ? Icons.check_circle : Icons.flag, color: done ? Colors.greenAccent : gold),
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
        const Center(child: Text('SAJOMA CASINO - Entretenimiento virtual', style: TextStyle(color: Colors.white38))),
      ],
    );
  }

  void editName() {
    final controller = TextEditingController(text: name);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Perfil'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nombre de jugador')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            setState(() => name = controller.text.trim().isEmpty ? 'Jugador' : controller.text.trim());
            save();
            Navigator.pop(dialogContext);
          }, child: const Text('Guardar')),
        ],
      ),
    );
  }

  void slots() {
    if (!canBet(100)) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final symbols = <String>['7', 'CROWN', 'DIAMOND', 'STAR', 'BELL', 'CHERRY', 'BAR', 'WILD'];
        List<List<String>> reels = List.generate(5, (c) => List.generate(3, (r) => symbols[(c + r) % symbols.length]));
        int bet = 100;
        bool busy = false;
        bool turbo = false;
        int lastWin = 0;

        String shortSymbol(String value) {
          switch (value) {
            case 'CROWN': return '♛';
            case 'DIAMOND': return '◆';
            case 'STAR': return '★';
            case 'BELL': return 'BEL';
            case 'CHERRY': return 'CHY';
            case 'BAR': return 'BAR';
            case 'WILD': return 'WILD';
            default: return value;
          }
        }

        Widget reelCell(String value, {bool center = false}) {
          return Expanded(
            child: Container(
              height: 72,
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: center
                      ? const [Color(0xFFFFE58A), Color(0xFFB8860B)]
                      : const [Color(0xFF151515), Color(0xFF29210E)],
                ),
                border: Border.all(color: gold, width: center ? 2 : 1),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
              ),
              child: FittedBox(
                child: Text(
                  shortSymbol(value),
                  style: TextStyle(
                    color: center ? Colors.black : gold,
                    fontSize: value == 'WILD' ? 24 : 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        }

        Widget infoBox(String label, String value) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: gold.withValues(alpha: 0.45)),
              ),
              child: Column(children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, color: gold, fontWeight: FontWeight.w900)),
              ]),
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, update) {
            Future<void> spin() async {
              if (busy || balance < bet) {
                if (balance < bet) {
                  Navigator.pop(dialogContext);
                  offerCoinsAfterLoss();
                }
                return;
              }
              update(() { busy = true; lastWin = 0; });
              final duration = turbo ? 250 : 800;
              await Future.delayed(Duration(milliseconds: duration));
              final next = List.generate(5, (_) => List.generate(3, (_) => symbols[rng.nextInt(symbols.length)]));
              final center = List.generate(5, (i) => next[i][1]);
              final counts = <String, int>{};
              for (final value in center) {
                counts[value] = (counts[value] ?? 0) + 1;
              }
              final maxCount = counts.values.reduce(max);
              int payout = 0;
              if (center.every((v) => v == 'WILD')) {
                payout = bet * 50;
              } else if (maxCount >= 5) {
                payout = bet * 25;
              } else if (maxCount == 4) {
                payout = bet * 10;
              } else if (maxCount == 3) {
                payout = bet * 5;
              } else if (maxCount == 2) {
                payout = bet * 2;
              }
              final net = payout - bet;
              update(() {
                reels = next;
                busy = false;
                lastWin = payout;
              });
              move(net, 'Tragamonedas: ${net >= 0 ? '+' : ''}$net', win: net > 0);
              if (net < 0) offerCoinsAfterLoss();
            }

            return Dialog.fullscreen(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF090909),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: gold, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 24, spreadRadius: 4)],
                ),
                child: SingleChildScrollView(
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF171000), Color(0xFF3A2700), Color(0xFF171000)]),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.workspace_premium, color: gold, size: 30),
                        const SizedBox(width: 8),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('SAJOMA RICHES', style: TextStyle(color: gold, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          Text('PREMIO MAYOR 50,000 COINS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        ])),
                        IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close, color: Colors.white70)),
                      ]),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1300),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: gold, width: 2),
                      ),
                      child: Column(children: [
                        const Text('WAYS 243', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        for (int row = 0; row < 3; row++)
                          Row(children: [for (int col = 0; col < 5; col++) reelCell(reels[col][row], center: row == 1)]),
                      ]),
                    ),
                    if (lastWin > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: gold),
                        ),
                        child: Text('GANASTE +$lastWin COINS', style: const TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.w900)),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 3),
                      child: Text('LINEA DE PAGO CENTRAL', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        infoBox('SALDO', '$balance'),
                        infoBox('APUESTA', '$bet'),
                        infoBox('GANANCIA', '$lastWin'),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      OutlinedButton(onPressed: busy || bet <= 100 ? null : () => update(() => bet -= 100), child: const Text('− APUESTA')),
                      const SizedBox(width: 8),
                      OutlinedButton(onPressed: busy ? null : () => update(() => turbo = !turbo), child: Text(turbo ? 'TURBO ON' : 'TURBO')),
                      const SizedBox(width: 8),
                      OutlinedButton(onPressed: busy ? null : () => update(() => bet += 100), child: const Text('+ APUESTA')),
                    ]),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 220,
                      height: 68,
                      child: FilledButton(
                        onPressed: busy ? null : spin,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1FA34A),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: gold, width: 3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
                        ),
                        child: busy
                            ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('SPIN', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                                Text('GIRA PARA GANAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                              ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF171717),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                      ),
                      child: const Text('MONEDAS VIRTUALES • ENTRETENIMIENTO', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ),
                  ]),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void roulette() {
    if (!canBet(100)) return;
    showGame('RULETA', (close) => Column(children: [
      const Text('Elige Rojo, Negro o Verde. Apuesta virtual de 100 coins.'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: FilledButton(onPressed: () => _roulettePlay('ROJO', close), child: const Text('ROJO'))),
        const SizedBox(width: 6),
        Expanded(child: FilledButton(onPressed: () => _roulettePlay('NEGRO', close), child: const Text('NEGRO'))),
        const SizedBox(width: 6),
        Expanded(child: FilledButton(onPressed: () => _roulettePlay('VERDE', close), child: const Text('VERDE'))),
      ]),
    ]));
  }

  void _roulettePlay(String pick, VoidCallback close) {
    final result = rng.nextInt(37);
    final color = result == 0 ? 'VERDE' : (result % 2 == 0 ? 'NEGRO' : 'ROJO');
    final reward = pick == color ? (color == 'VERDE' ? 3500 : 200) : -100;
    move(reward, 'Ruleta $result $color: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
    close();
    showResult('RULETA', 'Salio $result ($color).', reward);
    if (reward < 0) offerCoinsAfterLoss();
  }

  void blackjack() {
    if (!canBet(100)) return;
    showGame('BLACKJACK', (close) => Column(children: [
      const Text('Pide carta o plantate. Objetivo: acercarte a 21 sin pasarte.'),
      const SizedBox(height: 12),
      FilledButton(onPressed: () {
        final player = 15 + rng.nextInt(7);
        final dealer = 16 + rng.nextInt(6);
        final reward = player > 21 ? -100 : dealer > 21 || player > dealer ? 200 : player == dealer ? 0 : -100;
        move(reward, 'Blackjack jugador $player / casa $dealer: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
        close();
        showResult('BLACKJACK', 'Tu total: $player\nCasa: $dealer', reward);
        if (reward < 0) offerCoinsAfterLoss();
      }, child: const Text('JUGAR MANO - 100 COINS')),
    ]));
  }

  void poker() {
    if (!canBet(100)) return;
    showGame('POKER', (close) => Column(children: [
      const Text('Duelo virtual de manos. Una mano fuerte gana.'),
      const SizedBox(height: 12),
      FilledButton(onPressed: () {
        final player = 1 + rng.nextInt(10);
        final house = 1 + rng.nextInt(10);
        final reward = player > house ? 300 : player == house ? 0 : -100;
        move(reward, 'Poker $player vs $house: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
        close();
        showResult('POKER', 'Tu mano: $player\nCasa: $house', reward);
        if (reward < 0) offerCoinsAfterLoss();
      }, child: const Text('REPARTIR - 100 COINS')),
    ]));
  }

  void baccarat() {
    if (!canBet(100)) return;
    showGame('BACCARAT', (close) => Column(children: [
      const Text('Apuesta virtual en Jugador, Banca o Empate.'),
      const SizedBox(height: 12),
      ...['JUGADOR', 'BANCA', 'EMPATE'].map((pick) => Padding(padding: const EdgeInsets.only(bottom: 7), child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
        final result = ['JUGADOR', 'BANCA', 'EMPATE'][rng.nextInt(3)];
        final reward = pick == result ? (result == 'EMPATE' ? 800 : 200) : -100;
        move(reward, 'Baccarat $result: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
        close();
        showResult('BACCARAT', 'Resultado: $result', reward);
        if (reward < 0) offerCoinsAfterLoss();
      }, child: Text(pick))))),
    ]));
  }

  void craps() {
    if (!canBet(100)) return;
    showGame('CRAPS', (close) => Column(children: [
      FilledButton(onPressed: () {
        final d1 = 1 + rng.nextInt(6), d2 = 1 + rng.nextInt(6), total = d1 + d2;
        final win = total == 7 || total == 11;
        final reward = win ? 200 : -100;
        move(reward, 'Craps $d1+$d2=$total: ${reward >= 0 ? '+' : ''}$reward', win: win);
        close();
        showResult('CRAPS', 'Dados: $d1 + $d2 = $total', reward);
        if (reward < 0) offerCoinsAfterLoss();
      }, child: const Text('LANZAR DADOS - 100 COINS')),
    ]));
  }

  void keno() {
    if (!canBet(100)) return;
    final picks = <int>{};
    showGame('KENO', (close) => StatefulBuilder(builder: (dialogContext, update) {
      return Column(children: [
        Wrap(spacing: 5, runSpacing: 5, children: List.generate(40, (i) {
          final n = i + 1;
          return FilterChip(label: Text('$n'), selected: picks.contains(n), onSelected: (v) {
            update(() {
              if (v && picks.length < 10) picks.add(n);
              if (!v) picks.remove(n);
            });
          });
        })),
        const SizedBox(height: 12),
        Text('${picks.length}/10 seleccionados'),
        const SizedBox(height: 8),
        FilledButton(onPressed: picks.length != 10 ? null : () {
          final draw = <int>{};
          while (draw.length < 10) draw.add(1 + rng.nextInt(40));
          final hits = picks.intersection(draw).length;
          final table = [-100, -100, -100, 50, 100, 200, 500, 1000, 2500, 5000, 10000];
          final reward = table[hits];
          move(reward, 'Keno $hits aciertos: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
          close();
          showResult('KENO', 'Numeros sorteados: ${draw.toList()..sort()}\nAciertos: $hits', reward);
          if (reward < 0) offerCoinsAfterLoss();
        }, child: const Text('SORTEAR')),
      ]);
    }));
  }

  void videoPoker() {
    if (!canBet(100)) return;
    showGame('VIDEO POKER', (close) => Column(children: [
      const Text('Recibe cinco cartas virtuales y gana segun la fuerza de la mano.'),
      const SizedBox(height: 12),
      FilledButton(onPressed: () {
        final cards = List.generate(5, (_) => 2 + rng.nextInt(13));
        final rank = pokerRank(cards);
        final reward = rank >= 3 ? rank * 150 : -100;
        move(reward, 'Video Poker ${pokerName(rank)}: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
        close();
        showResult('VIDEO POKER', 'Cartas: ${cards.join(' - ')}\n${pokerName(rank)}', reward);
        if (reward < 0) offerCoinsAfterLoss();
      }, child: const Text('REPARTIR - 100 COINS')),
    ]));
  }

  int pokerRank(List<int> cards) {
    final counts = <int, int>{};
    for (final c in cards) counts[c] = (counts[c] ?? 0) + 1;
    final values = counts.values.toList()..sort((a, b) => b.compareTo(a));
    if (values.isNotEmpty && values.first == 4) return 5;
    if (values.isNotEmpty && values.first == 3 && values.length > 1 && values[1] == 2) return 4;
    if (values.isNotEmpty && values.first == 3) return 3;
    if (values.where((v) => v == 2).length >= 2) return 2;
    if (values.isNotEmpty && values.first == 2) return 1;
    return 0;
  }

  String pokerName(int rank) => ['Carta alta', 'Pareja', 'Dos pares', 'Trio', 'Full house', 'Poker'][rank];

  void horses() {
    if (!canBet(100)) return;
    showGame('CARRERA DE CABALLOS', (close) => Column(children: [
      const Text('Elige un caballo del 1 al 6.'),
      const SizedBox(height: 8),
      ...List.generate(6, (i) => Padding(padding: const EdgeInsets.only(bottom: 6), child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
        final winner = 1 + rng.nextInt(6);
        final win = winner == i + 1;
        final reward = win ? 500 : -100;
        move(reward, 'Carrera: caballo ganador $winner, tu caballo ${i + 1}: ${win ? '+500' : '-100'}', win: win);
        close();
        showResult('CARRERA', 'Ganador: caballo $winner\nTu caballo: ${i + 1}', reward);
        if (reward < 0) offerCoinsAfterLoss();
      }, child: Text('APOSTAR CABALLO ${i + 1}'))))),
    ]));
  }
}
