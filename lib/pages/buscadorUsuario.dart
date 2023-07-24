import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(
      child: Text('Resultados de búsqueda para: $query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.isEmpty
          ? FirebaseFirestore.instance.collection('usuarios').snapshots()
          : FirebaseFirestore.instance
              .collection('usuarios')
              .where('nombre', isEqualTo: query)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error al cargar los usuarios');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No se encontraron usuarios');
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final apellido = userData['apellido'];
            final cedula = userData['cedula'];
            final email = userData['email'];
            final id = userData['id'];
            final nombre = userData['nombre'];
            final opcion = userData['opcion'];
            final telefono = userData['telefono'];

            return ListTile(
              title: Text('$nombre $apellido'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cédula: $cedula'),
                  Text('Email: $email'),
                  Text('ID: $id'),
                  Text('Opción: $opcion'),
                  Text('Teléfono: $telefono'),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Eliminar usuario'),
                        content: Text(
                            '¿Estás seguro de que deseas eliminar este usuario?'),
                        actions: [
                          TextButton(
                            child: Text('Cancelar'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text('Eliminar'),
                            onPressed: () {
                              eliminarUsuarioCompleto(email, id, id);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void eliminarUsuarioCompleto(String correo, String userId, String id) async {
    try {
      // Eliminar el usuario de Firebase Authentication
      User? user = await FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == userId) {
        await user.delete();
        print('Usuario eliminado de Firebase Authentication exitosamente.');
      } else {
        print(
            'No se encontró un usuario con el ID especificado en Firebase Authentication.');
      }

      // Consultar el usuario por correo electrónico
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: correo)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final usuarioId = querySnapshot.docs[0].id;

        // Eliminar las publicaciones del empleador
        QuerySnapshot publicacionesEmpleadorSnapshot = await FirebaseFirestore
            .instance
            .collection('publicaciones')
            .where('empleadorId', isEqualTo: id)
            .get();

        for (QueryDocumentSnapshot doc in publicacionesEmpleadorSnapshot.docs) {
          await doc.reference.delete();
        }

        // Eliminar los contratos del trabajador
        QuerySnapshot contratosTrabajadorSnapshot = await FirebaseFirestore
            .instance
            .collection('contratos')
            .where('trabajadorId', isEqualTo: id)
            .get();

        for (QueryDocumentSnapshot doc in contratosTrabajadorSnapshot.docs) {
          await doc.reference.delete();
        }

        // Eliminar el usuario de Firestore
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuarioId)
            .delete();

        // Eliminar la solicitud de Firestore
        await FirebaseFirestore.instance
            .collection('solicitud_eliminar_cuenta')
            .doc(id)
            .delete();

        print('Usuario eliminado exitosamente.');
      } else {
        print(
            'No se encontró ningún usuario con el correo electrónico especificado.');
      }

      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error al eliminar el usuario: $e');
    }
  }
}
