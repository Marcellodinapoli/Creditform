import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // IMPORT FIRESTORE
import 'package:shared_preferences/shared_preferences.dart';
import 'courses_page.dart';
import 'main_scaffold_with_role.dart';
import 'course_details_page.dart'; // nuova pagina da creare
import '../widgets/page_wrapper.dart'; // import page_wrapper

class AuthPage extends StatefulWidget {  // <-- assicurati che la classe si chiami così
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _acceptedPrivacy = false;

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _error;

  Future<void> _submit() async {
    final auth = FirebaseAuth.instance;

    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin && !_acceptedPrivacy) {
      setState(() {
        _error = "Devi accettare la privacy per registrarti.";
      });
      return;
    }

    try {
      UserCredential userCredential;

      if (_isLogin) {
        userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _error = "Le password non coincidono.";
          });
          return;
        }

        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final uid = userCredential.user!.uid;
        final email = _emailController.text.trim();
        final role = email == "dinapoli.marcello@gmail.com" ? "admin" : "utente";

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CoursesPage(role: "utente"),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "CreditForm",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("www.credithistory.it"),
                  const SizedBox(height: 32),

                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Nome"),
                      validator: (val) => val == null || val.isEmpty ? "Campo obbligatorio" : null,
                    ),
                    TextFormField(
                      controller: _surnameController,
                      decoration: const InputDecoration(labelText: "Cognome"),
                      validator: (val) => val == null || val.isEmpty ? "Campo obbligatorio" : null,
                    ),
                  ],

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (val) => val != null && val.contains("@") ? null : "Email non valida",
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: (val) =>
                    val != null && val.length >= 6 ? null : "Minimo 6 caratteri",
                  ),

                  if (!_isLogin)
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(labelText: "Conferma Password"),
                      obscureText: true,
                      validator: (val) => val != _passwordController.text
                          ? "Le password non coincidono"
                          : null,
                    ),

                  const SizedBox(height: 16),

                  if (!_isLogin)
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedPrivacy,
                          onChanged: (val) {
                            setState(() {
                              _acceptedPrivacy = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            "Accetto l'informativa sulla privacy",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? "Accedi" : "Registrati"),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _error = null;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? "Non hai un account? Registrati"
                          : "Hai già un account? Accedi",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
