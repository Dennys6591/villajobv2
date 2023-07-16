import 'package:flutter/material.dart';
import 'package:villajob/pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:villajob/pages/perfiltrabajador.dart';
import 'package:firebase_auth/firebase_auth.dart';

class adminScreen extends StatefulWidget {
  const adminScreen({super.key});

  @override
  State<adminScreen> createState() => _adminScreenState();
}

class _adminScreenState extends State<adminScreen> {
  late String adminId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    obtenerAdminId();
  }

  void obtenerAdminId() {
    String? adminEmail = FirebaseAuth.instance.currentUser!.email;

    FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: adminEmail)
        .get()
        .then((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        adminId = snapshot.docs[0].id;
      }
      setState(() {
        isLoading = false;
      });
    }).catchError((error) {
      print('Error al obtener admin: $error');
      setState(() {
        isLoading = false;
      });
    });

    print("Se obptuvo el id del admin");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, //Extiende el widget detras del appbar
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 204, 15, 15),
        elevation: 0,
        title: isLoading
            ? Text(
                'Cargando...', // Mostrar texto de carga mientras se obtiene el valor de trabajadorId
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(adminId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      'Cargando...', // Mostrar texto de carga mientras se obtiene la información del trabajador
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text(
                      'Error al cargar los datos',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    );
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final adminNombre = userData['nombre'];
                  final adminApellido = userData['apellido'];

                  return Text(
                    'Administrador: $adminNombre $adminApellido',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  );
                },
              ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: UserSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets
            .zero, // Ajusta el padding a cero para eliminar el espacio adicional
        alignment: Alignment.centerLeft, // Alinea el contenido a la izquierda
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment
              .start, // Alinea los elementos del Column a la izquierda
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 60),
              child: Text(
                'Listado de solicitudes de eliminación de cuenta',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('solicitud_eliminar_cuenta')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error al cargar las solicitudes');
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text('No hay solicitudes');
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final solicitud = snapshot.data!.docs[index];
                      final email = solicitud['email'];
                      final fecha = solicitud['fecha'].toDate();
                      final usuarioId = solicitud['usuarioId'];
                      final nombre = solicitud['nombre'];
                      final apellido = solicitud['apellido'];
                      final id = solicitud['id'];

                      return Container(
                        child: ListTile(
                          title: Text('Nombre: $nombre - Apellido: $apellido'),
                          subtitle: Text(
                              'Fecha: $fecha - ID authentication: $usuarioId - ID usuario: $id - email: $email '),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  // Acción para eliminar la solicitud
                                  eliminarUsuarioCompleto(solicitud['email'],
                                      usuarioId, solicitud.id, solicitud['id']);
                                  //eliminarUsuarioPorCorreo(solicitud['email']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void eliminarUsuarioCompleto(
      String correo, String userId, String solicitudId, String id) async {
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
            .doc(solicitudId)
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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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




/*
 void eliminarUsuarioPorId(String userId) {
    FirebaseAuth.instance.currentUser!.delete().then((_) {
      print('Usuario eliminado correctamente');
      // Realizar otras acciones después de eliminar el usuario si es necesario
    }).catchError((error) {
      print('Error al eliminar el usuario: $error');
      // Mostrar mensaje de error si es necesario
    });
  }*/