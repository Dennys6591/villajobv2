import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:villajob/pages/empleador.dart';
import 'package:villajob/pages/trabajadores.dart';
import 'package:villajob/widgets_reutilizables/reutilizables.dart';
import 'login.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({Key? key}) : super(key: key);

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _nombreTextController = TextEditingController();
  TextEditingController _apellidoTextController = TextEditingController();
  TextEditingController _telefonoTextController = TextEditingController();
  TextEditingController _cedulaTextController = TextEditingController();
  TextEditingController _tipoTextController = TextEditingController();
  String _selectedOption = 'Trabajador';
  String id = '0';
  String idE = '0';
  RegExp _nameRegExp = RegExp(r'^[a-zA-Z]+$');
  RegExp _cedulaRegExp = RegExp(r'^\d{10}$');
  RegExp _phoneRegExp = RegExp(r'^09\d{8}$');

  bool _validateFields() {
    String nombre = _nombreTextController.text;
    String apellido = _apellidoTextController.text;
    String cedula = _cedulaTextController.text;
    String telefono = _telefonoTextController.text;

    if (nombre.isEmpty || !_nameRegExp.hasMatch(nombre)) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Ingrese un nombre válido sin caracteres especiales.'),
          actions: [
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
      return false;
    }

    if (apellido.isEmpty || !_nameRegExp.hasMatch(apellido)) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Ingrese un apellido válido sin caracteres especiales.'),
          actions: [
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
      return false;
    }

    if (!_cedulaRegExp.hasMatch(cedula)) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Ingrese una cédula válida (10 dígitos).'),
          actions: [
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
      return false;
    }

    if (!_phoneRegExp.hasMatch(telefono)) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Ingrese un número de teléfono válido (10 dígitos).'),
          actions: [
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  void _createUserAndSaveData() async {
    if (!_validateFields()) {
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailTextController.text,
        password: _passwordTextController.text,
      );

      print("Usuario Creado");

      if (_selectedOption == 'Trabajador') {
        id = 'T${DateTime.now().microsecondsSinceEpoch.toString().padLeft(6, '0')}';
      } else if (_selectedOption == 'Empleador') {
        id = 'E${DateTime.now().microsecondsSinceEpoch.toString().padLeft(6, '0')}';
      } else if (_selectedOption == 'Ambos') {
        id = 'T${DateTime.now().microsecondsSinceEpoch.toString().padLeft(6, '0')}';
        idE = 'E${DateTime.now().microsecondsSinceEpoch.toString().padLeft(6, '0')}';
      
      await FirebaseFirestore.instance.collection('usuarios').doc(idE).set({
        'nombre': _nombreTextController.text,
        'apellido': _apellidoTextController.text,
        'email': _emailTextController.text,
        'cedula': _cedulaTextController.text,
        'telefono': _telefonoTextController.text,
        'opcion': _selectedOption,
        'id': idE,
      });
      }

      await FirebaseFirestore.instance.collection('usuarios').doc(id).set({
        'nombre': _nombreTextController.text,
        'apellido': _apellidoTextController.text,
        'email': _emailTextController.text,
        'cedula': _cedulaTextController.text,
        'telefono': _telefonoTextController.text,
        'opcion': _selectedOption,
        'id': id,
      });

      print("Datos del usuario guardados en Firestore");

      final storage = firebase_storage.FirebaseStorage.instance;
      final folderRef = storage.ref().child(id).child("$id");
      final emptyList = <int>[];
      final data = Uint8List.fromList(emptyList);
      await folderRef.putData(data);

      print('Carpeta creada en Firebase Storage: $id');

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreem()),
      );
    } catch (error, stackTrace) {
      print("Error ${error.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "REGISTRO",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
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
              MediaQuery.of(context).size.height * 0.05,
              20,
              0,
            ),
            child: Column(
              children: <Widget>[
                LogoWidget("assets/images/logo.png"),
                const SizedBox(height: 0.5),
                reusableTextFiell(
                  "Ingrese Nombre",
                  Icons.person_outline,
                  false,
                  _nombreTextController,
                ),
                const SizedBox(height: 20),
                reusableTextFiell(
                  "Ingrese Apellido",
                  Icons.person_outline,
                  false,
                  _apellidoTextController,
                ),
                const SizedBox(height: 20),
                reusableTextFiell(
                  "Ingrese Correo",
                  Icons.person_outline,
                  false,
                  _emailTextController,
                ),
                const SizedBox(height: 20),
                reusableTextFiell(
                  "Ingrese Contraseña",
                  Icons.lock_outline,
                  true,
                  _passwordTextController,
                ),
                const SizedBox(height: 20),
                reusableTextFiell(
                  "Ingrese Cédula",
                  Icons.person_outline,
                  false,
                  _cedulaTextController,
                ),
                const SizedBox(height: 20),
                reusableTextFiell(
                  "Ingrese Teléfono",
                  Icons.phone,
                  false,
                  _telefonoTextController,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 60,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedOption,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                        underline: Container(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedOption = newValue!;
                          });
                        },
                        items: <String>['Trabajador', 'Empleador', 'Ambos']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _createUserAndSaveData,
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        onPrimary: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Registrarse",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("¿Ya tienes una cuenta?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreem()),
                        );
                      },
                      child: const Text(
                        "Inicia sesión",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
