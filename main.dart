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
  Widget build(BuildContext context) => MaterialApp(
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
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Casino()));
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gold, width: 3)), child: const Icon(Icons.casino, size: 65, color: gold)),
          const SizedBox(height: 20), const Text('SAJOMA', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 7, color: gold)),
          const Text('CASINO', style: TextStyle(fontSize: 16, letterSpacing: 9)),
          const SizedBox(height: 20), const Text('ENTRETENIMIENTO CON MONEDAS VIRTUALES', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ])),
      );
}

class Casino extends StatefulWidget {
  const Casino({super.key});
  @override
  State<Casino> createState() => _CasinoState();
}

class _CasinoState extends State<Casino> {
  int balance = 125680, tab = 0, level = 1, xp = 0, wins = 0, missions = 0;
  String name = 'Jugador';
  bool bonus = false;
  final rng = Random();
  List<Map<String, dynamic>> history = [];

  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final h = p.getString('history');
    setState(() {
      balance = p.getInt('balance') ?? 125680; name = p.getString('name') ?? 'Jugador'; bonus = p.getBool('bonus') ?? false;
      level = p.getInt('level') ?? 1; xp = p.getInt('xp') ?? 0; wins = p.getInt('wins') ?? 0; missions = p.getInt('missions') ?? 0;
      if (h != null) history = List<Map<String, dynamic>>.from(jsonDecode(h));
    });
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('balance', balance); await p.setString('name', name); await p.setBool('bonus', bonus); await p.setInt('level', level); await p.setInt('xp', xp); await p.setInt('wins', wins); await p.setInt('missions', missions); await p.setString('history', jsonEncode(history));
  }
  void move(int amount, String event, {bool win = false}) {
    setState(() {
      balance = max(0, balance + amount);
      history.insert(0, {'e': event, 'd': amount, 't': DateTime.now().toIso8601String()});
      if (history.length > 150) history.removeLast();
      xp += 10 + (win ? 20 : 0); if (win) wins++;
      while (xp >= 100) { level++; xp -= 100; }
      missions = min(5, missions + 1);
    });
    save();
  }
  void snack(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  bool canBet(int bet) { if (balance < bet) { snack('No tienes suficientes monedas virtuales.'); buyCoins(); return false; } return true; }

  void buyCoins() {
    showDialog<void>(context: context, builder: (_) => AlertDialog(
      title: const Text('COMPRAR MONEDAS'),
      content: const Text('Monedas 100% virtuales. No son dinero real y no se pueden retirar. Esta pantalla es una demostracion.'),
      actions: [
        _pack('10,000', 10000, '0.99'), _pack('50,000', 50000, '3.99'), _pack('150,000', 150000, '9.99'), _pack('500,000', 500000, '19.99'),
      ],
    ));
  }
  Widget _pack(String a, int coins, String price) => SizedBox(width: double.infinity, child: Padding(padding: const EdgeInsets.only(top: 5), child: FilledButton(onPressed: () { Navigator.pop(context); move(coins, 'Paquete virtual +$a'); snack('Demo: se añadieron $a monedas.'); }, child: Text('$a monedas  -  \$$price'))));
  void claimBonus() { if (bonus) { snack('El bono de hoy ya fue reclamado.'); return; } setState(() => bonus = true); move(500, 'Bono diario +500'); snack('Bono diario: +500 monedas virtuales.'); }

  @override
  Widget build(BuildContext context) {
    final pages = [home(), History(history: history), missionsPage(), profile()];
    return Scaffold(
      appBar: AppBar(title: const Text('SAJOMA CASINO', style: TextStyle(color: gold, fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: editName, icon: const Icon(Icons.person_outline)), Padding(padding: const EdgeInsets.only(right: 14), child: Center(child: Text('COINS $balance', style: const TextStyle(color: gold, fontWeight: FontWeight.bold))))]),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.casino_outlined), selectedIcon: Icon(Icons.casino), label: 'Casino'), NavigationDestination(icon: Icon(Icons.history), label: 'Historial'), NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Misiones'), NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil')]),
    );
  }

  Widget home() => ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [const CircleAvatar(radius: 28, backgroundColor: gold, child: Icon(Icons.person, color: Colors.black)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bienvenido, $name', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), Text('Nivel $level  |  $xp/100 XP', style: const TextStyle(color: Colors.white60))])), IconButton(onPressed: claimBonus, icon: Icon(Icons.card_giftcard, color: bonus ? Colors.grey : gold))]))),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('SALDO VIRTUAL', style: TextStyle(color: Colors.white60, letterSpacing: 2)), Text('$balance COINS', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: gold)), const SizedBox(height: 8), LinearProgressIndicator(value: xp / 100, minHeight: 7), const SizedBox(height: 12), OutlinedButton.icon(onPressed: buyCoins, icon: const Icon(Icons.add_circle_outline), label: const Text('COMPRAR MONEDAS VIRTUALES'))]))),
    const SizedBox(height: 18), const Text('JUEGOS DE CASINO', style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 2)),
    game(Icons.local_activity, 'Tragamonedas', 'Multiplicadores, bonus y giros', slots), game(Icons.circle, 'Ruleta Europea', '0-36, rojo/negro y docenas', () => roulette(false)), game(Icons.circle_outlined, 'Ruleta Americana', '0, 00 y apuestas clasicas', () => roulette(true)),
    game(Icons.style, 'Blackjack', 'Pide carta, planta o dobla', blackjack), game(Icons.diamond, 'Poker', 'Mano contra la banca virtual', poker), game(Icons.account_balance, 'Baccarat', 'Jugador, Banca o Empate', baccarat),
    game(Icons.casino_outlined, 'Craps', 'Pass line y dados virtuales', craps), game(Icons.grid_3x3, 'Keno', 'Elige numeros y busca aciertos', keno), game(Icons.star_border, 'Video Poker', '5 cartas y combinaciones', videoPoker),
    game(Icons.directions_run, 'Carrera de Caballos', 'Elige caballo y corre por premio', horses),
  ]);
  Widget game(IconData icon, String title, String sub, VoidCallback action) => Card(margin: const EdgeInsets.only(top: 8), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7), leading: CircleAvatar(backgroundColor: gold.withOpacity(.15), child: Icon(icon, color: gold)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(sub), trailing: const Icon(Icons.chevron_right, color: gold), onTap: action));

  Widget missionsPage() => ListView(padding: const EdgeInsets.all(16), children: [const Text('TORNEOS Y MISIONES', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('Todo usa monedas virtuales sin valor monetario.', style: TextStyle(color: Colors.white60)), mission('Bono diario', 'Reclama 500 coins', bonus, claimBonus), mission('Jugador activo', 'Juega 5 partidas', missions >= 5, () => snack('Juega partidas para completar esta mision.')), mission('Primera victoria', 'Gana una partida', wins > 0, () => snack(wins > 0 ? 'Mision completada.' : 'Todavia no has ganado.')), const Card(child: ListTile(leading: Icon(Icons.emoji_events, color: gold), title: Text('Torneo virtual semanal'), subtitle: Text('Clasificacion por XP - sin dinero real')))]);
  Widget mission(String title, String sub, bool done, VoidCallback action) => Card(child: ListTile(leading: Icon(done ? Icons.check_circle : Icons.flag, color: done ? Colors.greenAccent : gold), title: Text(title), subtitle: Text(done ? 'Completada' : sub), trailing: done ? null : FilledButton(onPressed: action, child: const Text('JUGAR'))));
  Widget profile() => ListView(padding: const EdgeInsets.all(18), children: [const SizedBox(height: 10), const Center(child: CircleAvatar(radius: 52, backgroundColor: gold, child: Icon(Icons.person, size: 58, color: Colors.black))), const SizedBox(height: 14), Center(child: Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))), Center(child: Text('Nivel $level', style: const TextStyle(color: gold))), const SizedBox(height: 20), ListTile(leading: const Icon(Icons.account_balance_wallet, color: gold), title: const Text('Monedas virtuales'), trailing: Text('$balance')), ListTile(leading: const Icon(Icons.emoji_events, color: gold), title: const Text('Victorias'), trailing: Text('$wins')), ListTile(leading: const Icon(Icons.star, color: gold), title: const Text('XP'), trailing: Text('$xp / 100')), ListTile(leading: const Icon(Icons.edit, color: gold), title: const Text('Cambiar nombre'), onTap: editName), const SizedBox(height: 20), const Center(child: Text('SAJOMA CASINO - SOLO ENTRETENIMIENTO VIRTUAL', style: TextStyle(color: Colors.white38)))]);
  void editName() { final c = TextEditingController(text: name); showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Perfil'), content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Nombre de jugador')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () { setState(() => name = c.text.trim().isEmpty ? 'Jugador' : c.text.trim()); save(); Navigator.pop(context); }, child: const Text('Guardar'))])); }

  void slots() { if (!canBet(100)) return; showGame('TRAGAMONEDAS', (close) { List<int> r = [0, 1, 2]; return StatefulBuilder(builder: (ctx, up) => Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: r.map((x) => Container(width: 70, height: 75, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: gold), borderRadius: BorderRadius.circular(12)), child: Text(['7', 'BAR', 'STAR', 'BELL', 'CHERRY'][x], style: const TextStyle(fontWeight: FontWeight.bold, color: gold)))).toList()), const SizedBox(height: 18), FilledButton(onPressed: () { final a = List.generate(3, (_) => rng.nextInt(5)); final reward = a.every((x) => x == 0) ? 1800 : a.toSet().length == 1 ? 900 : a.toSet().length == 2 ? 250 : -100; up(() => r = a); move(reward, 'Slots ${reward >= 0 ? '+' : ''}$reward', win: reward > 0); close(); }, child: const Text('GIRAR 100 COINS'))])); }); }

  void roulette(bool american) { if (!canBet(100)) return; showGame(american ? 'RULETA AMERICANA' : 'RULETA EUROPEA', (close) => Column(mainAxisSize: MainAxisSize.min, children: [const Text('Elige tu apuesta'), Wrap(spacing: 8, children: ['ROJO', 'NEGRO', 'PAR', 'IMPAR', '0'].map((s) => OutlinedButton(onPressed: () { final n = rng.nextInt(american ? 38 : 37); final win = (s == '0' && n == 0) || (s == 'ROJO' && red(n)) || (s == 'NEGRO' && n > 0 && !red(n)) || (s == 'PAR' && n > 0 && n.isEven) || (s == 'IMPAR' && n.isOdd); final reward = win ? (s == '0' ? 3500 : 100) : -100; move(reward, 'Ruleta $n: $s ${reward >= 0 ? '+' : ''}$reward', win: win); close(); }, child: Text(s))).toList()), const SizedBox(height: 10), Text(american ? '0 - 36 + 00' : '0 - 36') ])); }
  bool red(int n) => [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36].contains(n);

  void blackjack() { if (!canBet(100)) return; showGame('BLACKJACK', (close) { List<int> p = [drawCard(), drawCard()], d = [drawCard(), drawCard()]; bool done = false; return StatefulBuilder(builder: (ctx, up) { int sum(List<int> a) { var s = a.fold(0, (x, y) => x + y); var aces = a.where((x) => x == 11).length; while (s > 21 && aces-- > 0) s -= 10; return s; } void finish() { if (done) return; done = true; while (sum(d) < 17) d.add(drawCard()); final ps = sum(p), ds = sum(d); final reward = ps > 21 ? -100 : (ds > 21 || ps > ds ? 100 : ps == ds ? 0 : -100); move(reward, 'Blackjack $ps vs $ds ${reward >= 0 ? '+' : ''}$reward', win: reward > 0); close(); } return Column(mainAxisSize: MainAxisSize.min, children: [Text('TU MANO: ${p.map(card).join('  ')}  = ${sum(p)}'), Text('BANCA: ${d.map(card).join('  ')}'), const SizedBox(height: 15), Wrap(spacing: 8, children: [FilledButton(onPressed: () { p.add(drawCard()); up(() {}); if (sum(p) > 21) finish(); }, child: const Text('PEDIR')), OutlinedButton(onPressed: finish, child: const Text('PLANTARSE')), OutlinedButton(onPressed: () { p.add(drawCard()); up(() {}); finish(); }, child: const Text('DOBLAR'))])]); }); }); }
  int drawCard() => [2,3,4,5,6,7,8,9,10,10,10,10,11][rng.nextInt(13)];
  String card(int n) => n == 11 ? 'A' : n.toString();

  void poker() { if (!canBet(100)) return; final vals = List.generate(5, (_) => 2 + rng.nextInt(13))..sort(); final rank = pokerRank(vals); final reward = rank >= 4 ? 300 + rank * 100 : -100; move(reward, 'Poker $rank ${reward >= 0 ? '+' : ''}$reward', win: reward > 0); showResult('POKER', 'Tus cartas: ${vals.map(card).join(' - ')}\nCombinacion: ${pokerName(rank)}\n${reward >= 0 ? 'Ganaste' : 'Perdiste'} ${reward.abs()} coins.', reward); }
  int pokerRank(List<int> v) { final m = <int,int>{}; for (final x in v) m[x] = (m[x] ?? 0) + 1; final counts = m.values.toList()..sort(); if (counts.last == 4) return 6; if (counts.last == 3 && counts.length == 2) return 5; if (counts.last == 3) return 4; if (counts.where((x) => x == 2).length == 2) return 3; if (counts.last == 2) return 2; return 1; }
  String pokerName(int r) => ['','Carta alta','Pareja','Doble pareja','Trio','Full','Poker'][r];

  void baccarat() { if (!canBet(100)) return; showGame('BACCARAT', (close) => Column(mainAxisSize: MainAxisSize.min, children: [const Text('Apuesta por el resultado'), Wrap(spacing: 8, children: ['JUGADOR','BANCA','EMPATE'].map((s) => FilledButton(onPressed: () { final p = rng.nextInt(10), b = rng.nextInt(10); final result = p == b ? 'EMPATE' : (p > b ? 'JUGADOR' : 'BANCA'); final win = s == result; final reward = win ? (s == 'EMPATE' ? 800 : 100) : -100; move(reward, 'Baccarat $result ${reward >= 0 ? '+' : ''}$reward', win: win); close(); showResult('BACCARAT', 'Jugador $p - Banca $b\nResultado: $result', reward); }, child: Text(s))).toList())])); }

  void craps() { if (!canBet(100)) return; showGame('CRAPS', (close) => Column(mainAxisSize: MainAxisSize.min, children: [const Text('Apuesta PASS LINE'), const SizedBox(height: 10), FilledButton(onPressed: () { final a=1+rng.nextInt(6), b=1+rng.nextInt(6), total=a+b; final win = [7,11].contains(total) || (total >= 4 && total <= 10 && total != 7 && rng.nextBool()); final reward = win ? 100 : -100; move(reward, 'Craps $a+$b=$total ${reward >= 0 ? '+' : ''}$reward', win: win); close(); showResult('CRAPS', 'Dados: $a + $b = $total', reward); }, child: const Text('LANZAR DADOS 100 COINS'))])); }

  void keno() {
    if (!canBet(100)) return;
    final picks = <int>{};
    showGame('KENO', (close) {
      return StatefulBuilder(
        builder: (ctx, up) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: List.generate(40, (i) {
                  final n = i + 1;
                  return FilterChip(
                    label: Text('$n'),
                    selected: picks.contains(n),
                    onSelected: picks.length >= 10 && !picks.contains(n)
                        ? null
                        : (v) {
                            up(() {
                              if (v) {
                                picks.add(n);
                              } else {
                                picks.remove(n);
                              }
                            });
                          },
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text('${picks.length}/10 seleccionados'),
              FilledButton(
                onPressed: picks.length != 10
                    ? null
                    : () {
                        final draw = <int>{};
                        while (draw.length < 10) {
                          draw.add(1 + rng.nextInt(40));
                        }
                        final hits = picks.intersection(draw).length;
                        final rewards = [-100, -100, -100, 50, 100, 200, 500, 1000, 2500, 5000, 10000];
                        final reward = rewards[hits];
                        move(reward, 'Keno $hits aciertos ${reward >= 0 ? '+' : ''}$reward', win: reward > 0);
                        close();
                        showResult('KENO', 'Numeros sorteados: ${draw.toList()..sort()}\nAciertos: $hits', reward);
                      },
                child: const Text('SORTEAR'),
              ),
            ],
          );
        },
      );
    });
  }

  void videoPoker() { if (!canBet(100)) return; final cards=List.generate(5, (_) => 2+rng.nextInt(13)); final rank=pokerRank(cards..sort()); final reward=rank>=2 ? rank*150 : -100; move(reward, 'Video Poker ${pokerName(rank)} ${reward >= 0 ? '+' : ''}$reward', win: reward>0); showResult('VIDEO POKER', 'Cartas: ${cards.map(card).join(' - ')}\n$pokerName(rank)', reward); }

  void horses() { if (!canBet(100)) return; showGame('CARRERA DE CABALLOS', (close) => Column(mainAxisSize: MainAxisSize.min, children: [const Text('Elige un caballo'), ...List.generate(6, (i) => ListTile(leading: CircleAvatar(backgroundColor: gold, child: Text('${i+1}', style: const TextStyle(color: Colors.black))), title: Text('Caballo ${i+1}'), trailing: FilledButton(onPressed: () { final winner=1+rng.nextInt(6); final win=winner==i+1; final reward=win?500:-100; move(reward, 'Carrera: ganador $winner ${win ? '+500' : '-100'}', win: win); close(); showResult('CARRERA', 'Ganador: caballo $winner\nTu caballo: ${i+1}', reward); }, child: const Text('APOSTAR'))))])); }

  void showGame(String title, Widget Function(VoidCallback close) content) { late VoidCallback close; showDialog<void>(context: context, builder: (_) { close=() => Navigator.pop(context); return AlertDialog(title: Text(title, style: const TextStyle(color: gold, fontWeight: FontWeight.w900)), content: SingleChildScrollView(child: content(close))); }); }
  void showResult(String title, String text, int reward) { if (!mounted) return; showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text('$text\n\n${reward > 0 ? 'GANASTE +$reward' : reward < 0 ? 'PERDISTE ${reward.abs()}' : 'EMPATE'} COINS'), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('CONTINUAR'))])); }
}

class History extends StatelessWidget {
  final List<Map<String,dynamic>> history; const History({super.key, required this.history});
  @override Widget build(BuildContext context) { if(history.isEmpty) return const Center(child: Text('Todavia no hay movimientos.')); return ListView.builder(padding: const EdgeInsets.all(12), itemCount: history.length, itemBuilder: (_,i){final x=history[i], a=x['d'] as int; return Card(child: ListTile(leading: Icon(a>=0?Icons.arrow_upward:Icons.arrow_downward,color:a>=0?Colors.greenAccent:Colors.redAccent),title:Text(x['e']),subtitle:Text((x['t'] as String).replaceFirst('T',' ').split('.').first),trailing:Text('${a>=0?'+':''}$a',style:TextStyle(color:a>=0?Colors.greenAccent:Colors.redAccent,fontWeight:FontWeight.bold))));}); }
}
