import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 10,
        ),
        const Text(
          'Empleos disponibles',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('publicaciones')
                .where('empleadorEmail',
                    isNotEqualTo: FirebaseAuth.instance.currentUser!.email)
                .where('bloqueada', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Error al cargar las publicaciones');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
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

                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final empleadorNombre = userData['nombre'];
                        final empleadorApellido = userData['apellido'];
                        final empleadorTelefono = userData['telefono'];

                        // Mostrar la publicación junto con el nombre y apellido del empleador
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(document['descripcion']),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  content: Container(
                                    height: 80,
                                    width: 200,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Empleador: $empleadorNombre $empleadorApellido'),
                                        Text('Teléfono: $empleadorTelefono'),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, 'Salir');
                                      },
                                      child: const Text('Salir'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _aceptarPublicacion(
                                          document.id,
                                          document['empleadorId'],
                                          document['bloqueada'],
                                          context,
                                        );
                                        Navigator.pop(context, 'Aceptar');
                                      },
                                      child: const Text('Aceptar'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Card(
                              child: ListTile(
                                title: Text(document['descripcion']),
                                subtitle: Text(
                                    'Empleador: $empleadorNombre $empleadorApellido'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                              ),
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
    );
  }

  void _aceptarPublicacion(String publicacionId, String empleadorId,
      bool publicacionBloqueada, BuildContext context) {
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
