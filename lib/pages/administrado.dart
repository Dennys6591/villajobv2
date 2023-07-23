import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'buscadorUsuario.dart';

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
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 0, top: 60),
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

                      //

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
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Eliminar usuario'),
                                        content: Text(
                                            '¿Estás seguro que desea eliminar al Usuario por completo?'),
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
                                              eliminarUsuarioCompleto(email,
                                                  usuarioId, solicitud.id, id);
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
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
            Padding(
              padding: const EdgeInsets.only(left: 0, top: 100),
              child: Text(
                'Listado de publicaciones',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('publicaciones')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error al cargar las publicaciones');
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text('No hay publicaciones');
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final publicacion = snapshot.data!.docs[index];
                      final bloqueada = publicacion['bloqueada'];
                      final descripcion = publicacion['descripcion'];
                      final empleadorId = publicacion['empleadorId'];
                      final precio = publicacion['precio'];
                      final id = publicacion.id;

                      //eliminarPublicacion(id, empleadorId);

                      return Container(
                        child: ListTile(
                          title: Text(
                              'Descripción: $descripcion - Precio: $precio'),
                          subtitle: Text(
                              'Empleador ID: $empleadorId - Bloqueada: $bloqueada'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Eliminar publicacion'),
                                        content: Text(
                                            '¿Estás seguro que desea eliminar publicacion?'),
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
                                              eliminarPublicacion(
                                                  id, empleadorId);
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
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
      // Consultar los usuarios por correo electrónico
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: correo)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (QueryDocumentSnapshot usuarioDoc in querySnapshot.docs) {
          final usuarioId = usuarioDoc.id;

          // Eliminar las publicaciones del empleador
          QuerySnapshot publicacionesEmpleadorSnapshot = await FirebaseFirestore
              .instance
              .collection('publicaciones')
              .where('empleadorId', isEqualTo: usuarioId)
              .get();

          for (QueryDocumentSnapshot doc
              in publicacionesEmpleadorSnapshot.docs) {
            await doc.reference.delete();
          }

          // Eliminar los contratos del trabajador
          QuerySnapshot contratosTrabajadorSnapshot = await FirebaseFirestore
              .instance
              .collection('contratos')
              .where('trabajadorId', isEqualTo: usuarioId)
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
        }
      } else {
        print(
            'No se encontró ningún usuario con el correo electrónico especificado.');
      }
    } catch (e) {
      print('Error al eliminar el usuario: $e');
    }
  }

  void eliminarPublicacion(String id, String empleadorId) async {
    try {
      // Obtener la referencia de la publicación específica
      DocumentSnapshot publicacionSnapshot = await FirebaseFirestore.instance
          .collection('publicaciones')
          .doc(id)
          .get();

      if (publicacionSnapshot.exists) {
        // Guardar empleadorId y motivo en la colección "public_eliminadas"
        String empleadorId = publicacionSnapshot['empleadorId'];
        String descripcion = publicacionSnapshot['descripcion'];
        String motivo =
            'Se eliminó porque incumple con nuestras normas. Vuelva a publicar.';

        await FirebaseFirestore.instance.collection('public_eliminadas').add({
          'empleadorId': empleadorId,
          'motivo': motivo,
          'descripcion': descripcion,
        });

        // Eliminar la publicación de la colección "publicaciones"
        await publicacionSnapshot.reference.delete();

        print('Publicación eliminada exitosamente.');
      } else {
        print('No se encontró ninguna publicación con el ID especificado.');
      }

      // Eliminar los contratos del trabajador
      QuerySnapshot contratosTrabajadorSnapshot = await FirebaseFirestore
          .instance
          .collection('contratos')
          .where('empleadorId', isEqualTo: empleadorId)
          .get();

      for (QueryDocumentSnapshot doc in contratosTrabajadorSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error al eliminar la publicación: $e');
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
