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
  String selectedLocation = 'All';

  final List<String> categories = [
    'All', 'food', 'exercise', 'Travel', 'concert'
  ];

  final List<String> locations = [
    'All', 'General', 'MFU', 'RSU', 'CMU', 
  ];

  Stream<QuerySnapshot> _buildQuery() {
    if (selectedCategory == 'All') {
      return FirebaseFirestore.instance
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    return FirebaseFirestore.instance
        .collection('activities')
        .where('category', isEqualTo: selectedCategory)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

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
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xff5aaee0), width: 2),
                      ),
                      child: const Icon(Icons.person_outline,
                          color: Color(0xff5aaee0), size: 24),
                    ),
                  ),

                  const SizedBox(width: 5),

                  // ---- Location Dropdown ----
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selectedLocation != 'All'
                              ? const Color(0xff3a8fc7)
                              : Colors.black12,
                          width: 1.2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedLocation,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: selectedLocation != 'All'
                                ? const Color(0xff3a8fc7)
                                : Colors.black38,
                            size: 18,
                          ),
                          isExpanded: true,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          items: locations.map((loc) {
                            return DropdownMenuItem<String>(
                              value: loc,
                              child: Row(
                                children: [
                                  Icon(
                                    loc == 'All'
                                        ? Icons.public
                                        : Icons.location_on,
                                    size: 14,
                                    color: loc == selectedLocation
                                        ? const Color(0xff3a8fc7)
                                        : Colors.black38,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    loc == 'All' ? 'All Location' : loc,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: loc == selectedLocation
                                          ? const Color(0xff3a8fc7)
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => selectedLocation = val!),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ✅ Create activity button (+ icon)
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

            const SizedBox(height: 10),

            // ---- Activity List from Firestore ----
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildQuery(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // filter location ฝั่ง client (ไม่ต้องสร้าง composite index เพิ่ม)
                  final allDocs = snapshot.data?.docs ?? [];
                  final docs = selectedLocation == 'All'
                      ? allDocs
                      : allDocs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return (data['location'] as String? ?? '')
                              .toLowerCase()
                              .contains(selectedLocation.toLowerCase());
                        }).toList();

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
                            "ยังไม่มีกิจกรรม",
                            style: TextStyle(fontSize: 16, color: Colors.black38),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "กด + เพื่อสร้างกิจกรรมแรกของคุณ",
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

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityCard({required this.activity});

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
            child: Container(
              height: 150,
              width: double.infinity,
              color: const Color(0xffcce3f5),
              child: const Icon(Icons.image_outlined,
                  size: 48, color: Colors.white54),
            ),
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
                    const Icon(Icons.person_outline,
                        size: 20, color: Colors.black38),
                    const SizedBox(width: 6),
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
