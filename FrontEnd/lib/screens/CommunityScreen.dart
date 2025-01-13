import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> posts = [];
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await _supabase
          .from('posts')
          .select('*, comments(*)')
          .order('created_at', ascending: false);

      setState(() {
        posts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $error')),
      );
    }
  }

  Future<void> _addNewPost(String title, String description) async {
    try {
      final response = await _supabase
          .from('posts')
          .insert({
        'title': title,
        'description': description,
        'author': _supabase.auth.currentUser?.email ?? 'Anonymous',
        'likes': 0,
      })
          .select();

      if (response != null && response.isNotEmpty) {
        setState(() {
          posts.insert(0, response[0]);
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $error')),
      );
    }
  }

  Future<void> _addComment(int postId, String commentText) async {
    try {
      await _supabase.from('comments').insert({
        'post_id': postId,
        'comment_text': commentText,
        'author': _supabase.auth.currentUser?.email ?? 'Anonymous',
      });
      _fetchPosts();
      _commentController.clear();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $error')),
      );
    }
  }

  Future<void> _likePost(int postId, int currentLikes) async {
    try {
      final userEmail = _supabase.auth.currentUser?.email ?? 'Anonymous';

      final likeCheckResponse = await _supabase
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_email', userEmail)
          .maybeSingle();

      if (likeCheckResponse != null) {
        setState(() {
          final index = posts.indexWhere((post) => post['id'] == postId);
          if (index != -1) {
            posts[index]['hasLiked'] = true;
          }
        });
        return;
      }

      final updateResponse = await _supabase
          .from('posts')
          .update({'likes': currentLikes + 1})
          .eq('id', postId)
          .select();

      if (updateResponse != null && updateResponse.isNotEmpty) {
        await _supabase.from('likes').insert({
          'post_id': postId,
          'user_email': userEmail,
        });

        setState(() {
          final index = posts.indexWhere((post) => post['id'] == postId);
          if (index != -1) {
            posts[index]['likes'] = currentLikes + 1;
            posts[index]['hasLiked'] = true;
          }
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking post: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['title'],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(post['description'], style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.thumb_up,
                          color: post['hasLiked'] == true ? Colors.blue : null,
                        ),
                        onPressed: () => _likePost(post['id'], post['likes'] ?? 0),
                      ),
                      Text('${post['likes']} Likes', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const Divider(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...List<Widget>.from(
                        (post['comments'] ?? []).map(
                              (comment) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(comment['author'] ?? 'Anonymous'),
                            subtitle: Text(comment['comment_text']),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _addComment(post['id'], value);
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () {
                                if (_commentController.text.isNotEmpty) {
                                  _addComment(post['id'], _commentController.text);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPostDialog(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPostDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                if (title.isNotEmpty && description.isNotEmpty) {
                  _addNewPost(title, description);
                  Navigator.pop(context);
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }
}
