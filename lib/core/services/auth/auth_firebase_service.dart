import 'dart:async';
import 'dart:math';

import 'package:chat/core/models/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'auth_service.dart';

class AuthFirebaseService implements AuthService {
  static ChatUser? _currentUser;
  static final _userStream = Stream<ChatUser?>.multi(
    (controller) async {
      await Firebase.initializeApp();
      final authChanges = FirebaseAuth.instance.authStateChanges();
      await for (final user in authChanges) {
        _currentUser = user == null ? null : _toChatUser(user);
        controller.add(_currentUser);
      }
    },
  );

  @override
  ChatUser? get currentUser => _currentUser;

  @override
  Stream<ChatUser?> get userChanges => _userStream;

  @override
  Future<void> signup(
    String name,
    String email,
    String password,
    File? image,
  ) async {
    final signup = await Firebase.initializeApp(
      name: 'userSignup',
      options: Firebase.app().options,
    );

    final auth = FirebaseAuth.instanceFor(app: signup);

    UserCredential credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      final imageName = '${credential.user!.uid}.jpg';
      final imageUrl = await _uploadUserImage(image, imageName);

      await credential.user?.updateDisplayName(name);
      await credential.user?.updatePhotoURL(imageUrl);

      await login(email, password);

      _currentUser = _toChatUser(credential.user!, name, imageUrl);
      await _saveChatUser(_currentUser!);
    }

    await signup.delete();
  }

  @override
  Future<void> login(String email, String password) async =>
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

  @override
  Future<void> logout() async => FirebaseAuth.instance.signOut();

  static void _updateUser(ChatUser? user) {}

  Future<String?> _uploadUserImage(File? image, String imageName) async {
    if (image == null) return null;
    final storage = FirebaseStorage.instance;
    final imageRef = storage.ref().child('user_images').child(imageName);
    await imageRef.putFile(image).whenComplete(() {});
    return await imageRef.getDownloadURL();
  }

  Future<void> _saveChatUser(ChatUser user) {
    final store = FirebaseFirestore.instance;
    final docRef = store.collection('users').doc(user.id);
    return docRef.set({
      'name': user.name,
      'email': user.email,
      'imageURL': user.imageUrl,
    });
  }

  static ChatUser _toChatUser(User user, [String? name, String? imageUrl]) =>
      ChatUser(
        id: user.uid,
        name: name ?? user.displayName ?? user.email!.split('@')[0],
        email: user.email!,
        imageUrl: imageUrl ?? user.photoURL ?? 'assets/images/avatar.png',
      );
}
