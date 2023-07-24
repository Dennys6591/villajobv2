import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import 'changePass.dart';

class EditarPerfilTrabajador extends StatefulWidget {
  const EditarPerfilTrabajador({Key? key}) : super(key: key);

  @override
  State<EditarPerfilTrabajador> createState() => _EditarPerfilTrabajadorState();
}

class _EditarPerfilTrabajadorState extends State<EditarPerfilTrabajador> {
  late String trabajadorId = '';
  String? urlFotoPerfil;
  File? _image;
  final picker = ImagePicker();
  String? nombre;
  String? apellido;
  String? telefono;
  String? cedula;
  String? correo;

  @override
  void initState() {
    super.initState();
    obtenerTrabajadorId();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    obtenerDatosTrabajador();
  }

  Future<void> obtenerTrabajadorId() async {
    String? trabajadorEmail = FirebaseAuth.instance.currentUser!.email;

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: trabajadorEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        trabajadorId = snapshot.docs[0].id;
      });
    } else {
      throw 'No se encontró el ID del trabajador';
    }
  }

  Future<void> obtenerDatosTrabajador() async {
    String? trabajadorEmail = FirebaseAuth.instance.currentUser!.email;
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: trabajadorEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final userData = snapshot.docs[0].data() as Map<String, dynamic>;
      setState(() {
        nombre = userData['nombre'] as String?;
        apellido = userData['apellido'] as String?;
        telefono = userData['telefono'] as String?;
        cedula = userData['cedula'] as String?;
        correo = userData['email'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil Trabajador"),
      ),
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 47, 152, 233),
                  Color.fromRGBO(236, 163, 249, 1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: _image != null ? null : Colors.grey,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(80),
                    child: _image != null
                        ? Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          )
                        : urlFotoPerfil != null
                            ? Image.network(
                                urlFotoPerfil!,
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    seleccionarImagen();
                  },
                  child: const Text('Cambiar imagen'),
                ),
                SizedBox(height: 40),
                Text(
                  'Nombre: $nombre',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Apellido: $apellido',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Teléfono: $telefono',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40.0),
                ElevatedButton(
                  onPressed: () {
                    mostrarDialogoEditarPerfil();
                  },
                  child: const Text('Editar Perfil'),
                ),
                SizedBox(height: 40.0,),
                 ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChangePasswordForm()),
                      ((route) => false),
                    );
                  },
                  child: const Text('Cambiar Contraseña'),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> seleccionarImagen() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        subirImagenAFirebase();
      } else {
        print('No se seleccionó ninguna imagen.');
      }
    });
  }

  Future<void> subirImagenAFirebase() async {
    if (_image == null) {
      print('No se seleccionó ninguna imagen.');
      return;
    }

    try {
      final referenciaFirebaseStorage =
          FirebaseStorage.instance.ref().child('$trabajadorId/foto_perfil.jpg');
      await referenciaFirebaseStorage.putFile(_image!);
      final urlImagen = await referenciaFirebaseStorage.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(trabajadorId)
          .update({
        'urlFotoPerfil': urlImagen,
      });

      setState(() {
        //_image = null;
      });
    } catch (error) {
      print('Error al subir la imagen: $error');
    }
  }

  void mostrarDialogoEditarPerfil() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: nombre,
                onChanged: (value) {
                  nombre = value;
                },
                decoration: InputDecoration(
                  labelText: 'Nombre',
                ),
              ),
              TextFormField(
                initialValue: apellido,
                onChanged: (value) {
                  apellido = value;
                },
                decoration: InputDecoration(
                  labelText: 'Apellido',
                ),
              ),
              TextFormField(
                initialValue: telefono,
                onChanged: (value) {
                  telefono = value;
                },
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                guardarCambios();
                Navigator.of(context).pop();
              },
              child: Text('Guardar cambios'),
            ),
          ],
        );
      },
    );
  }

  void guardarCambios() {
    FirebaseFirestore.instance.collection('usuarios').doc(trabajadorId).update({
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
    });

    setState(() {});
  }
}
