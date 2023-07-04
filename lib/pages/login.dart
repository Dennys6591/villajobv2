import 'package:flutter/material.dart';
import 'package:villajob/pages/empleador.dart';
import 'package:villajob/pages/registro.dart';
import 'package:villajob/pages/trabajadores.dart';

import '../widgets_reutilizables/reutilizables.dart';
import 'administrado.dart';
import 'package:villajob/logica_negocio/negocio.dart';

class LoginScreem extends StatefulWidget {
  const LoginScreem({Key? key}) : super(key: key);

  @override
  State<LoginScreem> createState() => _LoginScreemState();
}

class _LoginScreemState extends State<LoginScreem> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  bool _isLoading = true; // Variable para controlar el estado de carga

 LoginNegocio _negocio = LoginNegocio();

  mostrarDialogo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Elija un rol'),
          content: Container(
            height: 250,
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => TrabajadoresScreen()),
                        ((route) => false),
                      );
                    },
                    child: Text('Trabajador'),
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  height: 100,
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => EmpleadoresScreen()),
                        ((route) => false),
                      );
                    },
                    child: Text('Empleador'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 47, 152, 233),
              Color.fromRGBO(236, 163, 249, 1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).size.height * 0.2,
              20,
              0,
            ),
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
                  _emailTextController,
                ),
                const SizedBox(
                  height: 30,
                ),
                reusableTextFiell(
                  "Contraseña",
                  Icons.lock_outline,
                  true,
                  _passwordTextController,
                ),
                const SizedBox(
                  height: 30,
                ),
                loginButton(context, _isLoading, _signInWithEmailAndPassword),
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

      final usuario = await _negocio.signInWithEmailAndPassword(
        _emailTextController.text,
        _passwordTextController.text,
      );

      Navigator.pop(context);

      if (usuario != null) {
        String? userType = usuario['userType'];

        if (userType == 'Trabajador') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TrabajadoresScreen()),
          );
        } else if (userType == 'Empleador') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EmpleadoresScreen()),
          );
        } else if (userType == 'Ambos') {
          mostrarDialogo();
        } else if (userType == 'admin') {
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
        ),
      ],
    );
  }
}
