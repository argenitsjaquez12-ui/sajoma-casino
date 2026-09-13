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
      barrierColor: Colors.black.withOpacity(.94),
      builder: (dialogContext) {
        close = () => Navigator.pop(dialogContext);
        return Dialog.fullscreen(
          backgroundColor: const Color(0xFF050505),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF6B2E00), Color(0xFF17110A), Color(0xFF050505)]),
                    border: Border(bottom: BorderSide(color: gold, width: 1.5)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.workspace_premium, color: gold, size: 31),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('SAJOMA CASINO', style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                    ])),
                    Text('$balance', style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
                    IconButton(onPressed: close, icon: const Icon(Icons.close, color: Colors.white70, size: 29)),
                  ]),
                ),
                Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 14, 12, 24), child: content(close))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget gameFelt({required Widget child, Color accent = gold}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071A12), Color(0xFF003D2B), Color(0xFF020806)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18)],
      ),
      child: child,
    );
  }

  Widget neonButton(String label, VoidCallback? onPressed, {Color color = gold}) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Colors.white.withOpacity(.35)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget casinoCard(String text, {bool red = false, double width = 62, double height = 82}) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.black87, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: red ? Colors.red.shade700 : Colors.black87,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
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
    final sections = <String, List<List<dynamic>>>{
      'TRAGAMONEDAS POPULARES': [
        [Icons.diamond, 'DIAMOND RICHES', slots], [Icons.local_fire_department, 'GOLDEN DRAGON', () => casinoMiniGame('GOLDEN DRAGON')],
        [Icons.pets, 'BUFFALO KING', () => casinoMiniGame('BUFFALO KING')], [Icons.auto_awesome, 'SWEET BONUS', () => casinoMiniGame('SWEET BONUS')],
        [Icons.temple_buddhist, 'GATES OF OLYMPUS', () => casinoMiniGame('GATES OF OLYMPUS')], [Icons.nightlife, 'WOLF GOLD', () => casinoMiniGame('WOLF GOLD')],
        [Icons.account_balance, 'EGYPTIAN QUEEN', () => casinoMiniGame('EGYPTIAN QUEEN')], [Icons.menu_book, 'BOOK OF OPERA', () => casinoMiniGame('BOOK OF OPERA')],
      ],
      'JUEGOS DE MESA': [
        [Icons.album, 'RULETA', roulette], [Icons.style, 'BLACKJACK', blackjack], [Icons.diamond_outlined, 'BACCARAT', baccarat], [Icons.casino, 'CRAPS', craps],
        [Icons.style_outlined, 'TEXAS HOLD\'EM', poker], [Icons.casino_outlined, 'SIC BO', () => casinoMiniGame('SIC BO')], [Icons.style, 'CASINO WAR', () => casinoMiniGame('CASINO WAR')], [Icons.style, 'THREE CARD POKER', () => casinoMiniGame('THREE CARD POKER')],
      ],
      'JUEGOS ESPECIALES': [
        [Icons.grid_3x3, 'KENO', keno], [Icons.confirmation_number, 'BINGO', () => casinoMiniGame('BINGO')], [Icons.change_history, 'PLINKO', () => casinoMiniGame('PLINKO')], [Icons.bubble_chart, 'MINES', () => casinoMiniGame('MINES')],
        [Icons.casino, 'DICE', () => casinoMiniGame('DICE')], [Icons.style_outlined, 'VIDEO POKER', videoPoker], [Icons.rotate_right, 'WHEEL', () => casinoMiniGame('WHEEL')], [Icons.local_activity, 'SCRATCH', () => casinoMiniGame('SCRATCH')],
      ],
      'JACKPOTS Y ESPECIALES': [
        [Icons.star, 'MEGA JACKPOT', () => casinoMiniGame('MEGA JACKPOT')], [Icons.emoji_events, 'GRAND JACKPOT', () => casinoMiniGame('GRAND JACKPOT')], [Icons.workspace_premium, 'PROGRESSIVE', () => casinoMiniGame('JACKPOT PROGRESIVO')],
        [Icons.military_tech, 'MEGAWAYS', () => casinoMiniGame('MEGAWAYS')], [Icons.card_giftcard, 'BONUS SLOTS', () => casinoMiniGame('BONUS SLOTS')], [Icons.sports_esports, 'CARRERAS', horses],
        [Icons.support_agent, 'CASINO EN VIVO', () => casinoMiniGame('CASINO EN VIVO')], [Icons.emoji_events, 'TORNEOS', () => casinoMiniGame('TORNEOS')],
      ],
    };

    Widget section(String title, List<List<dynamic>> items) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 18, bottom: 9), child: Row(children: [
          const Icon(Icons.star, color: gold, size: 20), const SizedBox(width: 6),
          Expanded(child: Text(title, style: const TextStyle(color: gold, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: .7))),
          const Text('VER TODAS', style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900)),
        ])),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: 1.18),
          itemBuilder: (_, i) {
            final item = items[i]; final icon = item[0] as IconData; final name = item[1] as String; final action = item[2] as VoidCallback;
            final accents = [Colors.redAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.cyanAccent, Colors.greenAccent, Colors.blueAccent];
            final accent = accents[i % accents.length];
            return InkWell(onTap: action, borderRadius: BorderRadius.circular(16), child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF1B1B1B), const Color(0xFF070707)]),
                borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withOpacity(.9), width: 1.4),
                boxShadow: [BoxShadow(color: accent.withOpacity(.18), blurRadius: 12)],
              ),
              child: Stack(children: [
                Positioned(right: -12, top: -18, child: Icon(icon, size: 94, color: accent.withOpacity(.12))),
                Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 58, height: 58, decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(.16), border: Border.all(color: accent.withOpacity(.65))), child: Icon(icon, color: accent, size: 31)),
                  const SizedBox(height: 7), Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                ])),
              ]),
            ));
          },
        ),
      ]);
    }

    return ListView(padding: const EdgeInsets.fromLTRB(14, 12, 14, 24), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4A2200), Color(0xFF16120C)]), borderRadius: BorderRadius.circular(18), border: Border.all(color: gold, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SAJOMA CASINO', style: TextStyle(color: gold, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
          Text('BIENVENIDO, $name', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8), Row(children: [
            const Icon(Icons.monetization_on, color: gold), const SizedBox(width: 7), Text('$balance COINS', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const Spacer(), Text('VIP NIVEL $level', style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 10), LinearProgressIndicator(value: xp / 100, minHeight: 7, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(gold)),
          const SizedBox(height: 12), Row(children: [
            Expanded(child: neonButton('BONO DIARIO', claimBonus)), const SizedBox(width: 8), Expanded(child: neonButton('+ MONEDAS', buyCoins, color: Colors.black87)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6B0D0D), Color(0xFF170303)]), borderRadius: BorderRadius.circular(18), border: Border.all(color: gold, width: 1.5)), child: const Column(children: [
        Text('JACKPOT PROGRESIVO', style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
        SizedBox(height: 3), Text('1,250,680 COINS', style: TextStyle(color: Colors.amber, fontSize: 30, fontWeight: FontWeight.w900)),
        SizedBox(height: 4), Text('PREMIOS VIRTUALES • ENTRETENIMIENTO', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ])),
      for (final entry in sections.entries) section(entry.key, entry.value),
    ]);
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
    showGame('SAJOMA SLOTS', (close) {
      String a = '7', b = 'BAR', c = '7';
      bool busy = false;
      int bet = 100;
      final symbols = ['7', 'BAR', 'CHERRY', 'BELL', 'DIAMOND', 'STAR', 'LEMON'];
      return StatefulBuilder(builder: (dialogContext, update) {
        Widget reel(String value) {
          return Container(
            width: 88,
            height: 128,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF4D35E), Color(0xFF6D4300), Color(0xFFF7E39B)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: gold, width: 3),
              boxShadow: const [BoxShadow(color: Colors.orangeAccent, blurRadius: 12)],
            ),
            child: Container(
              margin: const EdgeInsets.all(5),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
              child: Text(value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900)),
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF5C0808), Color(0xFF130000)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: gold, width: 2),
              ),
              child: const Column(
                children: [
                  Text('SAJOMA RICHES', style: TextStyle(color: gold, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  SizedBox(height: 2),
                  Text('JACKPOT 1,250,680', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            gameFelt(
              accent: Colors.orangeAccent,
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [reel(a), reel(b), reel(c)]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10), border: Border.all(color: gold)),
                    child: const Text('7 = 1000     BAR = 500     DIAMANTE = 250     3 IGUALES = JACKPOT',
                        textAlign: TextAlign.center, style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: neonButton('− APUESTA', bet <= 100 ? null : () => update(() => bet -= 50))),
                const SizedBox(width: 8),
                Expanded(child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14), border: Border.all(color: gold)),
                  child: Text('$bet COINS', style: const TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.w900)),
                )),
                const SizedBox(width: 8),
                Expanded(child: neonButton('+ APUESTA', () => update(() => bet += 50))),
              ],
            ),
            const SizedBox(height: 10),
            neonButton(busy ? 'GIRANDO...' : 'GIRAR', busy ? null : () {
              if (!canBet(bet)) return;
              update(() => busy = true);
              Future.delayed(const Duration(milliseconds: 650), () {
                final values = List<String>.from(symbols)..shuffle(rng);
                final result = [values[0], values[1], values[2]];
                final reward = result[0] == result[1] && result[1] == result[2]
                    ? 1000
                    : (result[0] == result[1] || result[1] == result[2] || result[0] == result[2] ? 250 : -bet);
                update(() { a = result[0]; b = result[1]; c = result[2]; busy = false; });
                move(reward, 'SAJOMA SLOTS: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
                if (reward < 0) offerCoinsAfterLoss();
              });
            }, color: Colors.redAccent),
            const SizedBox(height: 8),
            const Text('MONEDAS VIRTUALES • ENTRETENIMIENTO',
                style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
          ],
        );
      });
    });
  }

  Widget _reel(String value) => Container(width: 78, height: 78, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: gold), borderRadius: BorderRadius.circular(12)), child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: gold, fontWeight: FontWeight.bold)));

  void roulette() {
    if (!canBet(100)) return;
    showGame('RULETA EUROPEA', (close) => gameFelt(
      accent: Colors.greenAccent,
      child: Column(
        children: [
          const Text('RULETA EUROPEA', style: TextStyle(color: gold, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [Color(0xFFD6B24C), Color(0xFF3B2500), Color(0xFF090909)]),
              border: Border.all(color: gold, width: 6),
              boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 20)],
            ),
            child: const Center(child: Text('0\n00\n1 2 3\n4 5 6', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            alignment: WrapAlignment.center,
            children: List.generate(37, (i) => Container(
              width: 35, height: 35, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == 0 ? Colors.green.shade700 : (i.isEven ? Colors.black : Colors.red.shade700),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: gold),
              ),
              child: Text('$i', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: neonButton('ROJO', () => _roulettePlay('ROJO', close), color: Colors.redAccent)),
            const SizedBox(width: 6),
            Expanded(child: neonButton('NEGRO', () => _roulettePlay('NEGRO', close), color: Colors.blueGrey)),
            const SizedBox(width: 6),
            Expanded(child: neonButton('VERDE 0', () => _roulettePlay('VERDE', close), color: Colors.green)),
          ]),
        ],
      ),
    ));
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
    showGame('BLACKJACK', (close) => gameFelt(
      accent: Colors.greenAccent,
      child: Column(
        children: [
          const Text('BLACKJACK', style: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.w900)),
          const Text('21 CONTRA LA CASA', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          const Text('DEALER', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            casinoCard('?', red: true),
            const SizedBox(width: 8),
            casinoCard('K♠'),
          ]),
          const SizedBox(height: 18),
          const Text('TU MANO', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            casinoCard('A♠'),
            const SizedBox(width: 8),
            casinoCard('7♥', red: true),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: neonButton('PEDIR', () {
              final player = 15 + rng.nextInt(7);
              final dealer = 16 + rng.nextInt(6);
              final reward = player > 21 ? -100 : dealer > 21 || player > dealer ? 200 : player == dealer ? 0 : -100;
              move(reward, 'Blackjack $player/$dealer: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
              close(); showResult('BLACKJACK', 'Tu total: $player\nCasa: $dealer', reward);
              if (reward < 0) offerCoinsAfterLoss();
            }, color: Colors.green)),
            const SizedBox(width: 6),
            Expanded(child: neonButton('PLANTARSE', () {
              final player = 17 + rng.nextInt(5);
              final dealer = 16 + rng.nextInt(6);
              final reward = player > dealer ? 200 : player == dealer ? 0 : -100;
              move(reward, 'Blackjack plantado $player/$dealer: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
              close(); showResult('BLACKJACK', 'Tu total: $player\nCasa: $dealer', reward);
              if (reward < 0) offerCoinsAfterLoss();
            }, color: Colors.blue)),
            const SizedBox(width: 6),
            Expanded(child: neonButton('DOBLAR', () {
              final win = rng.nextBool();
              final reward = win ? 400 : -200;
              move(reward, 'Blackjack DOBLAR: ${reward >= 0 ? '+' : ''}$reward', win: win);
              close(); showResult('BLACKJACK', win ? 'Ganaste al doblar.' : 'La casa ganó.', reward);
              if (reward < 0) offerCoinsAfterLoss();
            }, color: Colors.redAccent)),
          ]),
        ],
      ),
    ));
  }

  void poker() {
    if (!canBet(100)) return;
    showGame("POKER TEXAS HOLD'EM", (close) => gameFelt(
      accent: Colors.deepPurpleAccent,
      child: Column(
        children: [
          const Text("TEXAS HOLD'EM", style: TextStyle(color: gold, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text('MESA DE JUEGO', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            casinoCard('A♠'), const SizedBox(width: 4), casinoCard('K♦', red: true),
            const SizedBox(width: 4), casinoCard('Q♣'), const SizedBox(width: 4),
            casinoCard('J♥', red: true), const SizedBox(width: 4), casinoCard('10♠'),
          ]),
          const SizedBox(height: 16),
          const Text('TU MANO', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            casinoCard('K♠'), const SizedBox(width: 8), casinoCard('K♥', red: true),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12), border: Border.all(color: gold)),
            child: const Text('BOTE: 2,450 COINS', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: neonButton('FOLD', () {
              move(-100, 'Poker Fold: -100'); close(); showResult('POKER', 'Retiraste la mano.', -100); offerCoinsAfterLoss();
            }, color: Colors.redAccent)),
            const SizedBox(width: 6),
            Expanded(child: neonButton('CALL 100', () {
              final player = 1 + rng.nextInt(10), house = 1 + rng.nextInt(10);
              final reward = player > house ? 300 : player == house ? 0 : -100;
              move(reward, 'Poker $player vs $house: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
              close(); showResult('POKER', 'Tu mano: $player\nRival: $house', reward);
              if (reward < 0) offerCoinsAfterLoss();
            }, color: Colors.blue)),
            const SizedBox(width: 6),
            Expanded(child: neonButton('RAISE', () {
              final win = rng.nextBool();
              final reward = win ? 500 : -200;
              move(reward, 'Poker Raise: ${reward >= 0 ? '+' : ''}$reward', win: win);
              close(); showResult('POKER', win ? 'Tu rival se retiró.' : 'Tu rival ganó.', reward);
              if (reward < 0) offerCoinsAfterLoss();
            }, color: Colors.green)),
          ]),
        ],
      ),
    ));
  }

  void baccarat() {
    if (!canBet(100)) return;
    showGame('BACCARAT', (close) => gameFelt(
      accent: Colors.redAccent,
      child: Column(
        children: [
          const Text('BACCARAT', style: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF4A0010), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent)),
              child: Column(children: [
                const Text('PLAYER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [casinoCard('9♠'), const SizedBox(width: 5), casinoCard('7♣')]),
                const Text('TOTAL 6', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
              ]),
            )),
            const SizedBox(width: 8),
            Expanded(child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF0B1D4D), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.blueAccent)),
              child: Column(children: [
                const Text('BANKER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [casinoCard('K♦', red: true), const SizedBox(width: 5), casinoCard('4♥', red: true)]),
                const Text('TOTAL 4', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
              ]),
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: neonButton('PLAYER 1:1', () => _baccaratPlay('JUGADOR', close), color: Colors.blue)),
            const SizedBox(width: 5),
            Expanded(child: neonButton('EMPATE 8:1', () => _baccaratPlay('EMPATE', close), color: Colors.amber)),
            const SizedBox(width: 5),
            Expanded(child: neonButton('BANKER 0.95:1', () => _baccaratPlay('BANCA', close), color: Colors.redAccent)),
          ]),
        ],
      ),
    ));
  }

  void _baccaratPlay(String pick, VoidCallback close) {
    final result = ['JUGADOR', 'BANCA', 'EMPATE'][rng.nextInt(3)];
    final reward = pick == result ? (result == 'EMPATE' ? 800 : 200) : -100;
    move(reward, 'Baccarat $result: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
    close();
    showResult('BACCARAT', 'Resultado: $result', reward);
    if (reward < 0) offerCoinsAfterLoss();
  }

  void craps() {
    if (!canBet(100)) return;
    showGame('CRAPS', (close) => gameFelt(
      accent: Colors.redAccent,
      child: Column(
        children: [
          const Text('CRAPS', style: TextStyle(color: gold, fontSize: 30, fontWeight: FontWeight.w900)),
          const Text('MESA DE DADOS', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF064E3B), borderRadius: BorderRadius.circular(14), border: Border.all(color: gold)),
            child: const Column(children: [
              Text("DON'T COME     4   5   6   8   9   10", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              SizedBox(height: 12),
              Text('COME', style: TextStyle(color: Colors.redAccent, fontSize: 25, fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text('PASS LINE', style: TextStyle(color: gold, fontSize: 25, fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 70, height: 70, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Text('⚄', style: TextStyle(fontSize: 48, color: Colors.black))),
            const SizedBox(width: 15),
            Container(width: 70, height: 70, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Text('⚅', style: TextStyle(fontSize: 48, color: Colors.black))),
          ]),
          const SizedBox(height: 15),
          neonButton('LANZAR DADOS - 100 COINS', () {
            final d1 = 1 + rng.nextInt(6), d2 = 1 + rng.nextInt(6), total = d1 + d2;
            final win = total == 7 || total == 11;
            final reward = win ? 200 : -100;
            move(reward, 'Craps $d1+$d2=$total: ${reward >= 0 ? '+' : ''}$reward', win: win);
            close(); showResult('CRAPS', 'Dados: $d1 + $d2 = $total', reward);
            if (reward < 0) offerCoinsAfterLoss();
          }, color: Colors.redAccent),
        ],
      ),
    ));
  }

  void keno() {
    if (!canBet(100)) return;
    final picks = <int>{};
    showGame('KENO', (close) => StatefulBuilder(builder: (dialogContext, update) {
      return gameFelt(
        accent: Colors.cyanAccent,
        child: Column(
          children: [
            const Text('SAJOMA KENO', style: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.w900)),
            const Text('SELECCIONA 10 NÚMEROS', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Wrap(spacing: 4, runSpacing: 4, children: List.generate(80, (i) {
              final n = i + 1;
              final selected = picks.contains(n);
              return InkWell(
                onTap: () => update(() {
                  if (selected) picks.remove(n);
                  else if (picks.length < 10) picks.add(n);
                }),
                child: Container(
                  width: 34, height: 34, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected ? const LinearGradient(colors: [Colors.cyan, Colors.blue]) : null,
                    color: selected ? null : const Color(0xFF071D2A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: selected ? Colors.cyanAccent : Colors.white24),
                  ),
                  child: Text('$n', style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.w800)),
                ),
              );
            })),
            const SizedBox(height: 10),
            Text('${picks.length}/10 SELECCIONADOS', style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            neonButton('JUGAR KENO - 100 COINS', picks.length == 10 ? () {
              final draw = <int>{};
              while (draw.length < 20) draw.add(1 + rng.nextInt(80));
              final hits = picks.intersection(draw).length;
              final table = [-100, -100, -100, 25, 50, 100, 250, 500, 1000, 2500, 10000];
              final reward = table[min(hits, 10)];
              move(reward, 'Keno $hits aciertos: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
              close();
              showResult('KENO', 'Sorteados: ${draw.toList()..sort()}\nAciertos: $hits', reward);
              if (reward < 0) offerCoinsAfterLoss();
            } : null),
          ],
        ),
      );
    }));
  }

  void videoPoker() {
    if (!canBet(100)) return;
    showGame('VIDEO POKER', (close) => gameFelt(
      accent: Colors.blueAccent,
      child: Column(
        children: [
          const Text('JACKS OR BETTER', style: TextStyle(color: gold, fontSize: 25, fontWeight: FontWeight.w900)),
          const Text('DRAW POKER', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            casinoCard('J♠'), casinoCard('J♥', red: true), casinoCard('8♣'), casinoCard('4♦', red: true), casinoCard('2♠'),
          ]),
          const SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) =>
            FilterChip(label: const Text('HOLD'), selected: false, onSelected: (_) {}))),
          const SizedBox(height: 12),
          neonButton('DEAL / DRAW - 100 COINS', () {
            final cards = List.generate(5, (_) => 2 + rng.nextInt(13));
            final rank = pokerRank(cards);
            final reward = rank >= 3 ? rank * 150 : -100;
            move(reward, 'Video Poker ${pokerName(rank)}: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
            close();
            showResult('VIDEO POKER', 'Mano: ${cards.join(' - ')}\n${pokerName(rank)}', reward);
            if (reward < 0) offerCoinsAfterLoss();
          }, color: Colors.blueAccent),
        ],
      ),
    ));
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

  Widget miniVisual(String title) {
    final t = title.toUpperCase();
    Widget panel(Widget child, Color accent, {double height = 175}) {
      return Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF171717), Color(0xFF050505)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent, width: 2),
        ),
        child: child,
      );
    }
    Widget chip(String text, Color accent) {
      return Container(
        width: 42,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      );
    }

    if (t.contains('MINES')) {
      return panel(
        Wrap(spacing: 6, runSpacing: 6, children: List.generate(20, (i) => chip('◆', Colors.cyanAccent))),
        Colors.cyanAccent,
        height: 190,
      );
    }
    if (t.contains('KENO')) {
      return panel(
        Wrap(spacing: 5, runSpacing: 5, children: List.generate(30, (i) => chip('${i + 1}', Colors.cyanAccent))),
        Colors.cyanAccent,
        height: 220,
      );
    }
    if (t.contains('BINGO')) {
      return panel(
        Column(children: [
          const Text('B   I   N   G   O', style: TextStyle(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: List.generate(25, (i) => chip('${i + 1}', Colors.purpleAccent))),
        ]),
        Colors.purpleAccent,
        height: 220,
      );
    }
    if (t.contains('WHEEL')) {
      return Center(
        child: Container(
          width: 190,
          height: 190,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(colors: [Colors.red, Colors.black, Colors.amber, Colors.green, Colors.black, Colors.red]),
            border: Border.all(color: gold, width: 7),
          ),
          child: const Text('SAJOMA\nWHEEL', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ),
      );
    }
    if (t.contains('PLINKO')) {
      return panel(
        Column(children: [
          const Text('PLINKO', style: TextStyle(color: Colors.orangeAccent, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Wrap(spacing: 9, runSpacing: 8, children: List.generate(28, (i) => const Icon(Icons.circle, size: 9, color: Colors.white54))),
        ]),
        Colors.orangeAccent,
        height: 210,
      );
    }
    if (t.contains('DICE') || t.contains('CRAPS') || t.contains('SIC BO')) {
      return panel(
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          casinoCard('⚄'),
          const SizedBox(width: 18),
          casinoCard('⚅'),
        ]),
        gold,
      );
    }
    if (t.contains('BACCARAT')) {
      return gameFelt(
        accent: Colors.redAccent,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Column(children: [const Text('PLAYER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900)), casinoCard('K♠')]),
          Column(children: [const Text('BANKER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900)), casinoCard('7♥', red: true)]),
        ]),
      );
    }
    if (t.contains('POKER') || t.contains('PAI GOW') || t.contains('WAR')) {
      return gameFelt(
        accent: Colors.deepPurpleAccent,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          casinoCard('A♠'), const SizedBox(width: 6), casinoCard('K♥', red: true), const SizedBox(width: 6), casinoCard('Q♣'), const SizedBox(width: 6), casinoCard('J♦', red: true),
        ]),
      );
    }
    if (t.contains('VIDEO POKER') || t.contains('JACKS') || t.contains('DEUCES') || t.contains('JOKER')) {
      return gameFelt(
        accent: Colors.blueAccent,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          casinoCard('10♠'), const SizedBox(width: 4), casinoCard('J♥', red: true), const SizedBox(width: 4), casinoCard('Q♣'), const SizedBox(width: 4), casinoCard('K♦', red: true), const SizedBox(width: 4), casinoCard('A♠'),
        ]),
      );
    }
    if (t.contains('HORSE') || t.contains('GALGO') || t.contains('CARRERA')) {
      return panel(
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('SAJOMA RACING', style: TextStyle(color: gold, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: [
              Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Expanded(child: LinearProgressIndicator(value: (i + 2) / 5, minHeight: 8)),
              const SizedBox(width: 8),
              const Text('🏇', style: TextStyle(fontSize: 18)),
            ]),
          )),
        ]),
        Colors.greenAccent,
      );
    }
    if (t.contains('JACKPOT') || t.contains('MEGAWAYS') || t.contains('BONUS SLOTS')) {
      return panel(
        const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('MEGA JACKPOT', style: TextStyle(color: gold, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
          SizedBox(height: 8),
          Text('777   BAR   ★', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('1,250,680 COINS', style: TextStyle(color: Colors.amber, fontSize: 19, fontWeight: FontWeight.w900)),
        ]),
        Colors.redAccent,
      );
    }
    return panel(
      Center(child: Text(t, textAlign: TextAlign.center, style: const TextStyle(color: gold, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 1.3))),
      gold,
    );
  }

  void casinoMiniGame(String title) {
    if (!canBet(100)) return;
    int bet = 100;
    bool busy = false;
    showGame(title, (close) => StatefulBuilder(builder: (dialogContext, update) {
      return SingleChildScrollView(
        child: Column(children: [
          miniVisual(title),
          const SizedBox(height: 12),
          Text(title.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: gold, fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('MESA EXCLUSIVA SAJOMA • MONEDAS VIRTUALES', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: neonButton('− 50', bet <= 100 ? null : () => update(() => bet -= 50), color: Colors.black87)),
            const SizedBox(width: 7),
            Expanded(child: Container(height: 48, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: gold, width: 2), borderRadius: BorderRadius.circular(12)), child: Text('$bet COINS', style: const TextStyle(color: gold, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 7),
            Expanded(child: neonButton('+ 50', () => update(() => bet = min(bet + 50, 5000)), color: Colors.black87)),
          ]),
          const SizedBox(height: 9),
          neonButton(busy ? 'JUGANDO...' : 'JUGAR • $bet COINS', busy ? null : () {
            if (!canBet(bet)) return;
            update(() => busy = true);
            Future.delayed(const Duration(milliseconds: 650), () {
              final roll = rng.nextInt(100);
              final reward = roll >= 88 ? bet * 5 : (roll >= 62 ? bet * 2 : -bet);
              update(() => busy = false);
              move(reward, '$title: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
              close();
              showResult(title, reward > 0 ? '¡Ganaste monedas virtuales!' : 'Esta ronda no ganó.', reward);
              if (reward < 0) offerCoinsAfterLoss();
            });
          }, color: Colors.redAccent),
          const SizedBox(height: 7),
          const Text('ENTRETENIMIENTO • SIN DINERO REAL • SIN RETIROS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800)),
        ]),
      );
    }));
  }

  void horses() {
    if (!canBet(100)) return;
    showGame('CARRERA DE CABALLOS', (close) => Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF102D12), Color(0xFF071007)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text('SAJOMA RACING', style: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.w900)),
          const Text('HIPÓDROMO VIRTUAL', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ...List.generate(6, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: i.isEven ? const Color(0xFF214B24) : const Color(0xFF18381B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(children: [
                Container(width: 34, height: 34, alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900))),
                const SizedBox(width: 10),
                Expanded(child: Text('CABALLO ${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                SizedBox(width: 100, child: neonButton('APOSTAR', () {
                  final winner = 1 + rng.nextInt(6);
                  final win = winner == i + 1;
                  final reward = win ? 500 : -100;
                  move(reward, 'Carrera caballo $winner: ${win ? '+500' : '-100'}', win: win);
                  close(); showResult('CARRERA', 'Ganador: caballo $winner\nTu caballo: ${i + 1}', reward);
                  if (reward < 0) offerCoinsAfterLoss();
                }, color: i.isEven ? Colors.green : Colors.blue)),
              ]),
            ),
          )),
        ],
      ),
    ));
  }

}
