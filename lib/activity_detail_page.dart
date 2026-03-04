import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityDetailPage extends StatefulWidget {
  final String activityId;
  const ActivityDetailPage({super.key, required this.activityId});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  bool isLoading = false;

  Future<void> toggleJoin(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final List participants = List.from(data['participants'] ?? []);
    final int maxP = data['maxParticipants'] ?? 0;
    final bool hasJoined = participants.contains(uid);
    final ref = FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId);

    setState(() => isLoading = true);

    try {
      if (hasJoined) {
        await ref.update({
          'participants': FieldValue.arrayRemove([uid])
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Left the activity")));
        }
      } else {
        if (participants.length >= maxP) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Activity is full")));
          }
          return;
        }
        await ref.update({
          'participants': FieldValue.arrayUnion([uid])
        });

        // Send notification to host
        final hostId = data['hostId'] ?? '';
        if (hostId.isNotEmpty && hostId != uid) {
          final joinerName = user.displayName ??
              user.email?.split('@').first ?? 'Someone';
          final activityTitle = data['title'] ?? 'Activity';
          await FirebaseFirestore.instance.collection('notifications').add({
            'toUserId': hostId,
            'fromUserId': uid,
            'fromUserName': joinerName,
            'activityId': widget.activityId,
            'activityTitle': activityTitle,
            'message': '$joinerName joined "$activityTitle"',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Joined successfully!")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("An error occurred: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> deleteActivity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text("Delete Activity",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this activity? This cannot be undone.",
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
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isLoading = true);
    try {
      // ลบ comments subcollection ก่อน
      final comments = await FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.activityId)
          .collection('comments')
          .get();
      for (final doc in comments.docs) {
        await doc.reference.delete();
      }
      // ลบ activity document
      await FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.activityId)
          .delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Activity deleted successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("An error occurred: \$e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffe2edf5),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .doc(widget.activityId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Activity not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List participants = List.from(data['participants'] ?? []);
          final int maxP = data['maxParticipants'] ?? 0;
          final String hostId = data['hostId'] ?? '';
          final bool isHost = user?.uid == hostId;
          final bool hasJoined =
              user != null && participants.contains(user.uid);
          final bool isFull = participants.length >= maxP;
          final String imageUrl = data['imageUrl'] ?? '';

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Hero Image + Back ----
                  Stack(
                    children: [
                      // Activity image
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: const Color(0xffcce3f5),
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xffcce3f5),
                                  child: const Icon(Icons.image_outlined,
                                      size: 60, color: Colors.white54),
                                ),
                              )
                            : Container(
                                color: const Color(0xffcce3f5),
                                child: const Icon(Icons.image_outlined,
                                    size: 60, color: Colors.white54),
                              ),
                      ),

                      // Back button
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
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
                      ),
                    ],
                  ),

                  // ---- Content ----
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          data['title'] ?? '',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),

                        // Description
                        Text(
                          data['description'] ?? '',
                          style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.5),
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xffe0ecf5)),
                        const SizedBox(height: 20),

                        // Info rows
                        _infoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'date',
                          value: data['date'] ?? '',
                        ),
                        const SizedBox(height: 14),
                        _infoRow(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: data['time'] ?? '',
                        ),
                        const SizedBox(height: 14),
                        _infoRow(
                          icon: Icons.location_on_outlined,
                          label: 'location',
                          value: data['location'] ?? '',
                        ),

                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xffe0ecf5)),
                        const SizedBox(height: 20),

                        // Participants
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Participants",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              "${participants.length}/$maxP",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black45),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (participants.isNotEmpty)
                          SizedBox(
                            height: 44,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: participants.length > 10
                                  ? 10
                                  : participants.length,
                              itemBuilder: (_, i) => _ParticipantAvatar(
                                uid: participants[i].toString(),
                              ),
                            ),
                          )
                        else
                          const Text(
                            "No participants yet",
                            style: TextStyle(
                                fontSize: 13, color: Colors.black38),
                          ),

                        const SizedBox(height: 28),

                        // ---- Join / Leave / Host badge ----
                        isHost
                            ? Column(
                                children: [
                                  // Host badge
                                  Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xfff0f4f8),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.black12, width: 1),
                                    ),
                                    child: const Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.star_rounded,
                                              color: Color(0xffffc107),
                                              size: 20),
                                          SizedBox(width: 6),
                                          Text(
                                            "You are the host of this activity",
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Delete button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          isLoading ? null : deleteActivity,
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20),
                                      label: const Text(
                                        "Delete Activity",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xffffeeee),
                                        foregroundColor: Colors.redAccent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          side: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 1.2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed:
                                      (isLoading || (!hasJoined && isFull))
                                          ? null
                                          : () => toggleJoin(data),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasJoined
                                        ? Colors.redAccent
                                        : const Color(0xff5aaee0),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5),
                                        )
                                      : Text(
                                          hasJoined
                                              ? "Leave"
                                              : isFull
                                                  ? "Full"
                                                  : "Join",
                                          style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700),
                                        ),
                                ),
                              ),

                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xffe0ecf5)),
                        const SizedBox(height: 20),

                        // ---- Comment Section ----
                        const Text(
                          "Comments",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),

                        _CommentSection(
                          activityId: widget.activityId,
                          participants: participants,
                          isHost: isHost,
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
              color: Color(0xffcce3f5), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: const Color(0xff5aaee0)),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Colors.black38)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ---- Participant Avatar: fetch photo from Firestore ----
class _ParticipantAvatar extends StatelessWidget {
  final String uid;
  const _ParticipantAvatar({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final photoUrl = (snapshot.data?.data() as Map<String, dynamic>?)?['photoUrl'] as String? ?? '';
        return Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: const Color(0xffcce3f5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_outline,
                      size: 20,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_outline,
                    size: 20, color: Colors.white),
          ),
        );
      },
    );
  }
}

// ============================================================
// Comment Section Widget
// ============================================================
class _CommentSection extends StatefulWidget {
  final String activityId;
  final List participants;
  final bool isHost;
  const _CommentSection({
    required this.activityId,
    required this.participants,
    required this.isHost,
  });

  @override
  State<_CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<_CommentSection> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch photoUrl from Firestore
    String photoUrl = user.photoURL ?? '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      photoUrl = (doc.data() as Map<String, dynamic>?)?['photoUrl'] as String? ?? photoUrl;
    } catch (_) {}

    setState(() => _isSending = true);
    _controller.clear();

    try {
      await FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.activityId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userName': user.displayName ?? user.email?.split('@').first ?? 'User',
        'photoUrl': photoUrl,
        'message': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _timeAgo(dynamic timestamp) {
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canComment =
        widget.isHost || widget.participants.contains(currentUid);

    return Column(
      children: [
        // ---- Comment list ----
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('activities')
              .doc(widget.activityId)
              .collection('comments')
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No comments yet.\nBe the first to comment!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black38, height: 1.6),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final isMe = data['userId'] == currentUid;
                return _CommentBubble(
                  data: data,
                  isMe: isMe,
                  timeAgo: _timeAgo(data['createdAt']),
                );
              },
            );
          },
        ),

        const SizedBox(height: 12),

        // ---- Input Box ----
        if (canComment)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _UserAvatar(uid: currentUid, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xfff0f7fc),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: const Color(0xff5aaee0), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          minLines: 1,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle:
                                TextStyle(color: Colors.black38, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6, bottom: 4),
                        child: GestureDetector(
                          onTap: _isSending ? null : _sendComment,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _isSending
                                  ? Colors.grey
                                  : const Color(0xff5aaee0),
                              shape: BoxShape.circle,
                            ),
                            child: _isSending
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xfff5f5f5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 16, color: Colors.black38),
                SizedBox(width: 8),
                Text(
                  'Join the activity to comment',
                  style: TextStyle(fontSize: 13, color: Colors.black38),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// Comment Bubble
// ============================================================
class _CommentBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final String timeAgo;
  const _CommentBubble(
      {required this.data, required this.isMe, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final photoUrl = data['photoUrl'] as String? ?? '';
    final userName = data['userName'] as String? ?? '';
    final message = data['message'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _UserAvatarFromUrl(photoUrl: photoUrl, size: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(userName,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xff5aaee0)
                        : const Color(0xfff0f7fc),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color: const Color(0xffcce3f5), width: 1),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : Colors.black87,
                        height: 1.4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(timeAgo,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.black38)),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _UserAvatarFromUrl(
                photoUrl: FirebaseAuth.instance.currentUser?.photoURL ?? '',
                size: 32),
          ],
        ],
      ),
    );
  }
}

// ---- Avatar helpers ----
class _UserAvatar extends StatelessWidget {
  final String uid;
  final double size;
  const _UserAvatar({required this.uid, required this.size});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (_, snap) {
        final url = (snap.data?.data() as Map<String, dynamic>?)?['photoUrl'] as String? ?? '';
        return _UserAvatarFromUrl(photoUrl: url, size: size);
      },
    );
  }
}

class _UserAvatarFromUrl extends StatelessWidget {
  final String photoUrl;
  final double size;
  const _UserAvatarFromUrl({required this.photoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          color: Color(0xffcce3f5), shape: BoxShape.circle),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person_outline,
                    color: Colors.white, size: 18))
            : const Icon(Icons.person_outline,
                color: Colors.white, size: 18),
      ),
    );
  }
}
