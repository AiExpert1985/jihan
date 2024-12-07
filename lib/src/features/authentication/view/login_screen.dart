// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/features/authentication/repository/auth_repository.dart';
import 'package:toastification/toastification.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenScreenState();
}

class _LoginScreenScreenState extends ConsumerState<LoginScreen> {
  final _loginForm = GlobalKey<FormState>(); // the key used to access the form

  String _userEmail = '';
  String _userPassword = '';

  void _submitForm() async {
    final isValid = _loginForm.currentState!.validate(); // runs validator
    if (!isValid) {
      return;
    }

    _loginForm.currentState!.save(); // runs onSave inside form
    final isSuccessful =
        await ref.watch(authRepositoryProvider).signUserIn(_userEmail, _userPassword);
    if (!isSuccessful) {
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: Text(S.of(context).db_error_login),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
          child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(15),
              width: 200,
              child: Image.asset('assets/images/logo.png'),
            ),
            SizedBox(
              width: 300,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Form(
                    key: _loginForm,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(labelText: S.of(context).email),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty || !value.contains('@')) {
                              return S.of(context).input_validation_error_message_for_email;
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _userEmail = value!; // value can't be null
                          },
                        ),
                        TextFormField(
                          decoration: InputDecoration(labelText: S.of(context).password),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return S.of(context).input_validation_error_message_for_password;
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _userPassword = value!; // value can't be null
                          },
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: Text(S.of(context).login),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
