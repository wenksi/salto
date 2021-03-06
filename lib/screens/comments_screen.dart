import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salto/components/add_comment.dart';
import 'package:salto/components/circle_avatar_button.dart';
import 'package:salto/components/timestamp.dart';
import 'package:salto/models/comment.dart';
import 'package:salto/models/http_exception.dart';
import 'package:salto/models/user.dart';
import 'package:salto/providers/auth.dart';
import 'package:salto/providers/comments.dart';
import 'package:salto/providers/users.dart';
import 'package:salto/screens/splash_screen.dart';

class CommentsScreen extends StatelessWidget {
  static const route = '/comments';
  List<Comment> _comments = [];
  String _postId;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context).settings.arguments as dynamic;
    if (!Provider.of<Auth>(context).isAuth) {
      Navigator.of(context).pop();
      return SplashScreen();
    }
    this._postId = args['postId'];
    final User postUser = args['postUser'];
    final User signedInUser = args['signedInUser'];
    return Scaffold(
        appBar: AppBar(
          title: Text('@${postUser.userName}'),
          actions: <Widget>[
            CircleAvatarButton(postUser, Theme.of(context).primaryColor)
          ],
        ),
        body: FutureBuilder(
            future: _getCommentsFuture(context),
            builder: (ctx, authResultSnapshot) {
              if (authResultSnapshot.connectionState == ConnectionState.done) {
                _comments = Provider.of<Comments>(context).items;
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: this
                              ._comments
                              .map(
                                  (Comment c) => _commentRowBuilder(context, c))
                              .toList(),
                        ),
                        AddComment(
                          userId: signedInUser.id,
                          postId: _postId,
                          hasLine: true,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }));
  }

  Widget _commentRowBuilder(BuildContext ctx, final Comment comment) {
    final user = Provider.of<Users>(ctx, listen: false).findById(comment.userId);
    if (user == null) return SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: _comments[_comments.length - 1].id == comment.id
                ? BorderSide.none
                : BorderSide(color: Theme.of(ctx).primaryColor, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            CircleAvatarButton(user, Colors.white),
            Text(
              '@${user.userName}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 5),
            Text(comment.text),
            Spacer(),
            Timestamp(comment.timestamp),
          ],
        ),
      ),
    );
  }

  Future<void> _getCommentsFuture(BuildContext ctx) async {
    try {
      return await Provider.of<Comments>(ctx).getComments(_postId);
    } on HttpException catch(error) {
      HttpException.showErrorDialog(error.message, ctx);
      return null;
    }
  }
}
