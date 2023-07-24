import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegistroPublicacionScreen extends StatefulWidget {
  const RegistroPublicacionScreen({Key? key}) : super(key: key);

  @override
  _RegistroPublicacionScreenState createState() =>
      _RegistroPublicacionScreenState();
}

class _RegistroPublicacionScreenState extends State<RegistroPublicacionScreen> {
  TextEditingController _descripcionController = TextEditingController();
  TextEditingController _precioController = TextEditingController();

  @override
  void dispose() {
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro de Publicación"),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _descripcionController,
              decoration: InputDecoration(labelText: "Descripción"),
            ),
            TextField(
              controller: _precioController,
              decoration: InputDecoration(labelText: "Precio"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registrarPublicacion,
              child: const Text("Registrar"),
            ),
          ],
        ),
      ),
    );
  }

  void _registrarPublicacion() {
    String descripcion = _descripcionController.text;
    String precio = _precioController.text;

    // Obtener el ID y correo del empleador actualmente autenticado
    String? empleadoEmail = FirebaseAuth.instance.currentUser!.email;

    FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: empleadoEmail)
        .get()
        .then((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        String empleadorId = snapshot.docs[0].id;
        String empleadorEmail = snapshot.docs[0].get('email');

        // Crear un nuevo documento de publicación en Firestore
        FirebaseFirestore.instance.collection('publicaciones').add({
          'descripcion': descripcion,
          'precio': precio,
          'empleadorId': empleadorId,
          'empleadorEmail': empleadorEmail,
          'bloqueada':
              false, // Agregar la variable 'bloqueada' con valor predeterminado false
        }).then((value) {
          // Registro exitoso
          print('Publicación registrada con éxito');
          // Volver al menú
          Navigator.pop(context);
        }).catchError((error) {
          // Error durante el registro
          print('Error al registrar la publicación: $error');
          // Puedes mostrar un mensaje de error o realizar alguna acción adicional en caso de error
        });
      } else {
        // No se encontró el empleador en la colección de usuarios
        print('Error: Empleador no encontrado');
      }
    }).catchError((error) {
      // Error al consultar la colección de usuarios
      print('Error al obtener el empleador: $error');
    });
  }
}
