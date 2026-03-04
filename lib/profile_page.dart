import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'activity_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  late TextEditingController nameController;
  bool isEditingName = false;
  bool isUploadingPhoto = false;

  // Tab: 0 = Joined, 1 = Created
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? 'Your name',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  // ---- Change profile photo ----
  Future<void> changeProfilePhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;

    setState(() => isUploadingPhoto = true);

    try {
      final Uint8List bytes = await image.readAsBytes();
      final uid = user?.uid ?? '';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/$uid.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final photoUrl = await ref.getDownloadURL();

      // Update Firebase Auth profile
      await user?.updatePhotoURL(photoUrl);

      // Reload user to update photoURL in instance
      await FirebaseAuth.instance.currentUser?.reload();

      // Update Firestore users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'photoUrl': photoUrl}, SetOptions(merge: true));

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile photo updated successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isUploadingPhoto = false);
    }
  }

  // ---- Save name ----
  Future<void> saveName() async {
    final newName = nameController.text.trim();
    if (newName.isEmpty) return;
    try {
      await user?.updateDisplayName(newName);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .set({'displayName': newName}, SetOptions(merge: true));

      if (mounted) {
        setState(() => isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name saved successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("An error occurred: $e")));
    }
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text("Sign out",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          "Are you sure you want to sign out?",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Sign out"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // popUntil before signOut so Navigator works before widget is disposed
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid ?? '';
    final email = user?.email ?? '';
    final username = '@${email.split('@').first}';
    // Read from currentUser on every rebuild to get latest photoURL
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL ?? '';

    return Scaffold(
      backgroundColor: const Color(0xff5aaee0),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Back button ----
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),

            // ---- TOGETHER header ----
            Column(
              children: [
                const Text(
                  "TOGETHER",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(1.0, -1.0),
                  child: Text(
                    "TOGETHER",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ---- Profile Card ----
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // ---- Avatar ----
                    Stack(
                      children: [
                        // Profile photo — always fetch from Firestore
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .snapshots(),
                          builder: (context, snap) {
                            final firestoreUrl =
                                (snap.data?.data() as Map<String, dynamic>?)?['photoUrl'] as String? ?? '';
                            final authUrl =
                                FirebaseAuth.instance.currentUser?.photoURL ??
                                    '';
                            final photoUrl = firestoreUrl.isNotEmpty
                                ? firestoreUrl
                                : authUrl;
                            return Container(
                              width: 90,
                              height: 90,
                              decoration: const BoxDecoration(
                                color: Color(0xffb0b0b0),
                                shape: BoxShape.circle,
                              ),
                              child: isUploadingPhoto
                                  ? const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5)
                                  : ClipOval(
                                      child: photoUrl.isNotEmpty
                                          ? Image.network(
                                              photoUrl,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                      Icons.person_outline,
                                                      size: 48,
                                                      color: Colors.white),
                                            )
                                          : const Icon(Icons.person_outline,
                                              size: 48, color: Colors.white),
                                    ),
                            );
                          },
                        ),

                        // Change photo button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: changeProfilePhoto,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xff5aaee0),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ---- Name (editable) ----
                    isEditingName
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 160,
                                child: TextField(
                                  controller: nameController,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 8),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: saveName,
                                child: const Icon(Icons.check_circle,
                                    color: Color(0xff5aaee0), size: 26),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                nameController.text.isNotEmpty
                                    ? nameController.text
                                    : 'Your name',
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => isEditingName = true),
                                child: const Icon(Icons.edit_outlined,
                                    size: 16, color: Colors.black38),
                              ),
                            ],
                          ),

                    const SizedBox(height: 4),

                    Text(
                      username,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff7c4dff),
                          fontWeight: FontWeight.w500),
                    ),

                    const SizedBox(height: 16),

                    // ---- Stats ----
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('activities')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        final joined = docs
                            .where((d) =>
                                (d['participants'] as List).contains(uid))
                            .length;
                        final created = docs
                            .where((d) => d['hostId'] == uid)
                            .length;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _statItem(joined.toString(), "Join"),
                            _divider(),
                            _statItem(created.toString(), "Create"),
                            _divider(),
                            _statItem(
                                (joined + created).toString(), "Total"),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ---- Tab: joined / Created ----
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedTab = 0),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: selectedTab == 0
                                        ? const Color(0xff5aaee0)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                "joined",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selectedTab == 0
                                      ? const Color(0xff5aaee0)
                                      : Colors.black38,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedTab = 1),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: selectedTab == 1
                                        ? const Color(0xff5aaee0)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                "Created",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selectedTab == 1
                                      ? const Color(0xff5aaee0)
                                      : Colors.black38,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ---- Activity List ----
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: selectedTab == 0
                            ? FirebaseFirestore.instance
                                .collection('activities')
                                .where('participants', arrayContains: uid)
                                .snapshots()
                            : FirebaseFirestore.instance
                                .collection('activities')
                                .where('hostId', isEqualTo: uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final docs = snapshot.data?.docs ?? [];

                          if (docs.isEmpty) {
                            return Center(
                              child: Text(
                                selectedTab == 0
                                    ? "No activities joined yet"
                                    : "No activities created yet",
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black38),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (_, i) {
                              final data = docs[i].data()
                                  as Map<String, dynamic>;
                              final id = docs[i].id;
                              final imageUrl = data['imageUrl'] ?? '';
                              final current =
                                  (data['participants'] as List?)
                                          ?.length ??
                                      0;
                              final max =
                                  data['maxParticipants'] ?? 0;

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ActivityDetailPage(
                                        activityId: id),
                                  ),
                                ),
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xfff0f7fc),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      // Activity image
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 54,
                                          height: 54,
                                          child: imageUrl.isNotEmpty
                                              ? Image.network(imageUrl,
                                                  fit: BoxFit.cover)
                                              : Container(
                                                  color: const Color(
                                                      0xffcce3f5),
                                                  child: const Icon(
                                                      Icons.image_outlined,
                                                      color: Colors.white54,
                                                      size: 24),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['title'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w700),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              data['date'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black38),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "$current/$max",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black38),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ---- Logout Button ----
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: logout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text(
                            "Sign out",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffffeeee),
                            foregroundColor: Colors.redAccent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                  color: Colors.redAccent, width: 1.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 28,
        width: 1,
        color: Colors.black12,
      );
}
