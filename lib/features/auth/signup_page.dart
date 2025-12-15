import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum SignupAccountType { business, customer }

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  SignupAccountType _accountType = SignupAccountType.business;
  bool _isSubmitting = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Business fields
  final _businessNameController = TextEditingController();
  String _businessCategory = 'retail';
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessCityController = TextEditingController();
  final _businessCountryController = TextEditingController(text: 'IT');

  // Customer fields
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerNotesController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _businessCityController.dispose();
    _businessCountryController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final cred = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = cred.user!.uid;
      final now = FieldValue.serverTimestamp();
      final userRef = firestore.collection('users').doc(uid);

      final batch = firestore.batch();
      final userData = <String, dynamic>{
        'role': _accountType == SignupAccountType.business
            ? 'business'
            : 'customer',
        'email': _emailController.text.trim(),
        'createdAt': now,
      };

      if (_accountType == SignupAccountType.business) {
        final workspaceRef = firestore.collection('workspaces').doc();
        batch.set(workspaceRef, {
          'name': _businessNameController.text.trim(),
          'category': _businessCategory,
          'phone': _businessPhoneController.text.trim(),
          'addressLine': _businessAddressController.text.trim(),
          'city': _businessCityController.text.trim(),
          'country': _businessCountryController.text.trim(),
          'createdAt': now,
          'createdByUid': uid,
        });

        final memberRef = workspaceRef.collection('members').doc(uid);
        batch.set(memberRef, {
          'role': 'owner',
          'joinedAt': now,
        });

        final membershipRef =
            firestore.collection('memberships').doc('${uid}_${workspaceRef.id}');
        batch.set(membershipRef, {
          'uid': uid,
          'workspaceId': workspaceRef.id,
          'role': 'owner',
          'joinedAt': now,
        });

        userData['profile'] = {
          'name': _businessNameController.text.trim(),
          'category': _businessCategory,
          'phone': _businessPhoneController.text.trim(),
          'addressLine': _businessAddressController.text.trim(),
          'city': _businessCityController.text.trim(),
          'country': _businessCountryController.text.trim(),
        };
      } else {
        final customerRef = firestore.collection('customers').doc(uid);
        batch.set(customerRef, {
          'uid': uid,
          'fullName': _customerNameController.text.trim(),
          'phone': _customerPhoneController.text.trim(),
          'notes': _customerNotesController.text.trim(),
          'createdAt': now,
        });

        userData['profile'] = {
          'fullName': _customerNameController.text.trim(),
          'phone': _customerPhoneController.text.trim(),
          'notes': _customerNotesController.text.trim(),
        };
      }

      batch.set(userRef, userData);

      await batch.commit();

      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      final message = e.message ?? 'Registrazione non riuscita';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante la registrazione')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea account'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Scegli il tipo di account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ToggleButtons(
                        isSelected: [
                          _accountType == SignupAccountType.business,
                          _accountType == SignupAccountType.customer,
                        ],
                        onPressed: _isSubmitting
                            ? null
                            : (index) {
                                setState(() {
                                  _accountType = index == 0
                                      ? SignupAccountType.business
                                      : SignupAccountType.customer;
                                });
                              },
                        borderRadius: BorderRadius.circular(8),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text('Attività'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text('Cliente'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _accountType == SignupAccountType.business
                          ? _BusinessForm(
                              nameController: _businessNameController,
                              category: _businessCategory,
                              onCategoryChanged: (value) {
                                setState(() => _businessCategory = value);
                              },
                              phoneController: _businessPhoneController,
                              addressController: _businessAddressController,
                              cityController: _businessCityController,
                              countryController: _businessCountryController,
                            )
                          : _CustomerForm(
                              nameController: _customerNameController,
                              phoneController: _customerPhoneController,
                              notesController: _customerNotesController,
                            ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Inserisci l\'email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci la password';
                          }
                          if (value.length < 6) {
                            return 'Almeno 6 caratteri';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Registrati'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BusinessForm extends StatelessWidget {
  const _BusinessForm({
    required this.nameController,
    required this.category,
    required this.onCategoryChanged,
    required this.phoneController,
    required this.addressController,
    required this.cityController,
    required this.countryController,
  });

  final TextEditingController nameController;
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController countryController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome attività',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci il nome dell\'attività';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: category,
          decoration: const InputDecoration(
            labelText: 'Categoria',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'retail', child: Text('Retail')),
            DropdownMenuItem(value: 'services', child: Text('Services')),
            DropdownMenuItem(value: 'beauty', child: Text('Beauty')),
            DropdownMenuItem(value: 'food', child: Text('Food')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) {
            if (value != null) onCategoryChanged(value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Seleziona una categoria';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Telefono',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci il telefono';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: 'Indirizzo (opzionale)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: cityController,
          decoration: const InputDecoration(
            labelText: 'Città (opzionale)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: countryController,
          decoration: const InputDecoration(
            labelText: 'Paese',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci il paese';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _CustomerForm extends StatelessWidget {
  const _CustomerForm({
    required this.nameController,
    required this.phoneController,
    required this.notesController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome e cognome',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci il nome';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Telefono',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci il telefono';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Note (opzionale)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
