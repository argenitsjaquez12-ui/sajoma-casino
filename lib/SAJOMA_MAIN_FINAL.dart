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
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        close = () => Navigator.pop(dialogContext);
        return Dialog(
          backgroundColor: const Color(0xFF080808),
          insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: gold, width: 2),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5A2600), Color(0xFF18120A), Color(0xFF030303)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: gold, size: 30),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SAJOMA CASINO',
                                style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                            Text(title,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Text('$balance',
                          style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
                      IconButton(
                        onPressed: close,
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: content(close),
                  ),
                ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SALDO VIRTUAL', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 5),
              Text('$balance COINS', style: const TextStyle(color: gold, fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Nivel $level  -  $xp / 100 XP'),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: FilledButton.icon(onPressed: claimBonus, icon: const Icon(Icons.card_giftcard), label: const Text('BONO DIARIO'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: buyCoins, icon: const Icon(Icons.add), label: const Text('MONEDAS'))),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        const Text('JUEGOS', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
        game(Icons.casino, 'Tragamonedas', 'Gira y busca tres iguales', slots),
        game(Icons.album, 'Ruleta europea', '0 al 36', roulette),
        game(Icons.album, 'Ruleta americana', '0, 00 y colores', roulette),
        game(Icons.style, 'Blackjack', '21 contra la casa', blackjack),
        game(Icons.spade, 'Texas Holdem', 'Poker de cartas', poker),
        game(Icons.spade, 'Three Card Poker', 'Poker de tres cartas', () => casinoMiniGame('THREE CARD POKER')),
        game(Icons.spade, 'Caribbean Stud Poker', 'Poker contra la casa', () => casinoMiniGame('CARIBBEAN STUD')),
        game(Icons.diamond, 'Baccarat', 'Jugador, banca o empate', baccarat),
        game(Icons.casino_outlined, 'Craps', 'Dados virtuales', craps),
        game(Icons.casino, 'Sic Bo', 'Tres dados', () => casinoMiniGame('SIC BO')),
        game(Icons.casino, 'Casino War', 'Guerra de cartas', () => casinoMiniGame('CASINO WAR')),
        game(Icons.style_outlined, 'Pai Gow Poker', 'Poker asiatico', () => casinoMiniGame('PAI GOW')),
        game(Icons.grid_3x3, 'Keno', 'Elige 10 numeros', keno),
        game(Icons.confirmation_number, 'Bingo', 'Numeros y premios', () => casinoMiniGame('BINGO')),
        game(Icons.style_outlined, 'Video Poker', 'Mano de cinco cartas', videoPoker),
        game(Icons.change_history, 'Jacks or Better', 'Video poker clasico', () => casinoMiniGame('JACKS OR BETTER')),
        game(Icons.change_history_outlined, 'Deuces Wild', 'Video poker especial', () => casinoMiniGame('DEUCES WILD')),
        game(Icons.rotate_right, 'Wheel', 'Gira la rueda', () => casinoMiniGame('WHEEL')),
        game(Icons.circle, 'Plinko', 'Bola y multiplicadores', () => casinoMiniGame('PLINKO')),
        game(Icons.grid_on, 'Mines', 'Descubre casillas seguras', () => casinoMiniGame('MINES')),
        game(Icons.casino, 'Dice', 'Alto o bajo', () => casinoMiniGame('DICE')),
        game(Icons.swap_vert, 'High / Low', 'Adivina el siguiente numero', () => casinoMiniGame('HIGH / LOW')),
        game(Icons.emoji_events, 'Carrera de caballos', 'Elige tu caballo', horses),
        game(Icons.directions_run, 'Carrera de galgos', 'Elige tu galgo', () => casinoMiniGame('CARRERA DE GALGOS')),
        game(Icons.star, 'Jackpot', 'Premio mayor virtual', () => casinoMiniGame('JACKPOT')),
        game(Icons.military_tech, 'Jackpot progresivo', 'Gran premio virtual', () => casinoMiniGame('JACKPOT PROGRESIVO')),
        game(Icons.local_activity, 'Megaways', 'Slot de muchas combinaciones', () => casinoMiniGame('MEGAWAYS')),
        game(Icons.local_activity, 'Bonus Slots', 'Rondas bonus', () => casinoMiniGame('BONUS SLOTS')),
        game(Icons.style, 'Joker Poker', 'Video poker con comodin', () => casinoMiniGame('JOKER POKER')),
        game(Icons.style, 'Pai Gow', 'Juego de cartas', () => casinoMiniGame('PAI GOW')),
        game(Icons.casino, 'Wheel of Fortune', 'Rueda de premios', () => casinoMiniGame('WHEEL OF FORTUNE')), 
      ],
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
              close(); showResult('BLACKJACK', 'Tu total: $player\\nCasa: $dealer', reward);
              if (reward < 0) offerCoinsAfterLoss();
            }, color: Colors.green)),
            const SizedBox(width: 6),
            Expanded(child: neonButton('PLANTARSE', () {
              final player = 17 + rng.nextInt(5);
              final dealer = 16 + rng.nextInt(6);
              final reward = player > dealer ? 200 : player == dealer ? 0 : -100;
              move(reward, 'Blackjack plantado $player/$dealer: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
              close(); showResult('BLACKJACK', 'Tu total: $player\\nCasa: $dealer', reward);
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
    showGame('POKER TEXAS HOLD'EM', (close) => gameFelt(
      accent: Colors.deepPurpleAccent,
      child: Column(
        children: [
          const Text('TEXAS HOLD'EM', style: TextStyle(color: gold, fontSize: 26, fontWeight: FontWeight.w900)),
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
              close(); showResult('POKER', 'Tu mano: $player\\nRival: $house', reward);
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
              Text('DON'T COME     4   5   6   8   9   10', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
              showResult('KENO', 'Sorteados: ${draw.toList()..sort()}\\nAciertos: $hits', reward);
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
            showResult('VIDEO POKER', 'Mano: ${cards.join(' - ')}\\n${pokerName(rank)}', reward);
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
    if (t.contains('SIC BO') || t.contains('DICE') || t.contains('CRAPS')) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0D3B2E), Color(0xFF00120D)]),
          borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('⚄', style: TextStyle(fontSize: 70, color: Colors.white)),
          SizedBox(width: 18),
          Text('⚅', style: TextStyle(fontSize: 70, color: Colors.white)),
        ]),
      );
    }
    if (t.contains('WHEEL') || t.contains('WHEEL OF FORTUNE')) {
      return Container(
        width: 190, height: 190, alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: const SweepGradient(colors: [Colors.red, Colors.amber, Colors.green, Colors.blue, Colors.purple, Colors.red]), border: Border.all(color: gold, width: 6)),
        child: const Text('SAJOMA\\nWHEEL', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
      );
    }
    if (t.contains('MINES')) {
      return Wrap(spacing: 5, runSpacing: 5, children: List.generate(25, (i) => Container(
        width: 48, height: 48, alignment: Alignment.center,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF22304A), Color(0xFF0A101C)]), borderRadius: BorderRadius.circular(7), border: Border.all(color: Colors.blueAccent)),
        child: const Icon(Icons.diamond, color: Colors.cyanAccent),
      )));
    }
    if (t.contains('KENO') || t.contains('BINGO')) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF053A60), Color(0xFF020A18)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.cyanAccent)),
        child: Wrap(spacing: 5, runSpacing: 5, children: List.generate(30, (i) => Container(width: 35, height: 35, alignment: Alignment.center, color: Colors.blueGrey.shade900, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      );
    }
    if (t.contains('POKER') || t.contains('PAI GOW') || t.contains('WAR')) {
      return gameFelt(accent: Colors.deepPurpleAccent, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        casinoCard('A♠'), const SizedBox(width: 8), casinoCard('K♥', red: true), const SizedBox(width: 8), casinoCard('Q♣'),
      ]));
    }
    return Container(
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF5D1300), Color(0xFF1B0700), Color(0xFF001B3A)]),
        borderRadius: BorderRadius.circular(16), border: Border.all(color: gold, width: 2),
      ),
      child: Text(t, textAlign: TextAlign.center, style: const TextStyle(color: gold, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  void casinoMiniGame(String title) {
    if (!canBet(100)) return;
    showGame(title, (close) => Column(
      children: [
        miniVisual(title),
        const SizedBox(height: 14),
        Text(title.toUpperCase(), style: const TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Sala de juego SAJOMA con monedas virtuales.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 14),
        neonButton('JUGAR - 100 COINS', () {
          final roll = rng.nextInt(100);
          final reward = roll >= 82 ? 500 : (roll >= 55 ? 150 : -100);
          move(reward, '$title: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
          close();
          showResult(title, reward > 0 ? 'Ganaste monedas virtuales.' : 'Esta ronda no ganó.', reward);
          if (reward < 0) offerCoinsAfterLoss();
        }, color: Colors.green),
      ],
    ));
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
                  close(); showResult('CARRERA', 'Ganador: caballo $winner\\nTu caballo: ${i + 1}', reward);
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
