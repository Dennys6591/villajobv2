import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:villajob/pages/empleador_pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:villajob/pages/registroPubli.dart';
import 'package:villajob/pages/trabajadores_pages/salir_page.dart';

import 'contratos.dart';

class EmpleadoresScreen extends StatefulWidget {
  const EmpleadoresScreen({Key? key});

  @override
  State<EmpleadoresScreen> createState() => _EmpleadoresScreenState();
}

class _EmpleadoresScreenState extends State<EmpleadoresScreen> {
  late String empleadorId;
  late bool isLoading = true;
  late Stream<QuerySnapshot<Map<String, dynamic>>> trabajadoresStream;
  String searchQuery = '';
  late String trabajadorId;
  double promedioCalificaciones = 0.0;
  var _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    obtenerEmpleadorId();
    obtenerTrabajadorId();
  }

  void obtenerEmpleadorId() async {
    // Obtener el ID del empleador actualmente autenticado
    String? empleadorEmail = FirebaseAuth.instance.currentUser!.email;

    // Obtener el documento del empleador desde la colección de usuarios
    FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: empleadorEmail)
        .get()
        .then((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        empleadorId = snapshot.docs[0].id;
      }
      setState(() {
        isLoading = false;
        trabajadoresStream = FirebaseFirestore.instance
            .collection('usuarios')
            .where('id', isGreaterThanOrEqualTo: 'T')
            .where('id', isLessThan: 'U')
            .snapshots();
      });
    }).catchError((error) {
      print('Error al obtener el trabajador: $error');
      setState(() {
        isLoading = false;
      });
    });
  }

  void obtenerTrabajadorId() {
    String? trabajadorEmail = FirebaseAuth.instance.currentUser!.email;

    FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: trabajadorEmail)
        .get()
        .then((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          trabajadorId = snapshot.docs[0].id;
          isLoading = false;
        });
      }
    }).catchError((error) {
      print('Error al obtener el trabajador: $error');
      setState(() {
        isLoading = false;
      });
    });
  }

  // void calcularPromedioCalificaciones(String trabajadorId) {
  //   double promedio = 0.0;
  //   int cantidadCalificaciones = 0;

  //   FirebaseFirestore.instance
  //       .collection('contratos')
  //       .where('trabajadorId', isEqualTo: trabajadorId)
  //       .where('estado', isEqualTo: 'cerrado')
  //       .get()
  //       .then((QuerySnapshot snapshot) {
  //     for (var doc in snapshot.docs) {
  //       if (doc['calificacion'] != null) {
  //         promedio += doc['calificacion'];
  //         cantidadCalificaciones++;
  //       }
  //     }

  //     if (cantidadCalificaciones > 0) {
  //       promedio = promedio / cantidadCalificaciones;
  //     }

  //     setState(() {
  //       promedioCalificaciones = promedio;
  //     });
  //   }).catchError((error) {
  //     print('Error al obtener los contratos: $error');
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(63, 63, 156, 1),
        elevation: 0,
        title: isLoading
            ? const Text(
                'Cargando...', // Mostrar texto de carga mientras se obtiene el valor de trabajadorId
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(empleadorId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Cargando...', // Mostrar texto de carga mientras se obtiene la información del trabajador
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text(
                      'Error al cargar los datos',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    );
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final empleadorNombre = userData['nombre'];
                  final empleadorApellido = userData['apellido'];

                  return Container(
                    height: 40,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: FittedBox(
                      child: Row(
                        children: [
                          const Icon(Icons.handshake_outlined),
                          const SizedBox(width: 10),
                          Text(
                            '¡Bienvenido $empleadorNombre $empleadorApellido!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'eliminarCuenta') {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmar eliminación de cuenta'),
                      content: const Text(
                          '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Eliminar cuenta'),
                          onPressed: () {
                            final userData = FirebaseAuth.instance.currentUser;
                            final solicitudRef = FirebaseFirestore.instance
                                .collection('solicitud_eliminar_cuenta');
                            final usuariosRef = FirebaseFirestore.instance
                                .collection('usuarios');

                            usuariosRef
                                .doc(userData?.uid)
                                .get()
                                .then((snapshot) {
                              if (snapshot.exists) {
                                final nombre = snapshot.data()?['nombre'];
                                final id = snapshot.data()?['id'];
                                final apellido = snapshot.data()?['apellido'];

                                // Guardar los datos de la solicitud en Firestore
                                solicitudRef.add({
                                  'usuarioId': userData?.uid,
                                  'email': userData?.email,
                                  'nombre': nombre,
                                  'apellido': apellido,
                                  'id': id,
                                  'fecha': DateTime.now(),
                                }).then((_) {
                                  // Cerrar todos los diálogos anteriores y mostrar el mensaje de confirmación
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Solicitud enviada'),
                                        content: const Text(
                                            'Tu solicitud para eliminar la cuenta ha sido enviada.'),
                                        actions: [
                                          TextButton(
                                            child: const Text('Cerrar'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }).catchError((error) {
                                  // Manejar el error si no se puede guardar la solicitud
                                  print(
                                      'Error al guardar la solicitud: $error');
                                  // Mostrar un diálogo o una notificación para informar al usuario sobre el error.
                                });
                              } else {
                                // El documento del usuario no existe en la colección "usuarios"
                                print(
                                    'Error: No se encontró el usuario en la colección "usuarios".');
                                // Mostrar un diálogo o una notificación para informar al usuario sobre el error.
                              }
                            }).catchError((error) {
                              // Manejar el error si no se pueden obtener los datos del usuario
                              print(
                                  'Error al obtener los datos del usuario: $error');
                              // Mostrar un diálogo o una notificación para informar al usuario sobre el error.
                            });
                          },
                        ),
                      ],
                    );
                  },
                );
              } else if (value == 'verPublicacionesEliminadas') {
                mostrarPublicacionesEliminadas(context, empleadorId);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'eliminarCuenta',
                child: Text('Solicitar eliminación de cuenta'),
              ),
              const PopupMenuItem<String>(
                value: 'verPublicacionesEliminadas',
                child: Text('Ver publicaciones eliminadas'),
              ),
            ],
          ),
        ],
        ///////////////////////////////////////////////
      ),
      ////////////////////////////////////////////body
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context)
              .unfocus(); // Cierra el teclado virtual al tocar en cualquier lugar de la pantalla
        },
        child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.grey[200],
            child: _currentIndex == 0
                ? const HomeEmpleadorPage()
                : _currentIndex == 1
                    ? const ContratosScreen()
                    : _currentIndex == 2
                        ? const RegistroPublicacionScreen()
                        : const SalirPage()),
      ),

      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text("Inicio"),
            selectedColor: const Color.fromRGBO(63, 63, 156, 1),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.file_present_sharp),
            title: const Text("Contratos"),
            selectedColor: const Color.fromRGBO(63, 63, 156, 1),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.note_add_outlined),
            title: const Text("Crear contrato"),
            selectedColor: const Color.fromRGBO(63, 63, 156, 1),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.exit_to_app),
            title: const Text("Salir"),
            selectedColor: const Color.fromRGBO(63, 63, 156, 1),
          ),
        ],
      ),
    );
  }

  void mostrarPublicacionesEliminadas(
      BuildContext context, String empleadorId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('public_eliminada')
              .where('empleadorId', isEqualTo: empleadorId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const AlertDialog(
                  content:
                      Text('Error al cargar las publicaciones eliminadas'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const AlertDialog(
                  content: Text('No hay publicaciones eliminadas'));
            }

            return AlertDialog(
              content: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final publicacion = snapshot.data!.docs[index];
                  final descripcion = publicacion['descripcion'];
                  final motivo = publicacion['motivo'];

                  return ListTile(
                    title: Text('Descripción: $descripcion'),
                    subtitle: Text('Motivo: $motivo'),
                  );
                },
              ),
              actions: [
                TextButton(
                  child: const Text('Cerrar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
