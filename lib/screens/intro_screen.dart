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

  // ─── Responsive helper ────────────────────────────────────────────────────
  // Trả về kích thước tỉ lệ theo chiều cao màn hình (tránh overflow).
  double _rh(BuildContext context, double factor) =>
      MediaQuery.of(context).size.height * factor;

  double _rw(BuildContext context, double factor) =>
      MediaQuery.of(context).size.width * factor;

  @override
  Widget build(BuildContext context) {
    final gtProvider = context.watch<GTProvider>();
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

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

    // ── Responsive layout breakpoints ────────────────────────────────────────
    // Phân loại thiết bị theo chiều cao thực (sau khi trừ system bars)
    final availH = size.height - padding.top - padding.bottom;

    // Nhỏ: < 600 (iPhone SE, Galaxy A series nhỏ)
    // Trung: 600 – 750 (iPhone 14, Pixel 6)
    // Lớn: > 750 (iPhone 14 Pro Max, tablet compact)
    final isSmall = availH < 600;
    final isLarge = availH > 750;

    // ── Tỉ lệ ảnh: chiếm ~38% chiều cao khả dụng, tối đa 280, tối thiểu 160
    final imageHeight = (availH * 0.38).clamp(160.0, 280.0);

    // ── Font sizes ────────────────────────────────────────────────────────────
    final titleSize = isSmall ? 18.0 : isLarge ? 24.0 : 21.0;
    final descSize = isSmall ? 13.0 : 15.0;
    final logoSize = isSmall ? 26.0 : 30.0;
    final brandFontSize = isSmall ? 15.0 : 17.0;

    // ── Spacing ───────────────────────────────────────────────────────────────
    final topBarPadding = isSmall ? 12.0 : 20.0;
    final spacerAfterImage = isSmall ? 8.0 : 14.0;
    final spacerAfterBadge = isSmall ? 14.0 : 20.0;
    final spacerAfterTitle = isSmall ? 12.0 : 20.0;
    final hzPadding = isSmall ? 24.0 : 32.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Nền gradient ───────────────────────────────────────────────────
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

          // ── Vòng trang trí trên ────────────────────────────────────────────
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

          // ── Vòng trang trí dưới ────────────────────────────────────────────
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

          // ── Nội dung chính ─────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Branding bar ──────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(24, topBarPadding, 24, 0),
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
                          'assets/icon/logo.png',
                          width: logoSize,
                          height: logoSize,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'DevTalk English',
                        style: TextStyle(
                          fontSize: brandFontSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── PageView ──────────────────────────────────────────────────
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
                            padding: EdgeInsets.symmetric(
                              horizontal: hzPadding,
                              vertical: isSmall ? 8 : 16,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ── Ảnh 3D bo viền ──────────────────────────
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
                                    // Chiều rộng tối đa = screen width - padding ngang
                                    width: double.infinity,
                                    height: imageHeight,
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
                                      borderRadius: BorderRadius.circular(25),
                                      child: Image.asset(
                                        intro.anh ?? 'assets/icons/intro.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Icon(
                                            icon,
                                            size: imageHeight * 0.25,
                                            color: color.withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: spacerAfterImage),

                                // ── Badge số trang ───────────────────────────
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
                                      fontSize: isSmall ? 11 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),

                                SizedBox(height: spacerAfterBadge),

                                // ── Tiêu đề ──────────────────────────────────
                                Text(
                                  intro.tieuDe,
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1A2E),
                                    height: 1.35,
                                    letterSpacing: -0.4,
                                  ),
                                  textAlign: TextAlign.center,
                                  // Tránh tràn khi tiêu đề quá dài
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                SizedBox(height: spacerAfterTitle),

                                // ── Mô tả ─────────────────────────────────────
                                // Dùng Flexible để mô tả co lại nếu không đủ chỗ
                                Flexible(
                                  child: Text(
                                    intro.moTa ?? '',
                                    style: TextStyle(
                                      fontSize: descSize,
                                      height: isSmall ? 1.5 : 1.65,
                                      color: const Color(0xFF5C5C7A),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                    // Giới hạn số dòng trên màn hình nhỏ
                                    maxLines: isSmall ? 4 : null,
                                    overflow: isSmall
                                        ? TextOverflow.ellipsis
                                        : TextOverflow.visible,
                                  ),
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

          // ── Thanh điều hướng phía dưới ─────────────────────────────────────
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

  // ─── Widget: Nút "Bắt đầu trải nghiệm" ──────────────────────────────────────
  Widget _buildBatDauButton(Color accentColor) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 24),
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
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          ),
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

  // ─── Widget: Thanh "Bỏ qua / Dots / Tiếp" ────────────────────────────────────
  Widget _buildNavBar(int total, Color accentColor) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 16),
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
              dotColor: const Color(0xFFD1D1E0),
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