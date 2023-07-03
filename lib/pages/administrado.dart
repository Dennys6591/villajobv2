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
      ),
      body: Stack(
        children: [
          // Contenido de la página
          Column(
            children: [
              // Otros widgets que desees mostrar antes del listado
              Text(
                'Listado de solicitudes de eliminación de cuenta',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

                        return ListTile(
                          title: Text('Email: $email'),
                          subtitle:
                              Text('Fecha: $fecha - Usuario ID: $usuarioId'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  // Acción para eliminar la solicitud
                                  eliminarUsuarioCompleto(solicitud['email'],
                                      usuarioId, solicitud.id);
                                  //eliminarUsuarioPorCorreo(solicitud['email']);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void eliminarUsuarioCompleto(
      String correo, String userId, String solicitudId) async {
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
}
