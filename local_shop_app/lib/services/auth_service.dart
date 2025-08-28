import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_shop_app/models/app_user_model.dart';
import 'package:local_shop_app/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
    String? shopName,
    String? category,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        await _firestoreService.createUserData(
          result.user!.uid,
          email,
          role,
          shopName: shopName,
          category: category,
        );
      }
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        // Check if user already exists in Firestore, if not, create a default customer entry
        AppUser? appUser = await _firestoreService.getUser(result.user!.uid);
        if (appUser == null) {
          await _firestoreService.createUserData(
            result.user!.uid,
            result.user!.email ?? '',
            'customer', // Default role for new Google sign-ins
          );
        }
      }
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    AppUser? appUser = await _firestoreService.getUser(uid);
    return appUser?.role;
  }

  // Get AppUser from Firestore
  Future<AppUser?> getAppUser(String uid) async {
    return await _firestoreService.getUser(uid);
  }
}
