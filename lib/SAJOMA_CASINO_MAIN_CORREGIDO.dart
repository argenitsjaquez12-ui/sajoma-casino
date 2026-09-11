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
        game(Icons.album, 'Ruleta', 'Ruleta virtual', roulette),
        game(Icons.style, 'Blackjack', '21 contra la casa', blackjack),
        game(Icons.style, 'Poker', 'Duelo virtual', poker),
        game(Icons.diamond, 'Baccarat', 'Jugador, banca o empate', baccarat),
        game(Icons.casino_outlined, 'Craps', 'Dados virtuales', craps),
        game(Icons.grid_3x3, 'Keno', 'Elige 10 numeros', keno),
        game(Icons.style_outlined, 'Video Poker', 'Mano de cinco cartas', videoPoker),
        game(Icons.emoji_events, 'Carrera de caballos', 'Elige tu caballo', horses),
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
    showGame('TRAGAMONEDAS', (close) {
      String a = 'A', b = 'B', c = 'C';
      bool busy = false;
      return StatefulBuilder(builder: (dialogContext, update) => Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _reel(a), _reel(b), _reel(c),
        ]),
        const SizedBox(height: 18),
        FilledButton(onPressed: busy ? null : () {
          update(() => busy = true);
          Future.delayed(const Duration(milliseconds: 450), () {
            final values = ['CHERRY', 'LEMON', 'BELL', 'STAR', 'SEVEN']..shuffle(rng);
            final result = [values[0], values[1], values[2]];
            final reward = result[0] == result[1] && result[1] == result[2] ? 1000 : (result[0] == result[1] || result[1] == result[2] || result[0] == result[2] ? 250 : -100);
            update(() { a = result[0]; b = result[1]; c = result[2]; busy = false; });
            move(reward, 'Tragamonedas: ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
            if (reward < 0) offerCoinsAfterLoss();
          });
        }, child: const Text('GIRAR - 100 COINS')),
      ]));
    });
  }

  Widget _reel(String value) => Container(width: 78, height: 78, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: gold), borderRadius: BorderRadius.circular(12)), child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: gold, fontWeight: FontWeight.bold)));

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
