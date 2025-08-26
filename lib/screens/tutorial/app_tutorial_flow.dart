import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTutorialFlow extends StatefulWidget {
  final VoidCallback? onFinish;
  const AppTutorialFlow({Key? key, this.onFinish}) : super(key: key);

  static const seenKey = 'tutorial_v1_seen';

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(seenKey) ?? false;
  }

  static Future<void> setSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenKey, true);
  }

  @override
  State<AppTutorialFlow> createState() => _AppTutorialFlowState();
}

class _AppTutorialFlowState extends State<AppTutorialFlow> {
  final PageController _page = PageController();
  int _index = 0;

  late final List<_SlideData> _slides = [
    _SlideData(
      icon: Icons.map_rounded,
      title: 'Empieza en el mapa',
      subtitle: 'Busca un destino, elige la mejor ruta y toca Iniciar.',
      chips: const ['SIGUIENDO', '2D', '3D'],
      bullets: const [
        _Bullet(icon: Icons.search, text: 'Escribe una dirección o lugar en la búsqueda.'),
        _Bullet(icon: Icons.place_outlined, text: 'También puedes tocar el mapa para fijar destino.'),
        _Bullet(icon: Icons.play_circle_fill_rounded, text: 'Pulsa Iniciar ruta para comenzar.'),
      ],
      tip: 'Usa SIGUIENDO para mantener la cámara centrada en tu posición.',
    ),
    _SlideData(
      icon: Icons.emoji_events_outlined,
      title: 'Gana puntos en la ruta',
      subtitle: 'Conduce seguro y suma puntos automáticamente.',
      bullets: const [
        _Bullet(icon: Icons.timeline_rounded, text: 'Ganas por avanzar y completar tramos.'),
        _Bullet(icon: Icons.shield_moon_outlined, text: 'Evita distracciones para no perder puntos.'),
        _Bullet(icon: Icons.check_circle_outline, text: 'Mejor puntuación si llegas sin desvíos.'),
      ],
      tip: 'Abre el Historial para ver puntos ganados y por qué.',
    ),
    _SlideData(
      icon: Icons.groups_2_outlined,
      title: 'Comunidades y ranking',
      subtitle: 'Únete o crea una comunidad y compite en el ranking.',
      bullets: const [
        _Bullet(icon: Icons.qr_code_2, text: 'Únete con un código o crea una nueva.'),
        _Bullet(icon: Icons.leaderboard_outlined, text: 'Tu puntaje sube tu posición en tiempo real.'),
        _Bullet(icon: Icons.notifications_active_outlined, text: 'Recibe avisos si te superan o estás cerca.'),
      ],
      tip: 'Crea tu comunidad en Comunidades > Crear.',
    ),
    _SlideData(
      icon: Icons.person_outline,
      title: 'Tu perfil',
      subtitle: 'Consulta tu información y tu progreso.',
      bullets: const [
        _Bullet(icon: Icons.badge_outlined, text: 'Nombre y correo de tu cuenta.'),
        _Bullet(icon: Icons.local_fire_department_outlined, text: 'Tu racha de días activos.'),
        _Bullet(icon: Icons.leaderboard_outlined, text: 'Tu clasificación actual.'),
      ],
      tip: 'Revisa tu avance desde Perfil cuando quieras.',
    ),
  ];

  Color get primary => const Color(0xFF1565C0);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _finish() async {
    await AppTutorialFlow.setSeen();
    if (!mounted) return;
    widget.onFinish?.call();
    Navigator.of(context).maybePop();
  }

  void _next() {
    final last = _slides.length - 1;
    if (_index >= last) {
      _finish();
    } else {
      _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primary,
        actions: [
          TextButton(onPressed: _finish, child: const Text('Omitir')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _RichSlide(data: _slides[i], primary: primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => _Dot(active: i == _index, color: primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${_index + 1}/${_slides.length}', style: TextStyle(color: Colors.black.withOpacity(0.45))),
                  const Spacer(),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(_index < _slides.length - 1 ? 'Siguiente' : 'Empezar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RichSlide extends StatelessWidget {
  final _SlideData data;
  final Color primary;
  const _RichSlide({required this.data, required this.primary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          _HeroIcon(icon: data.icon, primary: primary),
          const SizedBox(height: 18),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: primary),
          ),
          const SizedBox(height: 10),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.35, color: Colors.black.withOpacity(0.78)),
          ),
          if (data.chips != null && data.chips!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: data.chips!
                  .map((c) => Chip(
                        label: Text(c, style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
                        backgroundColor: primary.withOpacity(0.08),
                        side: BorderSide(color: primary.withOpacity(0.2)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          _CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...data.bullets.map((b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _BulletRow(icon: b.icon, text: b.text, primary: primary),
                    )),
              ],
            ),
          ),
          if (data.tip != null) ...[
            const SizedBox(height: 12),
            _TipCard(text: data.tip!, primary: primary),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;
  final Color primary;
  const _HeroIcon({required this.icon, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.12), primary.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Icon(icon, size: 58, color: primary),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _BulletRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color primary;
  const _BulletRow({required this.icon, required this.text, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: primary.withOpacity(0.18)),
          ),
          child: Icon(icon, size: 16, color: primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, height: 1.35, color: Colors.black.withOpacity(0.85)),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  final Color primary;
  const _TipCard({required this.text, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.35, color: Colors.black.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final Color color;
  const _Dot({required this.active, required this.color});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 6),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? color : Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_Bullet> bullets;
  final List<String>? chips;
  final String? tip;
  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bullets,
    this.chips,
    this.tip,
  });
}

class _Bullet {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});
}
