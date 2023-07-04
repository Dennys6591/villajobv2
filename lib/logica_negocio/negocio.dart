import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//logeo de clientes
class LoginNegocio {
  Future<Map<String, dynamic>?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String? userEmail = userCredential.user!.email;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: userEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs[0].data() as Map<String, dynamic>;
        String? userType = userData['opcion'];

        return {
          'userEmail': userEmail,
          'userType': userType,
        };
      } else {
        return null;
      }
    } catch (error) {
      print('Error de inicio de sesión: $error');
      return null;
    }
  }
}

///////////registro de clientes
class RegistroNegocio {
  Future<bool> createUserAndSaveData({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String opcion,
  }) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String id = '';
      String idE = '';
      if (opcion == 'Trabajador') {
        id =
            'T${DateTime.now().microsecondsSinceEpoch.toString().padLeft(6, '0')}';
      } else if (opcion == 'Empleador') {
        id =
            'E${DateTime.now().microsecondsSinceEpoch.toString().padLeft(6, '0')}';
      } else if (opcion == 'Ambos') {
        id =
            'T${DateTime.now().microsecondsSinceEpoch.toString().padLeft(6, '0')}';

        idE =
            'E${DateTime.now().microsecondsSinceEpoch.toString().padLeft(6, '0')}';
        await FirebaseFirestore.instance.collection('usuarios').doc(id).set({
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
          'cedula': cedula,
          'telefono': telefono,
          'opcion': opcion,
          'id': idE,
        });
      }

      await FirebaseFirestore.instance.collection('usuarios').doc(id).set({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'cedula': cedula,
        'telefono': telefono,
        'opcion': opcion,
        'id': id,
      });

      return true;
    } catch (error) {
      print('Error en el registro: $error');
      return false;
    }
  }
}
