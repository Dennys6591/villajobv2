import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:villajob/pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:villajob/pages/trabajadores.dart';
import 'login.dart';

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
      }

      if (cantidadCalificaciones > 0) {
        promedio = promedio / cantidadCalificaciones;
      }
      print(trabajadorId);
      // Cambiar la primera letra del ID a 'T'
      String nuevoId = 'T' + trabajadorId.substring(1);
      print(nuevoId);
      // Verificar si el ID del trabajador empieza con 'T' antes de actualizar el promedio en Firestore
      if (nuevoId.startsWith('T')) {
        // Actualiza el valor del promedio en Firestore en la colección 'usuarios'
        DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('usuarios').doc(nuevoId);

        await userDocRef.update({'promedioCalificaciones': promedio});
        promedioCalificaciones = promedio;
        print(
            'El promedio de calificaciones se ha actualizado en Firestore para el trabajador con ID que empieza por "T".');
      } else {
        print(
            'El trabajador con ID $trabajadorId no cumple con el requisito de que empiece con "T". No se actualizó el promedio en Firestore.');
      }
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

  //double get obtenerPromedioCalificaciones => promedioCalificaciones;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[700],
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contratos del trabajador', style: TextStyle(fontSize: 20)),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: isLoading
            ? Center(
                child: const CircularProgressIndicator(),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('contratos')
                    .where('trabajadorId', isEqualTo: trabajadorId)
                    .where('estado', isEqualTo: 'cerrado')
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al cargar los contratos.'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
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
                            return ListTile(
                              title: Text('Error al cargar el nombre'),
                            );
                          }

                          if (nombreSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              title: Text('Cargando nombre...'),
                            );
                          }

                          final nombreTrabajador =
                              nombreSnapshot.data ?? 'Nombre desconocido';

                          return ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nombre del trabajador:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(nombreTrabajador),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calificación:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(contrato['calificacion'].toString()),
                              ],
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estado:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(contrato['estado'].toString()),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
