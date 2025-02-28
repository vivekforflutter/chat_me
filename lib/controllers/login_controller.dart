import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;


  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    checkUserLoginStatus();
  }

  Rxn<User> firebaseUser = Rxn<User>();


  /// Check if user is already logged in
  void checkUserLoginStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_auth.currentUser != null) {
        updateFcmToken(_auth.currentUser!.uid);
        Get.offAll(() => HomeScreen()); // Navigate after build phase
      } else {
        Get.offAll(() => LoginScreen()); //  Navigate after build phase
      }
    });
  }


  ///  Sign Up Method
  Future<void> signUp(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        String? fcmToken = await _firebaseMessaging.getToken();

        await _firestore.collection('users').doc(user.uid).set({
          "uid": user.uid,
          "name": name,
          "email": email,
          "fcmToken": fcmToken,
          "createdAt": DateTime.now(),
        });

        await _auth.currentUser?.reload();
        Get.offAll(() => HomeScreen());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Get.snackbar(
          "Signup Failed",
          "This email is already registered. Please log in.",
        );
      } else {
        Get.snackbar("Signup Failed", e.message ?? "An error occurred");
      }
    } catch (e) {
      Get.snackbar("Signup Failed", e.toString());
    }
  }

  ///  Login Method
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      await updateFcmToken(_auth.currentUser!.uid);

      Get.offAll(() => HomeScreen());
    } catch (e) {
      Get.snackbar("Login Failed", e.toString());
    }
  }

  /// Logout Method
  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAll(() => LoginScreen());
    } catch (e) {
      Get.snackbar("Logout Failed", "Something went wrong. Try again.");
    }
  }

  /// Update FCM Token Method
  Future<void> updateFcmToken(String userId) async {
    try {
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(userId).update({
          "fcmToken": fcmToken,
        });
      }
    } catch (e) {
      Get.snackbar("FCM Token Update Failed", e.toString());
    }
  }
}
