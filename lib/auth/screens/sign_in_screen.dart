import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _selectedRoleTab = 0; // 0 = HOD, 1 = Class Advisor

  final _usernameCtrl = TextEditingController(text: 'hod.manivannan');
  final _passwordCtrl = TextEditingController(text: 'Hod@Mani2026');

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _glowAnimController;

  @override
  void initState() {
    super.initState();
    _glowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (WidgetsBinding.instance is WidgetsFlutterBinding) {
      _glowAnimController.repeat(reverse: true);
    } else {
      _glowAnimController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _glowAnimController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onRoleTabChanged(int index) {
    setState(() {
      _selectedRoleTab = index;
      if (index == 0) {
        _usernameCtrl.text = 'hod.manivannan';
        _passwordCtrl.text = 'Hod@Mani2026';
      } else {
        _usernameCtrl.text = 'advisor.anandhan';
        _passwordCtrl.text = 'Adv@Anandh2A';
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = AuthService();
    if (authService.isLockedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Security Lock active. Please wait ${authService.remainingLockoutSeconds}s.'),
          backgroundColor: AppColors.absentRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await authService.signInDirect(
      _usernameCtrl.text,
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pushReplacementNamed(context, authService.dashboardRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            _buildSkyCloudHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Role Selector Tabs (Only HOD & Class Advisor)
                    _buildRoleTabs(),

                    const SizedBox(height: 20),

                    // Input Label
                    Text(
                      _getInputLabel(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),

                    // Username / Email Input
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: InputDecoration(
                        hintText: _getInputHint(),
                        prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF0284C7)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your username/credential' : null,
                    ),

                    const SizedBox(height: 16),
                    const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),

                    // Password Input
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter official password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0284C7)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                      ),
                      validator: (v) => (v == null || v.length < 4) ? 'Password too short' : null,
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                        child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Login Button (Sky Blue Gradient)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Sign In as ${_selectedRoleTab == 0 ? "HOD" : "Class Advisor"}',
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Role Specific Quick Selector Chips
                    _buildQuickRoleAccounts(),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _roleTabItem(0, '🏛️ HOD Portal'),
          _roleTabItem(1, '👨‍🏫 Class Advisor'),
        ],
      ),
    );
  }

  Widget _roleTabItem(int index, String title) {
    final isSelected = _selectedRoleTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onRoleTabChanged(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  String _getInputLabel() {
    if (_selectedRoleTab == 0) return 'HOD Username or Email';
    return 'Class Advisor Username or Official Email';
  }

  String _getInputHint() {
    if (_selectedRoleTab == 0) return 'e.g., hod.manivannan or manivannan.hod@vsb.ac.in';
    return 'e.g., advisor.anandhan or advisor.2a@vsb.ac.in';
  }

  Widget _buildQuickRoleAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedRoleTab == 0
                  ? 'Quick HOD Logins:'
                  : '10 Section Class Advisors (2nd, 3rd, 4th Year):',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            if (_selectedRoleTab == 1)
              TextButton.icon(
                onPressed: _showAllAdvisorsDialog,
                icon: const Icon(Icons.co_present_rounded, size: 14, color: Color(0xFF0284C7)),
                label: const Text('View All 10', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedRoleTab == 0)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _accountChip('DR. MANIVANNAN (Ph.D.) - Department HOD', 'hod.manivannan', 'Hod@Mani2026'),
            ],
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // 2nd Year
              _accountChip('II-A: Dr. D. Anandhan', 'advisor.anandhan', 'Adv@Anandh2A'),
              _accountChip('II-B: Dr. M. Rajendiran', 'advisor.rajendiran', 'Adv@Rajen2B'),
              _accountChip('II-C: Mr. A. Bharathidasan', 'advisor.bharathidasan', 'Adv@Bharathi2C'),
              _accountChip('II-D: Mr. R. Palraj', 'advisor.palraj', 'Adv@Palraj2D'),
              // 3rd Year
              _accountChip('III-A: Ms. C. Vishnupriya', 'advisor.vishnupriya', 'Adv@Vishnu3A'),
              _accountChip('III-B: Dr. R. Murugesan', 'advisor.murugesan', 'Adv@Murugesan3B'),
              _accountChip('III-C: Mrs. B. Bharathi', 'advisor.bharathi', 'Adv@Bharathi3C'),
              _accountChip('III-D: Mr. Velusamy', 'advisor.velusamy', 'Adv@Velu3D'),
              // 4th Year
              _accountChip('IV-A: Mr. Muthuselvan', 'advisor.muthuselvan', 'Adv@Muthu4A'),
              _accountChip('IV-B: Mrs. Nandhinidevi', 'advisor.nandhinidevi', 'Adv@Nandhini4B'),
            ],
          ),
      ],
    );
  }

  Widget _accountChip(String label, String username, [String? password]) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0369A1))),
      backgroundColor: const Color(0xFFE0F2FE),
      side: const BorderSide(color: Color(0xFFBAE6FD)),
      onPressed: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _usernameCtrl.text = username;
          _passwordCtrl.text = password ?? 'password123';
        });
      },
    );
  }

  Widget _buildSkyCloudHeader() {
    return Container(
      width: double.infinity,
      height: 290,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFF7DD3FC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x440284C7),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background soft cloud silhouettes
          Positioned(
            top: 25,
            left: 20,
            child: Icon(
              Icons.cloud,
              size: 135,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 60,
            right: 15,
            child: Icon(
              Icons.cloud,
              size: 115,
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PinkSlipReport',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'V.S.B. Engineering College • Dept of AI & DS',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Official Academic Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAllAdvisorsDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 640),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.co_present_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('10 Section Class Advisors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('II, III & IV Year AI&DS • Tap to load credentials', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AuthService.sectionAdvisors.length,
                  itemBuilder: (context, i) {
                    final adv = AuthService.sectionAdvisors[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE0F2FE),
                          child: Text(
                            '${adv.year}${adv.section}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ),
                        title: Text(adv.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(adv.classSection ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text('User: ${adv.username}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                const SizedBox(width: 8),
                                Text('Pass: ${adv.password}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF16A34A))),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _usernameCtrl.text = adv.username;
                              _passwordCtrl.text = adv.password;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Use Login'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
