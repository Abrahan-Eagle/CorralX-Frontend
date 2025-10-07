import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ranch.dart';
import '../providers/profile_provider.dart';
import '../services/ranch_service.dart';

class EditRanchScreen extends StatefulWidget {
  final Ranch ranch;

  const EditRanchScreen({
    super.key,
    required this.ranch,
  });

  @override
  State<EditRanchScreen> createState() => _EditRanchScreenState();
}

class _EditRanchScreenState extends State<EditRanchScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _legalNameController;
  late TextEditingController _taxIdController;
  late TextEditingController _descriptionController;
  late TextEditingController _contactHoursController;
  late TextEditingController _deliveryPolicyController;
  late TextEditingController _returnPolicyController;
  
  late bool _isPrimary;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores con datos existentes
    _nameController = TextEditingController(text: widget.ranch.name);
    _legalNameController = TextEditingController(text: widget.ranch.legalName ?? '');
    _taxIdController = TextEditingController(text: widget.ranch.taxId ?? '');
    _descriptionController = TextEditingController(text: widget.ranch.businessDescription ?? '');
    _contactHoursController = TextEditingController(text: widget.ranch.contactHours ?? '');
    _deliveryPolicyController = TextEditingController(text: widget.ranch.deliveryPolicy ?? '');
    _returnPolicyController = TextEditingController(text: widget.ranch.returnPolicy ?? '');
    
    _isPrimary = widget.ranch.isPrimary;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _taxIdController.dispose();
    _descriptionController.dispose();
    _contactHoursController.dispose();
    _deliveryPolicyController.dispose();
    _returnPolicyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await RanchService.updateRanch(
        ranchId: widget.ranch.id,
        name: _nameController.text,
        legalName: _legalNameController.text.isNotEmpty ? _legalNameController.text : null,
        taxId: _taxIdController.text.isNotEmpty ? _taxIdController.text : null,
        businessDescription: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        contactHours: _contactHoursController.text.isNotEmpty ? _contactHoursController.text : null,
        isPrimary: _isPrimary,
        deliveryPolicy: _deliveryPolicyController.text.isNotEmpty ? _deliveryPolicyController.text : null,
        returnPolicy: _returnPolicyController.text.isNotEmpty ? _returnPolicyController.text : null,
      );

      setState(() => _isSubmitting = false);

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Hacienda actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refrescar ranches en ProfileProvider
        await context.read<ProfileProvider>().fetchMyRanches(forceRefresh: true);
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al actualizar hacienda'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Hacienda'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre de la hacienda
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Hacienda *',
                border: OutlineInputBorder(),
                helperText: 'Nombre comercial de tu hacienda',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Razón social
            TextFormField(
              controller: _legalNameController,
              decoration: const InputDecoration(
                labelText: 'Razón Social',
                border: OutlineInputBorder(),
                helperText: 'Nombre legal de la empresa',
              ),
            ),
            const SizedBox(height: 16),

            // RIF/NIT
            TextFormField(
              controller: _taxIdController,
              decoration: const InputDecoration(
                labelText: 'RIF/NIT',
                border: OutlineInputBorder(),
                helperText: 'Identificación fiscal',
              ),
            ),
            const SizedBox(height: 16),

            // Descripción del negocio
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción del Negocio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Horario de contacto
            TextFormField(
              controller: _contactHoursController,
              decoration: const InputDecoration(
                labelText: 'Horario de Atención',
                border: OutlineInputBorder(),
                helperText: 'Ej: Lunes a Viernes 8am - 5pm',
              ),
            ),
            const SizedBox(height: 16),

            // Política de entrega
            TextFormField(
              controller: _deliveryPolicyController,
              decoration: const InputDecoration(
                labelText: 'Política de Entrega',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Política de devolución
            TextFormField(
              controller: _returnPolicyController,
              decoration: const InputDecoration(
                labelText: 'Política de Devolución',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Switch: Hacienda principal
            SwitchListTile(
              title: const Text('Marcar como Hacienda Principal'),
              subtitle: const Text(
                'Solo una hacienda puede ser principal',
                style: TextStyle(fontSize: 12),
              ),
              value: _isPrimary,
              onChanged: (value) => setState(() => _isPrimary = value),
              activeColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // Botón Guardar
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: theme.colorScheme.surfaceVariant,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Guardar Cambios',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Información',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Los cambios afectarán todas tus publicaciones asociadas a esta hacienda\n'
                    '• La hacienda principal aparecerá destacada en tu perfil público\n'
                    '• Solo puedes tener una hacienda principal a la vez',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

