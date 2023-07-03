import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:villajob/pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:villajob/pages/perfiltrabajador.dart';

class TrabajadoresScreen extends StatefulWidget {
  const TrabajadoresScreen({Key? key});

  @override
  State<TrabajadoresScreen> createState() => _TrabajadoresScreenState();
}

class _TrabajadoresScreenState extends State<TrabajadoresScreen> {
  late String trabajadorId;
  bool isLoading = true;

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
        extendBodyBehindAppBar: true,//Extiende el widget detras del appbar
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: isLoading
              ? Text(
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
                      return Text(
                        'Cargando...', // Mostrar texto de carga mientras se obtiene la información del trabajador
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Text(
                        'Error al cargar los datos',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold),
                      );
                    }

                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final trabajadorNombre = userData['nombre'];
                    final trabajadorApellido = userData['apellido'];

                    return Text(
                      'Trabajador: $trabajadorNombre $trabajadorApellido',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
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
                  gradient: LinearGradient(colors: [
                Color.fromARGB(255, 47, 152, 233),
                Color.fromRGBO(236, 163, 249, 1)
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('publicaciones')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error al cargar las publicaciones');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (snapshot.hasData) {
                          final List<QueryDocumentSnapshot> documents =
                              snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: documents.length,
                            itemBuilder: (context, index) {
                              final document = documents[index];

                              // Obtener el ID del empleador
                              final empleadorId = document['empleadorId'];

                              // Obtener la información del empleador desde la colección de usuarios
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .doc(empleadorId)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError || !snapshot.hasData) {
                                    // Manejar el error o el documento no encontrado
                                    return Container();
                                  }

                                  final userData = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  final empleadorNombre = userData['nombre'];
                                  final empleadorApellido =
                                      userData['apellido'];
                                  final empleadorTelefono =
                                      userData['telefono'];

                                  // Mostrar la publicación junto con el nombre y apellido del empleador
                                  return GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title:
                                                Text(document['descripcion']),
                                            content: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'Empleador: $empleadorNombre $empleadorApellido'),
                                                Text(
                                                    'Teléfono: $empleadorTelefono'),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(
                                                      context, 'Salir');
                                                },
                                                child: const Text('Salir'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _aceptarPublicacion(
                                                    document.id,
                                                    document['empleadorId'],
                                                    document['bloqueada'],
                                                  );
                                                  Navigator.pop(
                                                      context, 'Aceptar');
                                                },
                                                child: const Text('Aceptar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Card(
                                      child: ListTile(
                                        title: Text(document['descripcion']),
                                        subtitle: Text(
                                            'Empleador: $empleadorNombre $empleadorApellido'),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }

                        return Container();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(     
                  child: BottomAppBar(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(   
                          icon: Icon(Icons.person_outline),
                          onPressed: () {
                            Navigator.push(
                            context, MaterialPageRoute(builder: (context)=> PerfilTrabajador()),
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
                )),
          ],
        )
      );
  }

  void _aceptarPublicacion(
      String publicacionId, String empleadorId, bool publicacionBloqueada) {
    // Obtener el ID del trabajador actualmente autenticado
    String? trabajadorEmail = FirebaseAuth.instance.currentUser!.email;

    // Obtener el documento del trabajador desde la colección de usuarios
    FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: trabajadorEmail)
        .get()
        .then((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        String trabajadorId = snapshot.docs[0].id;

        // Verificar si el trabajador ya ha aceptado la misma publicación
        FirebaseFirestore.instance
            .collection('contratos')
            .where('publicacionId', isEqualTo: publicacionId)
            .get()
            .then((QuerySnapshot snapshot) {
          if (snapshot.docs.isNotEmpty) {
            // Mostrar mensaje en una pantalla
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Esta publicación ya ha sido aceptada por otro trabajador'),
              ),
            );
          } else if (!publicacionBloqueada) {
            // Generar un ID único para el contrato
            String contratoId =
                'contrato${DateTime.now().millisecondsSinceEpoch}';

            // Guardar el contrato en Firestore
            FirebaseFirestore.instance
                .collection('contratos')
                .doc(contratoId)
                .set({
              'id': contratoId,
              'trabajadorId': trabajadorId,
              'empleadorId': empleadorId,
              'publicacionId':
                  publicacionId, // Agregar el ID de la publicación al contrato
              'calificacion': -1,
              'estado': "abierto",
            }).then((value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contrato creado con éxito'),
                ),
              );

              // Marcar la publicación como bloqueada
              FirebaseFirestore.instance
                  .collection('publicaciones')
                  .doc(publicacionId)
                  .update({
                'bloqueada': true,
              }).then((value) {
                print('Publicación bloqueada con éxito');
              }).catchError((error) {
                // Error al bloquear la publicación
                print('Error al bloquear la publicación: $error');
              });
            }).catchError((error) {
              // Error al guardar el contrato
              print('Error al guardar el contrato: $error');
            });
          }
        }).catchError((error) {
          // Error al consultar la colección de contratos
          print(
              'Error al verificar si el trabajador ha aceptado la publicación: $error');
        });
      } else {
        // No se encontró el trabajador en la colección de usuarios
        print('Error: Trabajador no encontrado');
      }
    }).catchError((error) {
      // Error al consultar la colección de usuarios
      print('Error al obtener el trabajador: $error');
    });
  }
}
