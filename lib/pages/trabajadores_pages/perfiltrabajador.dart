import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../changePass.dart';
//import 'package:editarPerfil.dart';

class PerfilTrabajador extends StatefulWidget {
  const PerfilTrabajador({Key? key, required String trabajadorId})
      : super(key: key);

  @override
  State<PerfilTrabajador> createState() => _PerfilTrabajadorState();
}

class _PerfilTrabajadorState extends State<PerfilTrabajador> {
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
    obtenerFotoPerfil();
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

///// obetener datos del trabajador
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

  ///obetener foto de perfil del trabajador
  Future<void> obtenerFotoPerfil() async {
    final referenciaFirebaseStorage =
        FirebaseStorage.instance.ref().child('$trabajadorId/foto_perfil.jpg');

    try {
      final metadata = await referenciaFirebaseStorage.getMetadata();

      if (metadata != null) {
        final downloadUrl = await referenciaFirebaseStorage.getDownloadURL();

        final response = await http.get(Uri.parse(downloadUrl));
        final bytes = response.bodyBytes;

        final file = File('${trabajadorId}_perfil.jpg');
        await file.writeAsBytes(bytes);

        setState(() {
          _image = file;
        });
      }
    } catch (error) {
      print('Error al obtener la foto de perfil: $error');
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(trabajadorId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final urlFotoPerfil = data['urlFotoPerfil'] as String?;
      setState(() {
        this.urlFotoPerfil = urlFotoPerfil;
        print('URL foto de perfil: $urlFotoPerfil');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
          MaterialButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            disabledColor: Colors.grey,
            elevation: 0,
            color: Colors.deepPurple,
            onPressed: () {
              seleccionarImagen();
            },
            child: const Text(
              'Seleccionar imagen',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),

          const SizedBox(height: 40), // Espacio vertical

          Text(
            'Nombre: $nombre',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          Text(
            'Apellido: $apellido',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          Text(
            'Teléfono: $telefono',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          Text(
            'Cédula: $cedula',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          Text(
            'Correo electrónico: $correo',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 40.0,
          ),
          MaterialButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            disabledColor: Colors.grey,
            elevation: 0,
            color: Colors.deepPurple,
            onPressed: () {
              mostrarDialogoEditarPerfil();
            },
            child: const Text(
              'Editar Perfil',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          MaterialButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            disabledColor: Colors.grey,
            elevation: 0,
            color: Colors.deepPurple,
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChangePasswordForm()));
            },
            child: const Text(
              'Cambiar contraseña',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  void mostrarDialogoEditarPerfil() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: nombre,
                onChanged: (value) {
                  nombre = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                ),
              ),
              TextFormField(
                initialValue: apellido,
                onChanged: (value) {
                  apellido = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                ),
              ),
              TextFormField(
                initialValue: telefono,
                onChanged: (value) {
                  telefono = value;
                },
                decoration: const InputDecoration(
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
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                guardarCambios();
                Navigator.of(context).pop();
              },
              child: const Text('Guardar cambios'),
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
}
