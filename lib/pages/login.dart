import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:villajob/pages/empleador.dart';
import 'package:villajob/pages/registro.dart';
import 'package:villajob/pages/trabajadores.dart';

import '../widgets_reutilizables/reutilizables.dart';
import 'administrado.dart';

class LoginScreem extends StatefulWidget {
  const LoginScreem({Key? key}) : super(key: key);

  @override
  State<LoginScreem> createState() => _LoginScreemState();
}

class _LoginScreemState extends State<LoginScreem> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  bool _isLoading = true; // Variable para controlar el estado de carga

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
          Color.fromARGB(255, 47, 152, 233),
          Color.fromRGBO(236, 163, 249, 1)
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              children: [
                LogoWidget("assets/images/logo.png"),
                const SizedBox(
                  height: 30,
                ),
                reusableTextFiell(
                    "Correo",
                    Icons.person_outline,
                    false,
                    _emailTextController),
                const SizedBox(
                  height: 30,
                ),
                reusableTextFiell("Contraseña", Icons.lock_outline, true,
                    _passwordTextController),
                const SizedBox(
                  height: 30,
                ),
                loginButton(context, _isLoading, () {
                  _signInWithEmailAndPassword();
                }),
                Opcion_de_registro(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.0),
                Text('Iniciando sesión...'),
              ],
            ),
          );
        },
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailTextController.text,
              password: _passwordTextController.text);

      String? userEmail = userCredential.user!.email;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: userEmail)
          .get();

      Navigator.pop(context);

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs[0].data() as Map<String, dynamic>;
        String? userType = userData['opcion'];

        if (userType == 'Trabajador') {
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TrabajadoresScreen()),
          );
        } else if (userType == 'Empleador') {
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EmpleadoresScreen()),
          );
        // ignore: unrelated_type_equality_checks
        } else if (userType == 'admin') {
           // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => adminScreen()),
          );
        }
      } else {
        showErrorMessage('El usuario no existe o no tiene asignado un tipo de usuario');
      }
    } catch (error) {
      Navigator.pop(context);
      showErrorMessage('Error de inicio de sesión: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showErrorMessage(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Row Opcion_de_registro() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("No tengo cuenta", style: TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegistroScreen()),
            );
          },
          child: const Text(
            "? REGISTRAR",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}
