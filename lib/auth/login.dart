import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ireader_mobile_edition/core/auth_service.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/widgets/fun_ui.dart';

const _depedSeal =
    'assets/images/Department-of-Education-DepEd-Seal-300x300.png';
const _ireaderLogo = 'assets/images/untitled-1.png';

/// First screen. If Firebase still has a signed-in user, re-checks their role
/// and account status before letting them in; otherwise shows [LoginScreen].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Navigate after the first frame; pushing during initState locks the
    // Navigator.
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(_depedSeal), context);
    precacheImage(const AssetImage(_ireaderLogo), context);
  }

  Future<void> _restore() async {
    // Wait for Firebase to restore any saved session (async on web).
    final user = await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => FirebaseAuth.instance.currentUser,
        );
    Widget next = const LoginScreen();
    if (user != null) {
      try {
        next = await AuthService.homeFor(user);
      } catch (_) {
        // homeFor already signed out; fall through to the login screen.
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: StorybookBackground(
        child: Center(child: BouncyLoader(label: 'Opening your library…')),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) return; // cancelled

      final home = await AuthService.homeFor(user);
      if (!mounted) return;
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => home));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
      );
    } on AccessDenied catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      // Do not surface raw exception text (it can include internal paths).
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sign-in failed. Check your connection and try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      body: StorybookBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LogoBubble(
                              asset: _depedSeal,
                              size: isMobile ? 76 : 92,
                            ),
                            const SizedBox(width: 14),
                            _LogoBubble(
                              asset: _ireaderLogo,
                              size: isMobile ? 76 : 92,
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 22),
                    const Text(
                      'KAGAWARAN NG EDUKASYON',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const Text(
                      'REPUBLIKA NG PILIPINAS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            children: [
                              const Text(
                                'iReader',
                                style: TextStyle(
                                  fontSize: 44,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Reading Comprehensive Assessment System',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FunTag(
                                    icon: Icons.menu_book_rounded,
                                    label: 'Read',
                                    color: AppTheme.primaryColor,
                                  ),
                                  FunTag(
                                    icon: Icons.lightbulb_rounded,
                                    label: 'Understand',
                                    color: AppTheme.sunColor,
                                  ),
                                  FunTag(
                                    icon: Icons.emoji_events_rounded,
                                    label: 'Grow',
                                    color: AppTheme.mintColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : login,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _GoogleBadge(),
                                            SizedBox(width: 12),
                                            Text(
                                              'Sign in with Google',
                                              style: TextStyle(fontSize: 16.5),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Use the Google account your school registered.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 400.ms)
                        .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoBubble extends StatelessWidget {
  final String asset;
  final double size;
  const _LogoBubble({required this.asset, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppTheme.softShadow,
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: 16,
          height: 1,
        ),
      ),
    );
  }
}
