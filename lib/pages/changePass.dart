import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:villajob/pages/login.dart';
import 'package:villajob/pages/perfiltrabajador.dart';

import '../widgets_reutilizables/reutilizables.dart';

class ChangePasswordForm extends StatefulWidget {
  @override
  _ChangePasswordFormState createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      String newPassword = _newPasswordController.text.trim();

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePassword(newPassword);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Contraseña actualizada exitosamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo encontrar al usuario actual')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar la contraseña: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text("Cambiar contraseña"),
      ),
        body: Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 47, 152, 233),
            Color.fromRGBO(163, 140, 220, 0.757),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Form(

        key: _formKey,
        child: Center(
          child: Column(
            children: [
              reusableTextFiell(
                "Nueva Contraseña",
                Icons.password,
                false,
                _newPasswordController,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _changePassword,
                child: Text('Cambiar Contraseña'),
              ),
              SizedBox(
                height: 40,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreem()));
                },
                child: Text('Salir'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
