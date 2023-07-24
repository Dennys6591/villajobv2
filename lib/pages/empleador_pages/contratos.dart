import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContratosScreen extends StatefulWidget {
  const ContratosScreen({Key? key});

  @override
  State<ContratosScreen> createState() => _ContratosScreenState();
}

class _ContratosScreenState extends State<ContratosScreen> {
  late String empleadorId;
  bool isLoading = true;
  int calificacion = 0;

  @override
  void initState() {
    super.initState();
    obtenerEmpleadorId();
  }

  void obtenerEmpleadorId() {
    String? empleadorEmail = FirebaseAuth.instance.currentUser!.email;

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
      print('Error al obtener el empleador: $error');
      setState(() {
        isLoading = false;
      });
    });
  }

  void calificarTrabajador(String trabajadorId, String contratoId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Calificar trabajador'),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Selecciona la calificación:'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          calificacion,
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => IconButton(
                            onPressed: () {
                              setState(() {
                                calificacion = index + 1;
                              });
                            },
                            icon: Icon(
                              index < calificacion
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                if (calificacion != 0) {
                  FirebaseFirestore.instance
                      .collection('contratos')
                      .doc(contratoId)
                      .update({
                    'calificacion': calificacion,
                    'estado': 'cerrado', // Actualizar el estado a "cerrado"
                  }).then((value) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Se ha calificado al trabajador.'),
                      ),
                    );
                  }).catchError((error) {
                    print('Error al calificar al trabajador: $error');
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Ocurrió un error al calificar al trabajador. Por favor, inténtalo de nuevo.'),
                      ),
                    );
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              disabledColor: Colors.grey,
              elevation: 0,
              color: Colors.deepPurple,
              textColor: Colors.white,
              child: const Text('Calificar'),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.pop(context);
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              disabledColor: Colors.grey,
              elevation: 0,
              color: Colors.deepPurple,
              textColor: Colors.white,
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(empleadorId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Cargando...',
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
                  final empleadorNombre = userData['nombre'];
                  final empleadorApellido = userData['apellido'];

                  return Text(
                    'Contratos de: $empleadorNombre $empleadorApellido',
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold),
                  );
                },
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('contratos')
                      .where('empleadorId', isEqualTo: empleadorId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Text('Error al cargar los contratos');
                    }

                    final List<QueryDocumentSnapshot> documents =
                        snapshot.data!.docs;

                    if (documents.isEmpty) {
                      return const Center(
                        child: Text('No hay contratos'),
                      );
                    }

                    return ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final document = documents[index];
                        final trabajadorId = document['trabajadorId'];
                        final publicacionId = document['publicacionId'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(trabajadorId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Text('Error al cargar los datos');
                            }

                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final trabajadorNombre = userData['nombre'];
                            final trabajadorApellido = userData['apellido'];
                            final trabajadorTelefono = userData['telefono'];
                            final trabajadorCedula = userData['cedula'];

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('publicaciones')
                                  .doc(publicacionId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError || !snapshot.hasData) {
                                  return const Text(
                                      'Error al cargar los datos');
                                }

                                final publicacionData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                final publicacionDescripcion =
                                    publicacionData['descripcion'];

                                return Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Card(
                                    child: ListTile(
                                      title: Text('Contrato ${index + 1}'),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 10),
                                          Text(
                                              'Trabajador: $trabajadorNombre $trabajadorApellido'),
                                          Text('Teléfono: $trabajadorTelefono'),
                                          Text('Cédula: $trabajadorCedula'),
                                          const SizedBox(height: 10),
                                          const Text(
                                              'Descripción de la publicación:'),
                                          Text(publicacionDescripcion),
                                          const SizedBox(height: 10),
                                          Text(
                                              'Estado del contrato: ${document['estado']}'),
                                        ],
                                      ),
                                      trailing: document['estado'] == 'abierto'
                                          ? MaterialButton(
                                              onPressed: () {
                                                calificarTrabajador(
                                                    trabajadorId, document.id);
                                              },
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              disabledColor: Colors.grey,
                                              elevation: 0,
                                              color: Colors.deepPurple,
                                              textColor: Colors.white,
                                              child:
                                                  const Text('Cerrar Contrato'),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: List.generate(
                                                document['calificacion'],
                                                (index) => const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
  }
}
