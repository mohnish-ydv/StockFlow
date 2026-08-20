import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/sf_ui.dart';
import 'legal_screens.dart';

enum AuthMode { register, signIn }

enum _AuthStage { entry, otp, profile }

class AuthScreen extends StatefulWidget {
  final StockFlowApi api;
  final VoidCallback onDone;
  final VoidCallback? onBack;
  final AuthMode initialMode;

  const AuthScreen({
    super.key,
    required this.api,
    required this.onDone,
    this.onBack,
    this.initialMode = AuthMode.signIn,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  final name = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final otpFocus = FocusNode();

  late AuthMode mode;
  _AuthStage stage = _AuthStage.entry;
  bool busy = false;
  bool agreed = false;
  int resendSeconds = 30;
  Timer? _timer;

  bool get isRegister => mode == AuthMode.register;
  String get digits => phone.text.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode;
  }

  @override
  void dispose() {
    _timer?.cancel();
    phone.dispose();
    otp.dispose();
    name.dispose();
    city.dispose();
    state.dispose();
    otpFocus.dispose();
    super.dispose();
  }

  void _msg(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _switchMode(AuthMode next) {
    if (busy || next == mode) return;
    _timer?.cancel();
    setState(() {
      mode = next;
      stage = _AuthStage.entry;
      otp.clear();
      agreed = false;
      resendSeconds = 30;
    });
  }

  void _startOtpTimer() {
    _timer?.cancel();
    resendSeconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (resendSeconds <= 1) {
        timer.cancel();
        setState(() => resendSeconds = 0);
      } else {
        setState(() => resendSeconds -= 1);
      }
    });
  }

  void _goToOtp() {
    if (digits.length < 10) {
      _msg('Enter a valid mobile number');
      return;
    }
    setState(() => stage = _AuthStage.otp);
    _startOtpTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => otpFocus.requestFocus());
  }

  Future<void> _submitOtp() async {
    if (otp.text.trim().length != 6) {
      _msg('Enter the 6-digit verification code');
      return;
    }

    if (isRegister) {
      _timer?.cancel();
      setState(() => stage = _AuthStage.profile);
      return;
    }

    await _finishAuthentication();
  }

  Future<void> _finishAuthentication() async {
    if (busy) return;
    if (isRegister) {
      if (name.text.trim().length < 2) {
        _msg('Enter your full name');
        return;
      }
      if (city.text.trim().isEmpty || state.text.trim().isEmpty) {
        _msg('Add your city and state');
        return;
      }
      if (!agreed) {
        _msg('Please accept the Terms & Conditions and Privacy Policy');
        return;
      }
    }

    setState(() => busy = true);
    try {
      await widget.api.login(
        phone: phone.text,
        otp: otp.text,
        fullName: isRegister ? name.text.trim() : '',
        city: isRegister ? city.text.trim() : 'Delhi',
        state: isRegister ? state.text.trim() : 'Delhi',
        language: 'en',
        authMode: isRegister ? 'register' : 'signIn',
      );
      if (!mounted) return;
      widget.onDone();
    } on ApiException catch (e) {
      if (!isRegister && e.code == 'SF-API-404') {
        _msg('No account found for this number. Tap “Create account” to sign up.');
      } else if (isRegister && e.code == 'SF-API-409') {
        _msg('This number already has an account. Switch to Sign in.');
      } else {
        _msg(e.toString());
      }
    } catch (e) {
      _msg('$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _resend() {
    if (resendSeconds > 0 || busy) return;
    otp.clear();
    _startOtpTimer();
    otpFocus.requestFocus();
  }

  void _back() {
    if (busy) return;
    if (stage == _AuthStage.profile) {
      setState(() => stage = _AuthStage.otp);
      return;
    }
    if (stage == _AuthStage.otp) {
      _timer?.cancel();
      setState(() => stage = _AuthStage.entry);
      return;
    }
    (widget.onBack ?? () => Navigator.maybePop(context))();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: StockFlowTheme.surface,
      body: Stack(
        children: [
          const Positioned(left: -126, top: -188, child: _AuthBlob(size: 342, color: StockFlowTheme.accent)),
          const Positioned(right: -86, top: 28, child: _AuthBlob(size: 174, color: Color(0xFFDCE7FF))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 14, 0),
                  child: Row(
                    children: [
                      SfRoundIconButton(
                        icon: stage == _AuthStage.entry ? Icons.close_rounded : Icons.arrow_back_rounded,
                        onTap: _back,
                        tooltip: stage == _AuthStage.entry ? 'Close' : 'Back',
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(width < 380 ? 20 : 28, 84, width < 380 ? 20 : 28, 34),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: switch (stage) {
                            _AuthStage.entry => _entry(),
                            _AuthStage.otp => _otp(),
                            _AuthStage.profile => _profile(),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entry() {
    final title = isRegister ? 'Create your account' : 'Welcome back';
    final subtitle = isRegister
        ? 'Use your mobile number to start buying or selling on StockFlow.'
        : 'Sign in with the mobile number linked to your StockFlow account.';

    return Column(
      key: ValueKey('entry-${mode.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 10),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 30),
        const Text('Mobile number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          onSubmitted: (_) => _goToOtp(),
          decoration: const InputDecoration(
            hintText: '98765 43210',
            prefixText: '+91  ',
            prefixStyle: TextStyle(fontWeight: FontWeight.w700, color: StockFlowTheme.text),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: StockFlowTheme.muted),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'Your phone number stays private and is never shown on listings.',
                style: TextStyle(fontSize: 11.5, height: 1.35, color: StockFlowTheme.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy ? null : _goToOtp,
            child: const Text('Continue'),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            runSpacing: 0,
            children: [
              Text(
                isRegister ? 'Already have an account?' : 'New to StockFlow?',
                style: const TextStyle(fontSize: 13, color: StockFlowTheme.textSecondary),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => _switchMode(isRegister ? AuthMode.signIn : AuthMode.register),
                child: Text(isRegister ? 'Sign in' : 'Create account'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _otp() {
    final masked = digits.length >= 4 ? '••••••${digits.substring(digits.length - 4)}' : phone.text.trim();
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _OtpIllustration(),
        const SizedBox(height: 28),
        Text('Verify your number', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 10),
        Text(
          'Enter the 6-digit code sent to +91 $masked.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        _OtpBoxes(controller: otp, focusNode: otpFocus, onSubmitted: _submitOtp),
        const SizedBox(height: 20),
        Row(
          children: [
            TextButton(
              onPressed: resendSeconds == 0 ? _resend : null,
              child: Text(resendSeconds == 0 ? 'Resend code' : 'Resend in 0:${resendSeconds.toString().padLeft(2, '0')}'),
            ),
            const Spacer(),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      _timer?.cancel();
                      setState(() => stage = _AuthStage.entry);
                    },
              child: const Text('Change number'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy ? null : _submitOtp,
            child: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isRegister ? 'Verify & continue' : 'Verify & sign in'),
          ),
        ),
      ],
    );
  }

  Widget _profile() {
    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tell us about you', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 10),
        const Text(
          'These details help StockFlow show relevant stock and fulfilment options. You can edit them later.',
          style: TextStyle(fontSize: 14, height: 1.5, color: StockFlowTheme.textSecondary),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: city,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: state,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'State'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ConsentRow(
          value: agreed,
          onChanged: (value) => setState(() => agreed = value),
          onTerms: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen())),
          onPrivacy: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy || !agreed ? null : _finishAuthentication,
            child: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create account'),
          ),
        ),
      ],
    );
  }
}

class _AuthBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _AuthBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      );
}

class _OtpIllustration extends StatelessWidget {
  const _OtpIllustration();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 126,
          height: 126,
          decoration: const BoxDecoration(color: StockFlowTheme.brandSoft, shape: BoxShape.circle),
          child: Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: StockFlowTheme.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8))],
              ),
              child: const Icon(Icons.sms_outlined, color: StockFlowTheme.accent, size: 34),
            ),
          ),
        ),
      );
}

class _OtpBoxes extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<void> Function() onSubmitted;

  const _OtpBoxes({required this.controller, required this.focusNode, required this.onSubmitted});

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    return GestureDetector(
      onTap: widget.focusNode.requestFocus,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final char = index < value.length ? value[index] : '';
              final active = index == value.length && value.length < 6;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 47,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StockFlowTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? StockFlowTheme.accent : StockFlowTheme.lineStrong,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  char,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: .01,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                autofocus: true,
                autofillHints: const [AutofillHints.oneTimeCode],
                onSubmitted: (_) => widget.onSubmitted(),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  const _ConsentRow({required this.value, required this.onChanged, required this.onTerms, required this.onPrivacy});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: value, onChanged: (checked) => onChanged(checked ?? false)),
          const SizedBox(width: 2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('I agree to the ', style: TextStyle(fontSize: 12.5, height: 1.45, color: StockFlowTheme.textSecondary)),
                  InkWell(
                    onTap: onTerms,
                    child: const Text('Terms & Conditions', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: StockFlowTheme.accentStrong)),
                  ),
                  const Text(' and ', style: TextStyle(fontSize: 12.5, color: StockFlowTheme.textSecondary)),
                  InkWell(
                    onTap: onPrivacy,
                    child: const Text('Privacy Policy', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: StockFlowTheme.accentStrong)),
                  ),
                  const Text('.', style: TextStyle(fontSize: 12.5, color: StockFlowTheme.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      );
}
