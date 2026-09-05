import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/data/student_directory_data.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _selectedRoleTab = 0; // 0 = HOD, 1 = Advisor, 2 = Student

  final _usernameCtrl = TextEditingController(text: 'hod.manivannan');
  final _passwordCtrl = TextEditingController(text: 'Hod@Mani2026');

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _cloudAnimController;

  @override
  void initState() {
    super.initState();
    _cloudAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudAnimController.dispose();
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
      } else if (index == 1) {
        _usernameCtrl.text = 'advisor.muthuselvan';
        _passwordCtrl.text = 'Adv@Muthu4A';
      } else {
        _usernameCtrl.text = '25243001'; // ABINAYA G
        _passwordCtrl.text = 'Stu@25243001';
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

    final success = await authService.preAuthenticate(
      _usernameCtrl.text,
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pushNamed(context, '/security-verification');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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

                        // Role Selector Tabs (HOD, Advisor, Student)
                        _buildRoleTabs(),

                        const SizedBox(height: 20),

                        // Input Label
                        Text(
                          _getInputLabel(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),

                        // Username / Email / Roll Number Input
                        TextFormField(
                          controller: _usernameCtrl,
                          decoration: InputDecoration(
                            hintText: _getInputHint(),
                            prefixIcon: Icon(_getInputIcon(), color: AppColors.primaryPurple),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
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
                            hintText: 'Enter account password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryPurple),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                          ),
                          validator: (v) => (v == null || v.length < 4) ? 'Password too short' : null,
                        ),

                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                            child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF38BDF8)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                  blurRadius: 16,
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
                                      'Sign In as ${_getRoleTitle()}',
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Role Specific Quick Selector Chips
                        _buildQuickRoleAccounts(),

                        const SizedBox(height: 32),
                      ],
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
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  String _getInputLabel() {
    if (_selectedRoleTab == 0) return 'HOD Email or Username';
    if (_selectedRoleTab == 1) return 'Class Advisor Email or Staff ID';
    return 'Student Roll Number or College Email';
  }

  String _getInputHint() {
    if (_selectedRoleTab == 0) return 'e.g., manivannan.hod@vsb.ac.in';
    if (_selectedRoleTab == 1) return 'e.g., advisor.4a@vsb.ac.in (Mr. Muthuselvan)';
    return 'e.g., 25243100, 24243007, 23243034';
  }

  IconData _getInputIcon() {
    if (_selectedRoleTab == 0) return Icons.admin_panel_settings_rounded;
    if (_selectedRoleTab == 1) return Icons.school_rounded;
    return Icons.badge_rounded;
  }

  String _getRoleTitle() {
    if (_selectedRoleTab == 0) return 'HOD';
    if (_selectedRoleTab == 1) return 'Advisor';
    return 'Student';
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
                  : _selectedRoleTab == 1
                      ? '10 Official Section Advisors:'
                      : 'Students & CR Logins:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            if (_selectedRoleTab == 1)
              TextButton.icon(
                onPressed: _showAllAdvisorsDialog,
                icon: const Icon(Icons.co_present_rounded, size: 14, color: AppColors.primaryPurple),
                label: const Text('View All 10 Advisors', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
              )
            else if (_selectedRoleTab == 2)
              TextButton.icon(
                onPressed: _showAllClassRepsDialog,
                icon: const Icon(Icons.people_alt_rounded, size: 14, color: AppColors.primaryPurple),
                label: const Text('View All 20 CRs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
              )
            else
              TextButton.icon(
                onPressed: _showCredentialsDirectoryDialog,
                icon: const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.primaryPurple),
                label: const Text('All Credentials & PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_selectedRoleTab == 0)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _accountChip('DR. MANIVANNAN (Overall HOD)', 'hod.manivannan', 'Hod@Mani2026'),
              _accountChip('Mrs. Kavitha (I & II Yr HOD)', 'hod.kavitha', 'Hod@Kavi2026'),
            ],
          )
        else if (_selectedRoleTab == 1)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _accountChip('IV-A: Mr. Muthuselvan', 'advisor.muthuselvan', 'Adv@Muthu4A'),
              _accountChip('IV-B: Mrs. Nandhinidevi', 'advisor.nandhinidevi', 'Adv@Nandhini4B'),
              _accountChip('III-A: Ms. C. Vishnupriya', 'advisor.vishnupriya', 'Adv@Vishnu3A'),
              _accountChip('III-B: Dr. R. Murugesan', 'advisor.murugesan', 'Adv@Murugesan3B'),
              _accountChip('III-C: Mrs. B. Bharathi', 'advisor.bharathi', 'Adv@Bharathi3C'),
              _accountChip('III-D: Mr. Velusamy', 'advisor.velusamy', 'Adv@Velu3D'),
              _accountChip('II-A: Dr. D. Anandhan', 'advisor.anandhan', 'Adv@Anandh2A'),
              _accountChip('II-B: Dr. M. Rajendiran', 'advisor.rajendiran', 'Adv@Rajen2B'),
              _accountChip('II-C: Mr. A. Bharathidasan', 'advisor.bharathidasan', 'Adv@Bharathi2C'),
              _accountChip('II-D: Mr. R. Palraj', 'advisor.palraj', 'Adv@Palraj2D'),
            ],
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _accountChip('ABINAYA G (II-A: 25243001)', '25243001', 'Stu@25243001'),
              _accountChip('ADITHYAN S (II-A: 25243002)', '25243002', 'Stu@25243002'),
              _accountChip('LITHESH HARI R (II-B: 25243100)', '25243100', 'Stu@25243100'),
              _accountChip('JANANI Y (II-B: 25243068)', '25243068', 'Stu@25243068'),
              _accountChip('MUHIL RAJA A (II-C: 25243129)', '25243129', 'Stu@25243129'),
              _accountChip('SAHANA S (II-D: 25243189)', '25243189', 'Stu@25243189'),
              _accountChip('Dinesh (II-D: 25243301)', '25243301', 'Stu@25243301'),
              _accountChip('AKASH I (III-A: 24243007)', '24243007', 'Stu@24243007'),
              _accountChip('S.AARTHI (IV-A: 23243001)', '23243001', 'Stu@23243001'),
              _accountChip('S. HARINI (IV-B: 23243034)', '23243034', 'Stu@23243034'),
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
        _usernameCtrl.text = username;
        _passwordCtrl.text = password ?? 'password123';
      },
    );
  }

  Widget _buildSkyCloudHeader() {
    return Container(
      width: double.infinity,
      height: 290,
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _cloudAnimController,
            builder: (ctx, child) {
              return Positioned(
                top: 20,
                left: -100 + (_cloudAnimController.value * (MediaQuery.of(context).size.width + 200)),
                child: Opacity(
                  opacity: 0.35,
                  child: const Icon(Icons.cloud_rounded, size: 140, color: Colors.white),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _cloudAnimController,
            builder: (ctx, child) {
              return Positioned(
                top: 110,
                right: -80 + (_cloudAnimController.value * (MediaQuery.of(context).size.width + 160)),
                child: Opacity(
                  opacity: 0.25,
                  child: const Icon(Icons.cloud_queue_rounded, size: 110, color: Colors.white),
                ),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('PinkSlipReport', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text('V.S.B. Engineering College • Dept of AI & DS', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 6),
                  const Text(
                    'Official Academic Portal',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
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
                    decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.co_present_rounded, color: Color(0xFF047857), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All 10 Section Class Advisors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('Select any Advisor to load their official Username & Password', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                          backgroundColor: const Color(0xFFD1FAE5),
                          child: Text(
                            '${adv.year}${adv.section}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                          ),
                        ),
                        title: Text(adv.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${adv.classSection} • ${adv.batchYear}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text('User: ${adv.username}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                                const SizedBox(width: 10),
                                Text('Pass: ${adv.password}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedRoleTab = 1;
                              _usernameCtrl.text = adv.username;
                              _passwordCtrl.text = adv.password;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Loaded credentials for ${adv.name} (${adv.classSection})! Ready to Sign In ⚡'),
                                backgroundColor: const Color(0xFF047857),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
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

  Future<void> _showAllClassRepsDialog() async {
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
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.people_alt_rounded, color: AppColors.primaryPurple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All 20 Class Representatives (CRs)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('1 Boy CR & 1 Girl CR per section • Select to load login', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                  itemCount: AuthService.classRepresentatives.length,
                  itemBuilder: (context, i) {
                    final cr = AuthService.classRepresentatives[i];
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
                          radius: 16,
                          backgroundColor: cr.gender == 'Girl' ? const Color(0xFFFDF2F8) : const Color(0xFFEFF6FF),
                          child: Text(
                            cr.gender == 'Girl' ? '♀' : '♂',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cr.gender == 'Girl' ? Colors.pink : Colors.blue,
                            ),
                          ),
                        ),
                        title: Text('${cr.name} (${cr.gender} CR)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${cr.rollNumber} • ${cr.classSection} (${cr.batchYear})', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text('User: ${cr.username}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                                const SizedBox(width: 10),
                                Text('Pass: ${cr.password}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedRoleTab = 2;
                              _usernameCtrl.text = cr.username;
                              _passwordCtrl.text = cr.password;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Loaded credentials for ${cr.name} (${cr.gender} CR)! Ready to Sign In ⚡'),
                                backgroundColor: const Color(0xFF0284C7),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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

  Future<void> _showCredentialsDirectoryDialog() async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => const _CredentialsDirectoryDialog(),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (result['role'] == UserRole.hod) {
          _selectedRoleTab = 0;
        } else if (result['role'] == UserRole.advisor) {
          _selectedRoleTab = 1;
        } else {
          _selectedRoleTab = 2;
        }
        _usernameCtrl.text = result['username'] ?? '';
        _passwordCtrl.text = result['password'] ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded credentials for ${result['name']}! Ready to Sign In ⚡'),
          backgroundColor: const Color(0xFF0284C7),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CredentialsDirectoryDialog extends StatefulWidget {
  const _CredentialsDirectoryDialog();

  @override
  State<_CredentialsDirectoryDialog> createState() => _CredentialsDirectoryDialogState();
}

class _CredentialsDirectoryDialogState extends State<_CredentialsDirectoryDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _studentSearchCtrl = TextEditingController();
  String _studentQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.badge_rounded, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Official Credentials Directory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('PDF generated • Tap any entry to auto-fill login', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF0284C7),
                labelColor: const Color(0xFF0284C7),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(text: '🏛️ HOD (2)'),
                  Tab(text: '👨‍🏫 Advisors (10)'),
                  Tab(text: '🎓 Students (622)'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHodList(),
                  _buildAdvisorList(),
                  _buildStudentList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHodList() {
    final hods = [
      {
        'name': 'DR. MANIVANNAN (Ph.D.)',
        'roleTitle': 'Overall Department HOD (III & IV Year)',
        'username': 'hod.manivannan',
        'password': 'Hod@Mani2026',
        'role': UserRole.hod,
      },
      {
        'name': 'Mrs. Kavitha',
        'roleTitle': 'Junior Wing HOD (I & II Year)',
        'username': 'hod.kavitha',
        'password': 'Hod@Kavi2026',
        'role': UserRole.hod,
      },
    ];

    return ListView.builder(
      itemCount: hods.length,
      itemBuilder: (context, i) {
        final h = hods[i];
        return _credentialCard(
          title: h['name'] as String,
          subtitle: h['roleTitle'] as String,
          username: h['username'] as String,
          password: h['password'] as String,
          badge: 'HOD PORTAL',
          badgeColor: const Color(0xFF312E81),
          onTap: () => Navigator.pop(context, h),
        );
      },
    );
  }

  Widget _buildAdvisorList() {
    final advisors = [
      {'name': 'Mr. Muthuselvan', 'class': 'IV AI&DS - Section A', 'username': 'advisor.muthuselvan', 'password': 'Adv@Muthu4A', 'role': UserRole.advisor},
      {'name': 'Mrs. Nandhinidevi', 'class': 'IV AI&DS - Section B', 'username': 'advisor.nandhinidevi', 'password': 'Adv@Nandhini4B', 'role': UserRole.advisor},
      {'name': 'Ms. C. Vishnupriya', 'class': 'III AI&DS - Section A', 'username': 'advisor.vishnupriya', 'password': 'Adv@Vishnu3A', 'role': UserRole.advisor},
      {'name': 'Dr. R. Murugesan', 'class': 'III AI&DS - Section B', 'username': 'advisor.murugesan', 'password': 'Adv@Murugesan3B', 'role': UserRole.advisor},
      {'name': 'Mrs. B. Bharathi', 'class': 'III AI&DS - Section C', 'username': 'advisor.bharathi', 'password': 'Adv@Bharathi3C', 'role': UserRole.advisor},
      {'name': 'Mr. Velusamy', 'class': 'III AI&DS - Section D', 'username': 'advisor.velusamy', 'password': 'Adv@Velu3D', 'role': UserRole.advisor},
      {'name': 'Dr. D. Anandhan', 'class': 'II AI&DS - Section A', 'username': 'advisor.anandhan', 'password': 'Adv@Anandh2A', 'role': UserRole.advisor},
      {'name': 'Dr. M. Rajendiran', 'class': 'II AI&DS - Section B', 'username': 'advisor.rajendiran', 'password': 'Adv@Rajen2B', 'role': UserRole.advisor},
      {'name': 'Mr. A. Bharathidasan', 'class': 'II AI&DS - Section C', 'username': 'advisor.bharathidasan', 'password': 'Adv@Bharathi2C', 'role': UserRole.advisor},
      {'name': 'Mr. R. Palraj', 'class': 'II AI&DS - Section D', 'username': 'advisor.palraj', 'password': 'Adv@Palraj2D', 'role': UserRole.advisor},
    ];

    return ListView.builder(
      itemCount: advisors.length,
      itemBuilder: (context, i) {
        final adv = advisors[i];
        return _credentialCard(
          title: adv['name'] as String,
          subtitle: '${adv['class']}',
          username: adv['username'] as String,
          password: adv['password'] as String,
          badge: 'CLASS ADVISOR',
          badgeColor: const Color(0xFF065F46),
          onTap: () => Navigator.pop(context, adv),
        );
      },
    );
  }

  Widget _buildStudentList() {
    final filtered = StudentDirectoryData.allStudents.where((s) {
      final q = _studentQuery.toLowerCase().trim();
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) ||
          s.rollNumber.contains(q) ||
          s.section.toLowerCase() == q ||
          '${s.year}${s.section}'.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        TextField(
          controller: _studentSearchCtrl,
          decoration: InputDecoration(
            hintText: 'Search by student name or roll no (622 total)...',
            hintStyle: const TextStyle(fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          onChanged: (v) => setState(() => _studentQuery = v),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final s = filtered[i];
              return _credentialCard(
                title: s.name,
                subtitle: '${s.rollNumber} • ${s.classDisplay} (${s.batchYear})',
                username: s.rollNumber,
                password: 'Stu@${s.rollNumber}',
                badge: '${s.romanYear}-${s.section}',
                badgeColor: const Color(0xFF0284C7),
                onTap: () => Navigator.pop(context, {
                  'name': s.name,
                  'username': s.rollNumber,
                  'password': 'Stu@${s.rollNumber}',
                  'role': UserRole.student,
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _credentialCard({
    required String title,
    required String subtitle,
    required String username,
    required String password,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
                        child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('User: $username', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                      const SizedBox(width: 12),
                      Text('Pass: $password', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
