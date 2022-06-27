import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({Key? key}) : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void dispose(){
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15,0,15,0),
        child: Column(
          children: [
            SizedBox(height: 40),
            TextField(
              controller: emailController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 4),
            TextField(
              controller: passwordController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
                onPressed: signIn,
                icon: Icon(Icons.lock_open, size: 32),
                label: Text('Sign In'),
            ),

          ],
        ),
      ),
    );
  }

  Future signIn() async{
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
    );

  }



}