import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:villajob/pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:villajob/pages/registroPubli.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
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
                      title: Text('Confirmar eliminación de cuenta'),
                      content: Text(
                          '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.'),
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
                                        title: Text('Solicitud enviada'),
                                        content: Text(
                                            'Tu solicitud para eliminar la cuenta ha sido enviada.'),
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
              PopupMenuItem<String>(
                value: 'eliminarCuenta',
                child: Text('Solicitar eliminación de cuenta'),
              ),
              PopupMenuItem<String>(
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 47, 152, 233),
                Color.fromRGBO(163, 140, 220, 0.757),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ListView(
              children: [
                const Text('Lista de trabajadores', textAlign: TextAlign.center, 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                const SizedBox(height: 20),
                TextField(

                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre',

                    prefixIcon: Icon(Icons.search),

                    filled: true, // Agrega el fondo blanco

                    fillColor:
                        Colors.white, // Establece el color de fondo blanco

                    hintStyle: TextStyle(
                        color: Colors
                            .black), // Establece el color del texto de sugerencia

                    border: OutlineInputBorder(
                      borderSide: BorderSide.none, // Elimina el borde

                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                isLoading
                    ? CircularProgressIndicator()
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('usuarios')
                            .where('id', isGreaterThanOrEqualTo: 'T')
                            .where('id', isLessThan: 'U')
                            .snapshots(),
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
                            final trabajadores = snapshot.data!.docs;

                            // Filtrar trabajadores por nombre

                            final filteredTrabajadores =
                                trabajadores.where((trabajador) {
                              final nombreCompleto =
                                  '${trabajador['nombre']} ${trabajador['apellido']}';

                              return nombreCompleto
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase());
                            }).toList();

                            if (filteredTrabajadores.isNotEmpty) {
                              return ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: filteredTrabajadores.length,
                                itemBuilder: (BuildContext context, int index) {
                                  var trabajador = filteredTrabajadores[index];

                                  return Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    height: MediaQuery.of(context).size.height *
                                        0.125,
                                    margin: EdgeInsets.all(20),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Icon(Icons.person, size: 50),
                                        Column(
                                          children: [
                                            Text(
                                              '${trabajador['nombre']} ${trabajador['apellido']} \nTeléfono: ${trabajador['telefono']} \nCédula: ${trabajador['cedula']} \nCalificacion: ${trabajador['promedioCalificaciones']}',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            const SizedBox(height: 5),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } else {
                              return Text('No se encontraron trabajadores.');
                            }
                          }

                          return Text('No se encontraron trabajadores.');
                        },
                      ),
              ],
            ),
          ),
        ),
      ),

      //////////////////////////////////fin body
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.folder),
              onPressed: () {
                // visualizar el contrato para darle la opcion de cerrarlo
                //y calificar
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ContratosScreen()));
              },
            ),
            Text('Contratos', style: TextStyle(fontSize: 12)),
            IconButton(
              icon: Icon(Icons.add_to_photos),
              onPressed: () {
                // visualizar el contrato para darle la opcion de cerrarlo
                //y calificar
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => RegistroPublicacionScreen()));
              },
            ),
            Text('Nueva publicación', style: TextStyle(fontSize: 12)),

            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                print("Saliendo");
                FirebaseAuth.instance.signOut().then((value) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreem()),
                  );
                });
              },
            ),
            Text('Salir', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void mostrarPublicacionesEliminadas(BuildContext context, String empleadorId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: SingleChildScrollView( // Agregar SingleChildScrollView aquí
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('public_eliminadas')
                      .where('empleadorId', isEqualTo: empleadorId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text('Error al cargar las publicaciones eliminadas');
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Text('No hay publicaciones eliminadas para este empleador');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
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
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text('Cerrar'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

}
