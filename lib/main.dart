import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestione Valori',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> valori = {};
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String recognizedText = "";
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('valori');
    if (jsonString != null) {
      setState(() {
        valori = Map<String, int>.from(json.decode(jsonString));
      });
    }
  }

  Future<void> _salvaDati() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('valori', json.encode(valori));
  }

  void aggiornaValore(String nome, int cambio) {
    setState(() {
      if (valori.containsKey(nome)) {
        valori[nome] = (valori[nome] ?? 0) + cambio;
      }
    });
    _salvaDati();
  }

  void startListening() async {
    try {
      bool available = await speech.initialize(
        onStatus: (status) => print("STATUS: $status"),
        onError: (error) => print("ERROR: $error"),
      );

      if (available) {
        setState(() {
          isListening = true;
        });
        speech.listen(
          onResult: (result) {
            setState(() {
              recognizedText = result.recognizedWords;
              processCommand(recognizedText);
            });
          },
        );
      } else {
        print("ERRORE: Il riconoscimento vocale non è disponibile.");
      }
    } catch (e) {
      print("ECCEZIONE: $e");
    }
  }

  void stopListening() {
    setState(() {
      isListening = false;
    });
    speech.stop();
  }

  void processCommand(String command) {
    command = command.toLowerCase();
    if (command.contains("aggiungi uno a")) {
      String nome = command.replaceAll("aggiungi uno a ", "").trim();
      if (valori.containsKey(nome)) {
        aggiornaValore(nome, 1);
      }
    } else if (command.contains("togli uno a")) {
      String nome = command.replaceAll("togli uno a ", "").trim();
      if (valori.containsKey(nome)) {
        aggiornaValore(nome, -1);
      }
    }
  }

  void aggiungiNome(String nome) {
    setState(() {
      if (nome.isNotEmpty && !valori.containsKey(nome)) {
        valori[nome] = 0;
      }
    });
    _salvaDati();
    _nameController.clear();
    Navigator.pop(context);
  }

  void rimuoviNome(String nome) {
    setState(() {
      valori.remove(nome);
    });
    _salvaDati();
  }

  void mostraDialogoAggiungiNome() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Aggiungi Nuovo Nome"),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(hintText: "Inserisci il nome"),
        ),
        actions: [
          TextButton(
            onPressed: () => aggiungiNome(_nameController.text),
            child: Text("Aggiungi"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annulla"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestione Valori')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: valori.keys.map((nome) {
                return ListTile(
                  title: Text(nome),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () => aggiornaValore(nome, -1),
                      ),
                      Text(valori[nome].toString(), style: TextStyle(fontSize: 20)),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => aggiornaValore(nome, 1),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => rimuoviNome(nome),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                onPressed: mostraDialogoAggiungiNome,
                child: Icon(Icons.add),
              ),
              FloatingActionButton(
                onPressed: isListening ? stopListening : startListening,
                child: Icon(isListening ? Icons.mic_off : Icons.mic),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
