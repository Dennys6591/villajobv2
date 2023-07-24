import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MostrarContrato extends StatefulWidget {
  const MostrarContrato({Key? key});

  @override
  State<MostrarContrato> createState() => _MostrarContratoState();
}

class _MostrarContratoState extends State<MostrarContrato> {
  late String trabajadorId;
  late double promedioCalificaciones = 0.0;
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
        setState(() {
          trabajadorId = snapshot.docs[0].id;
          isLoading = false;
        });
      }
      calcularPromedioCalificaciones(trabajadorId);
    }).catchError((error) {
      print('Error al obtener el trabajador: $error');
      setState(() {
        isLoading = false;
      });
    });
  }

  void calcularPromedioCalificaciones(String trabajadorId) async {
    double promedio = 0.0;
    int cantidadCalificaciones = 0;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('contratos')
          .where('trabajadorId', isEqualTo: trabajadorId)
          .where('estado', isEqualTo: 'cerrado')
          .get();
      for (var doc in snapshot.docs) {
        if (doc['calificacion'] >= 0) {
          promedio += doc['calificacion'];
          cantidadCalificaciones++;
        }
        promedio = promedio / cantidadCalificaciones;
      }

      // Actualiza el valor del promedio en Firestore en la colección 'usuarios'
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('usuarios').doc(trabajadorId);
      await userDocRef.update({'promedioCalificaciones': promedio});
      promedioCalificaciones = promedio;
      print('El promedio de calificaciones se ha actualizado en Firestore.');
    } catch (error) {
      print('Error al obtener los contratos: $error');
    }
  }

  Future<String> obtenerNombreTrabajador(String trabajadorId) async {
    DocumentSnapshot trabajadorSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(trabajadorId)
        .get();
    Map<String, dynamic> trabajadorData =
        trabajadorSnapshot.data() as Map<String, dynamic>;
    String nombreTrabajador = trabajadorData['nombre'] ?? 'Nombre desconocido';
    return nombreTrabajador;
  }

  // double get obtenerPromedioCalificaciones => promedioCalificaciones;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Contratos',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('contratos')
                      .where('trabajadorId', isEqualTo: trabajadorId)
                      .where('estado', isEqualTo: 'cerrado')
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error al cargar los contratos.'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No hay contratos disponibles.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (BuildContext context, int index) {
                        final contrato = snapshot.data!.docs[index];

                        return FutureBuilder<String>(
                          future:
                              obtenerNombreTrabajador(contrato['trabajadorId']),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> nombreSnapshot) {
                            if (nombreSnapshot.hasError) {
                              return const ListTile(
                                title: Text('Error al cargar el nombre'),
                              );
                            }

                            if (nombreSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const ListTile(
                                title: Text('Cargando nombre...'),
                              );
                            }

                            final nombreTrabajador =
                                nombreSnapshot.data ?? 'Nombre desconocido';

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Card(
                                child: ListTile(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Nombre del trabajador:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(nombreTrabajador),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Calificación:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(contrato['calificacion'].toString()),
                                    ],
                                  ),
                                  trailing: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Estado:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(contrato['estado'].toString()),
                                    ],
                                  ),
                                ),
                              ),
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
