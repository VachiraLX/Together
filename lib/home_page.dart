import 'package:flutter/material.dart';
import 'notification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_detail_page.dart';
import 'profile_page.dart';
import 'create_activity_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = 'All';

  final List<String> categories = [
    'All', 'food', 'exercise', 'Travel', 'concert'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe2edf5),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Top Bar ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Profile avatar
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                    child: _ProfileAvatar(),
                  ),

                  const Spacer(),

                  // Create activity button (+ icon)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateActivityPage()),
                    ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xff5aaee0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 26),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Notification bell with badge
                  _NotificationBell(),
                ],
              ),
            ),

            // ---- Category Chips ----
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final isSelected = cat == selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xff7c4dff)
                            : const Color(0xffcce3f5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ---- Activity List from Firestore ----
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedCategory == 'All'
                    ? FirebaseFirestore.instance
                        .collection('activities')
                        .orderBy('createdAt', descending: true)
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('activities')
                        .where('category', isEqualTo: selectedCategory)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note_outlined,
                              size: 64,
                              color: Colors.black.withOpacity(0.15)),
                          const SizedBox(height: 14),
                          const Text(
                            "No activities yet",
                            style: TextStyle(fontSize: 16, color: Colors.black38),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Tap + to create your first activity",
                            style: TextStyle(fontSize: 13, color: Colors.black26),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      data['id'] = docs[i].id;
                      return _ActivityCard(activity: data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Notification Bell Widget ----
class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('toUserId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationPage()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xff5aaee0), width: 2),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Color(0xff5aaee0), size: 22),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---- Profile Avatar Widget ----
class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          border: Border.all(color: const Color(0xff5aaee0), width: 2),
        ),
        child: const Icon(Icons.person_outline, color: Color(0xff5aaee0), size: 24),
      );
    }

    if (uid.isEmpty) return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        border: Border.all(color: const Color(0xff5aaee0), width: 2),
      ),
      child: const Icon(Icons.person_outline, color: Color(0xff5aaee0), size: 24),
    );
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final photoUrl = (snapshot.data?.data() as Map<String, dynamic>?)?['photoUrl'] as String? ?? '';
        final authPhotoUrl = FirebaseAuth.instance.currentUser?.photoURL ?? '';
        final finalUrl = photoUrl.isNotEmpty ? photoUrl : authPhotoUrl;

        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xff5aaee0), width: 2),
          ),
          child: ClipOval(
            child: finalUrl.isNotEmpty
                ? Image.network(
                    finalUrl,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_outline,
                      color: Color(0xff5aaee0),
                      size: 24,
                    ),
                  )
                : const Icon(Icons.person_outline,
                    color: Color(0xff5aaee0), size: 24),
          ),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityCard({required this.activity});

  Widget _buildActivityImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _imagePlaceholder();
        },
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      color: const Color(0xffcce3f5),
      child: const Icon(Icons.image_outlined, size: 48, color: Colors.white54),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = (activity['participants'] as List?)?.length ?? 0;
    final max = activity['maxParticipants'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildActivityImage(activity['imageUrl']),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? '',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _HostAvatar(hostId: activity['hostId'] ?? ''),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Host",
                              style: TextStyle(
                                  fontSize: 11, color: Colors.black38)),
                          Text(
                            activity['hostName'] ?? '',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "$current/$max",
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black45),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityDetailPage(
                              activityId: activity['id']),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xffe8f4fd),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xff5aaee0), width: 1),
                        ),
                        child: const Text(
                          "View",
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff5aaee0),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Host Avatar Widget ----
class _HostAvatar extends StatelessWidget {
  final String hostId;
  const _HostAvatar({required this.hostId});

  @override
  Widget build(BuildContext context) {
    if (hostId.isEmpty) {
      return _placeholder();
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(hostId).get(),
      builder: (_, snap) {
        final photoUrl =
            (snap.data?.data() as Map<String, dynamic>?)?['photoUrl']
                as String? ??
                '';
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xffcce3f5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xff5aaee0), width: 1.5),
          ),
          child: ClipOval(
            child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _icon(),
                  )
                : _icon(),
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xffcce3f5),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xff5aaee0), width: 1.5),
        ),
        child: _icon(),
      );

  Widget _icon() =>
      const Icon(Icons.person_outline, size: 20, color: Color(0xff5aaee0));
}
