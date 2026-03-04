import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CreateActivityPage extends StatefulWidget {
  const CreateActivityPage({super.key});

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();
  final maxController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String selectedCategory = 'exercise';
  bool isLoading = false;

  XFile? pickedImage;
  Uint8List? pickedImageBytes;
  final ImagePicker _picker = ImagePicker();

  final List<String> categories = ['food', 'exercise', 'Travel', 'concert'];

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    locationController.dispose();
    maxController.dispose();
    super.dispose();
  }

  // ---- Pick image from gallery ----
  Future<void> pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        pickedImage = image;
        pickedImageBytes = bytes;
      });
    }
  }

  // ---- Upload image to Firebase Storage (Web + Mobile) ----
  Future<String?> uploadImage(String activityId) async {
    if (pickedImage == null || pickedImageBytes == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('activity_images/$activityId.jpg');
      await ref.putData(
        pickedImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xff5aaee0),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xff5aaee0),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => startTime = picked);
  }

  Future<void> pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xff5aaee0),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => endTime = picked);
  }

  String formatDate(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return "${days[d.weekday]} ${d.day} ${months[d.month]} ${d.year}";
  }

  String formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  Future<void> createActivity() async {
    if (titleController.text.trim().isEmpty) {
      showError("Please enter activity title"); return;
    }
    if (descController.text.trim().isEmpty) {
      showError("Please enter a description"); return;
    }
    if (selectedDate == null) {
      showError("Please select a date"); return;
    }
    if (startTime == null || endTime == null) {
      showError("Please select start and end time"); return;
    }
    if (locationController.text.trim().isEmpty) {
      showError("Please enter a location"); return;
    }
    if (maxController.text.trim().isEmpty ||
        int.tryParse(maxController.text.trim()) == null ||
        int.parse(maxController.text.trim()) < 1) {
      showError("Please enter a valid number of participants"); return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final displayName =
          user?.displayName ?? user?.email?.split('@').first ?? 'Unknown';

      // Create doc first to get id for image filename
      final docRef =
          FirebaseFirestore.instance.collection('activities').doc();

      // Upload image first (if any)
      String? imageUrl = await uploadImage(docRef.id);

      await docRef.set({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'date': formatDate(selectedDate!),
        'time': "${formatTime(startTime!)} – ${formatTime(endTime!)}",
        'location': locationController.text.trim(),
        'category': selectedCategory,
        'maxParticipants': int.parse(maxController.text.trim()),
        'participants': [],
        'hostId': user?.uid ?? '',
        'hostName': displayName,
        'hostEmail': user?.email ?? '',
        'imageUrl': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Activity created successfully!")),
        );
      }
    } catch (e) {
      showError("An error occurred: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe2edf5),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xff5aaee0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    "Create Activity",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            // ---- Form ----
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xffc5dff0),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ---- Activity Image ----
                      _label("Activity Image"),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: pickedImageBytes != null
                                  ? const Color(0xff5aaee0)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: pickedImageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.memory(
                                    pickedImageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 40, color: Colors.black26),
                                    SizedBox(height: 8),
                                    Text(
                                      "Tap to select image",
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black38),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---- Activity Title ----
                      _label("Activity Title"),
                      const SizedBox(height: 6),
                      _inputField(
                        hint: "Enter activity title",
                        icon: Icons.title,
                        controller: titleController,
                      ),

                      const SizedBox(height: 16),

                      // ---- Description ----
                      _label("Description"),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Describe your activity...",
                          hintStyle: const TextStyle(
                              color: Colors.black38, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xff5aaee0), width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---- Category ----
                      _label("Category"),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.category_outlined,
                                color: Colors.black38, size: 20),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 14),
                            border: InputBorder.none,
                          ),
                          items: categories
                              .map((c) => DropdownMenuItem(
                                  value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => selectedCategory = v!),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---- Date ----
                      _label("Date"),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined,
                                  color: Colors.black38, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                selectedDate != null
                                    ? formatDate(selectedDate!)
                                    : "Select date",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: selectedDate != null
                                      ? Colors.black87
                                      : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---- Time ----
                      _label("Time"),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: pickStartTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        color: Colors.black38, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      startTime != null
                                          ? formatTime(startTime!)
                                          : "Start",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: startTime != null
                                            ? Colors.black87
                                            : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text("–",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.black45)),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: pickEndTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        color: Colors.black38, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      endTime != null
                                          ? formatTime(endTime!)
                                          : "End",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: endTime != null
                                            ? Colors.black87
                                            : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ---- Location ----
                      _label("Location"),
                      const SizedBox(height: 6),
                      _inputField(
                        hint: "Enter location",
                        icon: Icons.location_on_outlined,
                        controller: locationController,
                      ),

                      const SizedBox(height: 16),

                      // ---- Max Participants ----
                      _label("Max Participants"),
                      const SizedBox(height: 6),
                      _inputField(
                        hint: "e.g. 10",
                        icon: Icons.people_outline,
                        controller: maxController,
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 28),

                      // ---- Submit Button ----
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : createActivity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff5aaee0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
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
                                  "Create Activity",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54),
      );

  Widget _inputField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.black38, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xff5aaee0), width: 1.5),
        ),
      ),
    );
  }
}
