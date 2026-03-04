import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_detail_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  Future<void> markAllRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final unread = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markOneRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  String timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xffe2edf5),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header ----
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
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
                    "Notifications",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  // Mark all read button
                  TextButton(
                    onPressed: () => markAllRead(uid),
                    child: const Text(
                      "Mark all read",
                      style: TextStyle(
                          fontSize: 13, color: Color(0xff5aaee0)),
                    ),
                  ),
                ],
              ),
            ),

            // ---- Notification List ----
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('toUserId', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_outlined,
                              size: 64,
                              color: Colors.black.withOpacity(0.15)),
                          const SizedBox(height: 12),
                          const Text(
                            "No notifications yet",
                            style: TextStyle(
                                fontSize: 15, color: Colors.black38),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final isRead = data['isRead'] as bool? ?? false;
                      final activityId =
                          data['activityId'] as String? ?? '';

                      return GestureDetector(
                        onTap: () async {
                          await markOneRead(doc.id);
                          if (activityId.isNotEmpty && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActivityDetailPage(
                                    activityId: activityId),
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead
                                ? Colors.white
                                : const Color(0xffe8f4fd),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isRead
                                  ? Colors.transparent
                                  : const Color(0xff5aaee0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xffcce3f5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.person_add_outlined,
                                    color: Color(0xff5aaee0),
                                    size: 20),
                              ),
                              const SizedBox(width: 12),

                              // Message
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['message'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isRead
                                            ? FontWeight.w400
                                            : FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeAgo(data['createdAt']),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black38),
                                    ),
                                  ],
                                ),
                              ),

                              // Unread dot
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xff5aaee0),
                                    shape: BoxShape.circle,
                                  ),
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
          ],
        ),
      ),
    );
  }
}
