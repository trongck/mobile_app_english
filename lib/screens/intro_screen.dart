import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
 import 'onboarding_screen.dart';
import '../providers/gt_provider.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isLastPage = false;
  int _currentIndex = 0;
  int _imageAnimKey = 0;

  static const List<Color> _pageColors = [
    Color.fromARGB(255, 129, 230, 255),
    Color.fromARGB(255, 94, 182, 255),
    Color.fromARGB(255, 57, 176, 255),
    Color.fromARGB(255, 0, 167, 179),
  ];

  static const List<IconData> _pageIcons = [
    Icons.auto_stories_rounded,
    Icons.public_rounded,
    Icons.account_tree_rounded,
    Icons.rocket_launch_rounded,
  ];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GTProvider>(context, listen: false);
      if (provider.danhSachIntro.isEmpty) {
        provider.khoiTaoDuLieu().then((_) {
          if (mounted) _animController.forward();
        });
      } else {
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, int total) {
    setState(() {
      _currentIndex = index;
      _isLastPage = index == total - 1;
      _imageAnimKey++;
    });
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final gtProvider = context.watch<GTProvider>();
    final size = MediaQuery.of(context).size;

    // ── Loading ──────────────────────────────────────────────────────────────
    if (gtProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A73E8),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────────
    if (gtProvider.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  gtProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5C5C7A),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => gtProvider.khoiTaoDuLieu(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final intros = gtProvider.danhSachIntro;
    if (intros.isEmpty) return const SizedBox.shrink();

    final accentColor = _pageColors[_currentIndex % _pageColors.length];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Nền gradient ─────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.08),
                  Colors.white,
                ],
              ),
            ),
          ),

          // ── Vòng trang trí trên ──────────────────────────────────────────
          Positioned(
            top: -size.width * 0.25,
            right: -size.width * 0.25,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: size.width * 0.75,
              height: size.width * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.07),
              ),
            ),
          ),

          // ── Vòng trang trí dưới ──────────────────────────────────────────
          Positioned(
            bottom: 80,
            left: -size.width * 0.15,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: size.width * 0.45,
              height: size.width * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.05),
              ),
            ),
          ),

          // ── Nội dung chính ────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Branding bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Image.asset(
                          'assets/icon/logo.png', // đường dẫn ảnh của bạn
                          width: 30,
                          height: 30,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'DevTalk English',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 150),
                // PageView
                Expanded(
                  child: PageView.builder(
                  
                    controller: _pageController,
                    itemCount: intros.length,
                    onPageChanged: (i) => _onPageChanged(i, intros.length),
                    itemBuilder: (context, index) {
                      final intro = intros[index];
                      final color = _pageColors[index % _pageColors.length];
                      final icon = _pageIcons[index % _pageIcons.length];

                      return FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // ── Ảnh 3D bo viền ──────────────────────
                                TweenAnimationBuilder<double>(
                                  key: ValueKey(_imageAnimKey),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.elasticOut,
                                  builder: (context, v, child) {
                                    return Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY((1 - v) * 0.35)
                                        ..scale(0.75 + 0.25 * v),
                                      child: child,
                                    );
                                  },
                                  
                                  child: Container(
                                    width: 520,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      color: Colors.white,
                                      border: Border.all(
                                        color: color.withOpacity(0.18),
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.22),
                                          blurRadius: 28,
                                          offset: const Offset(0, 12),
                                          spreadRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: color.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        intro.anh ?? 'assets/icons/intro.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Icon(
                                            icon,
                                            size: 10,
                                            color: color.withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // ── Badge số trang (sát ảnh) ─────────────
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${index + 1} / ${intros.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Tiêu đề
                                Text(
                                  intro.tieuDe,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A2E),
                                    height: 1.35,
                                    letterSpacing: -0.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 20),

                                // Mô tả
                                Text(
                                  intro.moTa ?? '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.65,
                                    color: Color(0xFF5C5C7A),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Thanh điều hướng phía dưới ────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _isLastPage
                ? _buildBatDauButton(accentColor)
                : _buildNavBar(intros.length, accentColor),
          ),
        ],
      ),
    );
  }

  // ─── Widget: Nút "Bắt đầu trải nghiệm" ─────────────────────────────────────

  Widget _buildBatDauButton(Color accentColor) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
           onPressed: () => Navigator.pushReplacement(
            context,
            PageRouteBuilder(
            pageBuilder: (_, a, __) => const OnboardingScreen(),
            transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),  ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Bắt đầu trải nghiệm',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widget: Thanh "Bỏ qua / Dots / Tiếp" ──────────────────────────────────

  Widget _buildNavBar(int total, Color accentColor) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bỏ qua
          TextButton(
            onPressed: () => _pageController.animateToPage(
              total - 1,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF9E9EB8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            child: const Text(
              'Bỏ qua',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),

          // Dots indicator
          SmoothPageIndicator(
            controller: _pageController,
            count: total,
            effect: ExpandingDotsEffect(
              spacing: 6,
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: accentColor,
              dotColor: Color(0xFFD1D1E0),
              expansionFactor: 3,
            ),
            onDotClicked: (index) => _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          ),

          // Tiếp theo
          TextButton(
            onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
            ),
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Tiếp',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}