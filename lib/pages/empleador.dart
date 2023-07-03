import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:villajob/pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:villajob/pages/registroPubli.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'contratos.dart';

class EmpleadoresScreen extends StatefulWidget {
  const EmpleadoresScreen({Key? key});

  @override
  State<EmpleadoresScreen> createState() => _EmpleadoresScreenState();
}

class _EmpleadoresScreenState extends State<EmpleadoresScreen> {
  late String empleadorId;
  late bool isLoading = true;

  @override
  void initState() {
    super.initState();
    obtenerEmpleadorId();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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

                  return Text(
                    'Empleador: $empleadorNombre $empleadorApellido',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
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
                      title: Text('Confirmar eliminación de cuenta'),
                      content: Text('¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(
                          child: Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Eliminar cuenta'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Confirmar eliminación de cuenta'),
                                  content: Text('¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.'),
                                  actions: [
                                    TextButton(
                                      child: Text('Cancelar'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: Text('Eliminar cuenta'),
                                      onPressed: () {
                                        // Obtener los datos del usuario actual
                                        final userData = FirebaseAuth.instance.currentUser;
                                        final solicitudRef = FirebaseFirestore.instance.collection('solicitud_eliminar_cuenta');
                                        // Guardar los datos de la solicitud en Firestore
                                        
                                        solicitudRef.add({
                                          'usuarioId': userData!.uid,
                                          'email': userData.email,
                                          'fecha': DateTime.now(),
                                        }).then((_) {
                                          // Cerrar todos los diálogos anteriores y mostrar el mensaje de confirmación
                                          Navigator.of(context).popUntil((route) => route.isFirst);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Solicitud enviada'),
                                                content: Text('Tu solicitud para eliminar la cuenta ha sido enviada.'),
                                                actions: [
                                                  TextButton(
                                                    child: Text('Cerrar'),
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
                                          print('Error al guardar la solicitud: $error');
                                          // Mostrar un diálogo o una notificación para informar al usuario sobre el error.
                                        });
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'eliminarCuenta',
                child: Text('Solicitar eliminación de cuenta'),
              ),
            ],
          ),
        ],
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: isLoading
                  ? CircularProgressIndicator()
                  : FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('usuarios')
                          .where('id', isGreaterThanOrEqualTo: 'T')
                          .where('id', isLessThan: 'U')
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (snapshot.hasData &&
                            snapshot.data!.docs.isNotEmpty) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(
                                  snapshot.data!.docs.length, (index) {
                                var trabajador = snapshot.data!.docs[index];

                                return Container(
                                  width: 180,
                                  height: 80,
                                  margin: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      trabajador['nombre'] +
                                          ' ' +
                                          trabajador['apellido'] +
                                          ' \n' +
                                          'Teléfono: ' +
                                          trabajador['telefono'] +
                                          ' \n' +
                                          'Cédula: ' +
                                          trabajador['cedula'],
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }

                        return Text('No se encontraron trabajadores.');
                      },
                    ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.person_outline),
                    onPressed: () {
                      // visualizar el contrato para darle la opcion de cerrarlo
                      //y calificar
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ContratosScreen()));
                    },
                  ),
                  ElevatedButton(
                    child: Text("Crear Publicación"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistroPublicacionScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () {
                      print("Saliendo");
                      FirebaseAuth.instance.signOut().then((value) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreem()),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
