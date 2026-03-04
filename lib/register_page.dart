import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final dobController = TextEditingController();

  String? selectedGender;
  bool acceptTerms = false;
  bool isLoading = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    // Validation
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty) {
      showError("Please enter your first and last name");
      return;
    }
    if (emailController.text.trim().isEmpty) {
      showError("Please enter your email");
      return;
    }
    if (phoneController.text.trim().isEmpty) {
      showError("Please enter your phone number");
      return;
    }
    if (selectedGender == null) {
      showError("Please select your gender");
      return;
    }
    if (dobController.text.trim().isEmpty) {
      showError("Please enter your date of birth");
      return;
    }
    if (passwordController.text.isEmpty) {
      showError("Please enter your password");
      return;
    }
    if (passwordController.text != confirmController.text) {
      showError("Passwords do not match");
      return;
    }
    if (!acceptTerms) {
      showError("Please accept Terms and Conditions");
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user?.uid ?? '';
      final displayName =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}';

      // Update displayName in Firebase Auth
      await credential.user?.updateDisplayName(displayName);

      // Create document in Firestore users collection
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'displayName': displayName,
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'gender': selectedGender,
        'dob': dobController.text.trim(),
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      showError(e.message ?? "Register failed");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dobController.text =
          "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe2edf5),
      body: SafeArea(
        child: Column(
          children: [
            // Back button row
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff5aaee0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xffc5dff0),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- TOGETHER title ----
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "TOGETHER",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 6,
                                color: Colors.black87,
                                decoration: TextDecoration.underline,
                                decorationThickness: 1.5,
                              ),
                            ),
                            Transform(
                              alignment: Alignment.center,
                              transform:
                                  Matrix4.identity()..scale(1.0, -1.0),
                              child: Text(
                                "TOGETHER",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  color:
                                      Colors.black87.withOpacity(0.18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Center(
                        child: Text(
                          "Register your accounts",
                          style: TextStyle(
                              fontSize: 14, color: Colors.black54),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---- First name + Last name ----
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _label("First name"),
                                const SizedBox(height: 6),
                                _inputField(
                                  hint: "Fill first name",
                                  icon: Icons.person_outline,
                                  controller: firstNameController,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _label("Last name"),
                                const SizedBox(height: 6),
                                _inputField(
                                  hint: "Fill last name",
                                  icon: Icons.person_outline,
                                  controller: lastNameController,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ---- Email ----
                      _label("Email"),
                      const SizedBox(height: 6),
                      _inputField(
                        hint: "Fill your email",
                        icon: Icons.email_outlined,
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 14),

                      // ---- Phone number ----
                      _label("Phone number"),
                      const SizedBox(height: 6),
                      _inputField(
                        hint: "Fill your Phone number",
                        icon: Icons.phone_outlined,
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 14),

                      // ---- Gender + Date of birth ----
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _label("Gender"),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedGender,
                                    decoration: const InputDecoration(
                                      contentPadding:
                                          EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14),
                                      border: InputBorder.none,
                                    ),
                                    hint: const Text("Select Gender",
                                        style: TextStyle(
                                            color: Colors.black38,
                                            fontSize: 13)),
                                    items: const [
                                      DropdownMenuItem(
                                          value: "Male",
                                          child: Text("Male")),
                                      DropdownMenuItem(
                                          value: "Female",
                                          child: Text("Female")),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => selectedGender = v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _label("Date of birth"),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: AbsorbPointer(
                                    child: _inputField(
                                      hint: "MM/DD/YYYY",
                                      icon: Icons.calendar_month_outlined,
                                      controller: dobController,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ---- Password ----
                      _label("Password"),
                      const SizedBox(height: 6),
                      _inputField(
                        hint: "Fill your password",
                        icon: Icons.lock_outline,
                        controller: passwordController,
                        obscure: true,
                      ),

                      const SizedBox(height: 14),

                      // ---- Confirm Password ----
                      _label("Confirm password"),
                      const SizedBox(height: 6),
                      _inputField(
                        hint: "Confirm your password",
                        icon: Icons.lock_outline,
                        controller: confirmController,
                        obscure: true,
                      ),

                      const SizedBox(height: 12),

                      // ---- Terms & Conditions ----
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: acceptTerms,
                              onChanged: (v) =>
                                  setState(() => acceptTerms = v!),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              side: const BorderSide(color: Colors.black38),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "I accept Terms and Conditions and the Privacy Policy",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ---- Register Button ----
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff5aaee0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Register",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.black38, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xff5aaee0), width: 1.5),
        ),
      ),
    );
  }
}
