import 'package:flutter/material.dart';
import 'package:villajob/pages/empleador.dart';
import 'package:villajob/pages/registro.dart';
import 'package:villajob/pages/trabajadores.dart';
import 'package:villajob/widgets_reutilizables/auth_background.dart';

import '../ui/input_decorations.dart';
import '../widgets_reutilizables/card_container.dart';
import 'RecuperarPassword.dart';
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
  bool _isLoading = false; // Variable para controlar el estado de carga
  final loginForm = GlobalKey<FormState>();

  LoginNegocio _negocio = LoginNegocio();

  mostrarDialogo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Elija un rol'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          content: Container(
            height: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 80,
                  width: 150,
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    disabledColor: Colors.grey,
                    elevation: 0,
                    color: Colors.deepPurple,
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TrabajadoresScreen()),
                        ((route) => false),
                      );
                    },
                    child: const Text(
                      'Trabajador',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  height: 80,
                  width: 150,
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    disabledColor: Colors.grey,
                    elevation: 0,
                    color: Colors.deepPurple,
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EmpleadoresScreen()),
                        ((route) => false),
                      );
                    },
                    child: const Text(
                      'Empleador',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
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
      body: AuthBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.22,
              ),
              CardContainer(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      child: const Icon(
                        Icons.person_pin,
                        color: Colors.deepPurple,
                        size: 100,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Login',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      child: Form(
                        key: loginForm,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          children: [
                            TextFormField(
                              autocorrect: false,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecorations.authInputDecoration(
                                  hintText: 'john.doe@gmail.com',
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icons.alternate_email_rounded),
                              controller: _emailTextController,
                              validator: (value) {
                                String pattern =
                                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                                RegExp regExp = RegExp(pattern);

                                return regExp.hasMatch(value ?? '')
                                    ? null
                                    : 'El valor ingresado no luce como un correo';
                              },
                            ),
                            const SizedBox(height: 30),
                            TextFormField(
                              autocorrect: false,
                              obscureText: true,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecorations.authInputDecoration(
                                  hintText: '*****',
                                  labelText: 'Contraseña',
                                  prefixIcon: Icons.lock_outline),
                              controller: _passwordTextController,
                              validator: (value) {
                                return (value != null && value.length >= 6)
                                    ? null
                                    : 'La contraseña debe de ser de 6 caracteres';
                              },
                            ),
                            const SizedBox(height: 30),
                            MaterialButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              disabledColor: Colors.grey,
                              elevation: 0,
                              color: Colors.deepPurple,
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      FocusScope.of(context).unfocus();

                                      if (!loginForm.currentState!.validate()) {
                                        return;
                                      }

                                      setState(() {
                                        _isLoading = true;
                                      });

                                      await _signInWithEmailAndPassword();

                                      setState(() {
                                        _isLoading = false;
                                      });
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 80, vertical: 15),
                                child: Text(
                                  _isLoading ? 'Espere' : 'Ingresar',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Recuperar_contrasena(),
              const SizedBox(
                height: 10,
              ),
              Opcion_de_registro(),
              const SizedBox(
                height: 20,
              ),
            ],
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
          return const AlertDialog(
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
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const TrabajadoresScreen()),
              (route) => false);
        } else if (userType == 'Empleador') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const EmpleadoresScreen()),
            (route) => false,
          );
        } else if (userType == 'Ambos') {
          mostrarDialogo();
        } else if (userType == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const adminScreen()),
          );
        }
      } else {
        showErrorMessage(
            'El usuario no existe o no tiene asignado un tipo de usuario');
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
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Row Opcion_de_registro() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("¿No tienes cuenta? ",
            style: TextStyle(color: Colors.black54)),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegistroScreen()),
            );
          },
          child: const Text(
            "REGISTRARSE",
            style: TextStyle(
                color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Row Recuperar_contrasena() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("¿Olvidaste tu contraseña?",
            style: TextStyle(color: Colors.black54)),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const RecuperarPasswordScreen()),
            );
          },
          child: const Text(
            " RESTABLECER",
            style: TextStyle(
                color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
