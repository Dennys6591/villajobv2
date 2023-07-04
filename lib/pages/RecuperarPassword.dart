import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  String correo = '';
  bool isLoading = false;

  mostrarDialogo(String mensaje){
    showDialog(context: context, builder:(context) {
      return AlertDialog(
        title: Text('Recuperar contraseña'),
        content: Text(mensaje),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Aceptar'),
          ),
        ],
      );
    },);
  }

  void sendPasswordResetEmail(String recipientEmail, String clave) async {
  String username = 'proyectovillajob@gmail.com';
  String password = 'moeshxtkodvnneeg';

  final smtpServer = gmail(username, password);
  final message = Message()
    ..from = Address(username, 'VillaJob')
    ..recipients.add(recipientEmail)
    ..subject = 'Recuperación de contraseña'
    ..text = 'Hola,\n\nHas solicitado restablecer tu contraseña. Su contraseña es: $clave\n\nSi no solicitó restablecer su contraseña, ignore este correo electrónico.\n\nGracias,\nVillaJob';
  
  setState(() {
      isLoading = true;
    });

  try {
    final sendReport = await send(message, smtpServer);
    setState(() {
      isLoading = false;
    });
    Navigator.pop(context);
    mostrarDialogo('Correo electrónico enviado exitosamente.');
    // print('Correo electrónico enviado: $sendReport.toString()');
  } catch (e) {
    mostrarDialogo('Error al enviar el correo electrónico: $e');
    setState(() {
      isLoading = false;
    });
    // print('Error al enviar el correo electrónico: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recuperar contraseña'),
      ),
      body: Container(
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
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Ingrese su correo electrónico'),
            SizedBox(height: 20,),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Correo electrónico',
              ),
              onChanged: (value) {
                setState(() {
                  correo = value;
                });
              },
            ),
            SizedBox(height: 20,),
            ElevatedButton(
              onPressed: isLoading ? null : () {
                sendPasswordResetEmail(correo, '123456');
              },
              child: isLoading ? CircularProgressIndicator(color: Colors.white,) : Text('Enviar correo'),
            ),
          ],
        ),
      ),
    );
  }
}