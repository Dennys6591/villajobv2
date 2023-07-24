import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeEmpleadorPage extends StatefulWidget {
  const HomeEmpleadorPage({super.key});

  @override
  State<HomeEmpleadorPage> createState() => _HomeEmpleadorPageState();
}

class _HomeEmpleadorPageState extends State<HomeEmpleadorPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        const Text(
          'Listado de empleados',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 25,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre',

              prefixIcon: const Icon(Icons.search),

              filled: true, // Agrega el fondo blanco

              fillColor: Colors.white, // Establece el color de fondo blanco

              hintStyle: const TextStyle(
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
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .where('id', isGreaterThanOrEqualTo: 'T')
                .where('id', isLessThan: 'U')
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final trabajadores = snapshot.data!.docs;

                // Filtrar trabajadores por nombre

                final filteredTrabajadores = trabajadores.where((trabajador) {
                  final nombreCompleto =
                      '${trabajador['nombre']} ${trabajador['apellido']}';

                  return nombreCompleto
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
                }).toList();

                if (filteredTrabajadores.isNotEmpty) {
                  return ListView.builder(
                    itemCount: filteredTrabajadores.length,
                    itemBuilder: (BuildContext context, int index) {
                      var trabajador = filteredTrabajadores[index];

                      return Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.125,
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            const Icon(Icons.person, size: 50),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${trabajador['nombre']} ${trabajador['apellido']} \nTeléfono: ${trabajador['telefono']} \nCédula: ${trabajador['cedula']} \nCalificacion: ${trabajador['promedioCalificaciones']}',
                                  style: const TextStyle(fontSize: 12),
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
                  return const Text('No se encontraron trabajadores.');
                }
              }

              return const Text('No se encontraron trabajadores.');
            },
          ),
        ),
      ],
    );
  }
}
