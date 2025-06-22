import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlayerDetailScreen extends StatefulWidget {
  final String name;
  final String tag;

  PlayerDetailScreen({required this.name, required this.tag});

  @override
  _PlayerDetailScreenState createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  String? imageUrl;
  int? accountLevel;
  String? error;
  List<int> eloHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchPlayerData();
  }

  Future<void> _fetchPlayerData() async {
    try {
      final playerUrl = Uri.parse(
          'https://api.henrikdev.xyz/valorant/v1/account/${widget.name}/${widget.tag}?api_key=HDEV-0447c677-7e5c-41cf-b5e9-1cbdb2aa521b');
      final playerResp = await http.get(playerUrl);

      final histUrl = Uri.parse(
          'https://api.henrikdev.xyz/valorant/v1/mmr-history/na/${widget.name}/${widget.tag}?api_key=HDEV-0447c677-7e5c-41cf-b5e9-1cbdb2aa521b');
      final histResp = await http.get(histUrl);

      if (playerResp.statusCode == 200 && histResp.statusCode == 200) {
        final playerJson = jsonDecode(playerResp.body);
        final data = playerJson['data'];
        imageUrl = data['card']['large'];
        accountLevel = data['account_level'];

        final histJson = jsonDecode(histResp.body);
        final List history = histJson['data'];
        eloHistory = history.map<int>((e) => e['elo'] ?? 0).toList();

        setState(() {});
      } else {
        setState(() {
          error = 'Erro ao buscar dados';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erro ao buscar dados';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFF4655),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Valorant Histórico MMR'),
        centerTitle: true,
      ),
      body: Center(
        child: error != null
            ? Text(error!, style: TextStyle(color: Colors.white))
            : imageUrl == null
                ? CircularProgressIndicator(color: Colors.white)
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('lib/assets/valorant_logo.png',
                              height: 80),
                          SizedBox(height: 30),
                          Image.network(imageUrl!, height: 320),
                          SizedBox(height: 20),
                          Text(
                            '${widget.name}#${widget.tag}',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            'Level: $accountLevel',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white70),
                          ),
                          SizedBox(height: 40),
                          Text(
                            'Histórico de Elo',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          SizedBox(
                              height: 200,
                              child: EloLineChart(data: eloHistory)),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class EloLineChart extends StatelessWidget {
  final List<int> data;

  const EloLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: EloChartPainter(data),
      size: Size(double.infinity, 200),
    );
  }
}

class EloChartPainter extends CustomPainter {
  final List<int> data;
  EloChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final maxElo = data.reduce((a, b) => a > b ? a : b).toDouble();
    final minElo = data.reduce((a, b) => a < b ? a : b).toDouble();
    final range = (maxElo - minElo == 0) ? 1 : (maxElo - minElo);
    final stepX = size.width / (data.length - 1);

    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y = size.height - ((data[i] - minElo) / range) * size.height;
      points.add(Offset(x, y));
    }

    // Grid horizontal
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = i * size.height / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Linha principal
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paintLine);

    // Pontos e labels
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      canvas.drawCircle(point, 3, dotPaint);

      // Elo label
      final label = data[i].toString();
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(color: Colors.white, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(point.dx - 10, point.dy - 18));

      // X index
      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: TextStyle(color: Colors.white70, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(point.dx - 6, size.height + 2));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
