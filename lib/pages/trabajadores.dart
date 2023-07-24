import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:villajob/pages/trabajadores_pages/inicio_page.dart';
import 'package:villajob/pages/trabajadores_pages/mostrarContrato.dart';
import 'package:villajob/pages/trabajadores_pages/perfiltrabajador.dart';
import 'package:villajob/pages/trabajadores_pages/salir_page.dart';

class TrabajadoresScreen extends StatefulWidget {
  const TrabajadoresScreen({Key? key});

  @override
  State<TrabajadoresScreen> createState() => _TrabajadoresScreenState();
}

class _TrabajadoresScreenState extends State<TrabajadoresScreen> {
  late String trabajadorId = '';
  bool isLoading = true;
  var _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    obtenerTrabajadorId();
  }

  void obtenerTrabajadorId() {
    String? trabajadorEmail = FirebaseAuth.instance.currentUser!.email;

    FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: trabajadorEmail)
        .get()
        .then((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        trabajadorId = snapshot.docs[0].id;
      }
      setState(() {
        isLoading = false;
      });
    }).catchError((error) {
      print('Error al obtener el trabajador: $error');
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBodyBehindAppBar: true, //Extiende el widget detras del appbar
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
                    .doc(trabajadorId)
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
                          TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    );
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final trabajadorNombre = userData['nombre'];
                  final trabajadorApellido = userData['apellido'];

                  return Row(
                    children: [
                      const Icon(Icons.work_outline),
                      const SizedBox(width: 10),
                      Text(
                        '¡Bienvenido $trabajadorNombre $trabajadorApellido!',
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                    ],
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                            // Obtener los datos del usuario actual
                            final userData = FirebaseAuth.instance.currentUser;
                            final solicitudRef = FirebaseFirestore.instance
                                .collection('solicitud_eliminar_cuenta');
                            final usuariosRef = FirebaseFirestore.instance
                                .collection('usuarios');

                            // Obtener el nombre y el ID del usuario de la colección "usuarios"
                            usuariosRef
                                .doc(trabajadorId)
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
                              // Manejar el error si no se puede obtener los datos del usuario
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
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'eliminarCuenta',
                child: Text('Solicitar eliminación de cuenta'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.grey[200],
          child: _currentIndex == 0
              ? const HomePage()
              : _currentIndex == 1
                  ? PerfilTrabajador(trabajadorId: trabajadorId)
                  : _currentIndex == 2
                      ? MostrarContrato()
                      : const SalirPage()),
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
            icon: const Icon(Icons.person_outline),
            title: const Text("Perfil"),
            selectedColor: const Color.fromRGBO(63, 63, 156, 1),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.file_present_sharp),
            title: const Text("Contratos"),
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
}
