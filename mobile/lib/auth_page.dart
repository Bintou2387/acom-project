import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'api_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true; // true = Connexion, false = Inscription
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  // Contrôleurs
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool success;
    if (_isLogin) {
      // TENTATIVE DE CONNEXION
      success = await _api.login(_emailCtrl.text, _passCtrl.text);
    } else {
      // TENTATIVE D'INSCRIPTION
      success = await _api.signup(
        _emailCtrl.text, 
        _passCtrl.text, 
        _nameCtrl.text, 
        _phoneCtrl.text
      );
      // Si inscription réussie, on connecte automatiquement l'utilisateur
      if (success) {
        success = await _api.login(_emailCtrl.text, _passCtrl.text);
      }
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLogin ? "Bon retour !" : "Bienvenue sur Acom !"), backgroundColor: Colors.green)
      );
      context.go('/'); // Retour à l'accueil
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur d'identifiants ou email déjà pris"), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LOGO OU ICONE
                  const Icon(Icons.lock_person, size: 80, color: Color(0xFF003580)),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? "Connexion" : "Créer un compte",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003580)),
                  ),
                  const SizedBox(height: 30),

                  // CHAMPS
                  if (!_isLogin) ...[
                    _field(_nameCtrl, "Nom complet", Icons.person),
                    const SizedBox(height: 15),
                    _field(_phoneCtrl, "Téléphone", Icons.phone, type: TextInputType.phone),
                    const SizedBox(height: 15),
                  ],

                  _field(_emailCtrl, "Email", Icons.email, type: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _field(_passCtrl, "Mot de passe", Icons.lock, isPass: true),

                  const SizedBox(height: 30),

                  // BOUTON ACTION
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003580),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(_isLogin ? "SE CONNECTER" : "S'INSCRIRE", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 20),

                  // TOGGLE BUTTON
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? "Pas encore de compte ? Créer un compte" : "Déjà un compte ? Se connecter",
                      style: const TextStyle(color: Color(0xFF003580)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool isPass = false, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (val) => val == null || val.isEmpty ? "Requis" : null,
    );
  }
}