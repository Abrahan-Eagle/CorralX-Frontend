import 'package:flutter/material.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFDF7),
        elevation: 0,
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.arrow_back, size: isTablet ? 28 : 24),
        ),
        title: Text(
          'Publicar Nuevo Ganado',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1C18),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photos section
              _buildSection(
                title: 'Fotos del Animal (hasta 5)',
                subtitle: 'La primera foto será la imagen de portada.',
                child: Container(
                  height: isTablet ? 120 : 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4ED),
                    borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: isTablet ? 40 : 32,
                          color: Colors.grey,
                        ),
                        SizedBox(height: isTablet ? 10 : 8),
                        Text(
                          'Agregar fotos',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 32 : 24),
              // Registration section
              _buildSection(
                title: 'Registro del Animal',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Radio<String>(
                          value: 'con-registro',
                          groupValue: 'sin-registro',
                          onChanged: (value) {},
                        ),
                        Text('Con Registro', style: TextStyle(fontSize: isTablet ? 16 : 14)),
                        SizedBox(width: isTablet ? 32 : 24),
                        Radio<String>(
                          value: 'sin-registro',
                          groupValue: 'sin-registro',
                          onChanged: (value) {},
                        ),
                        Text('Sin Registro', style: TextStyle(fontSize: isTablet ? 16 : 14)),
                      ],
                    ),
                  ],
                ),
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 32 : 24),
              // Animal details section
              _buildSection(
                title: 'Detalles del Animal',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                              ),
                              labelText: 'Tipo',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 12 : 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'lechero', child: Text('Lechero')),
                              DropdownMenuItem(value: 'engorde', child: Text('Engorde')),
                              DropdownMenuItem(value: 'padrote', child: Text('Padrote')),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                              ),
                              labelText: 'Raza',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 12 : 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                              ),
                              labelText: 'Edad (años)',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 12 : 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                              ),
                              labelText: 'Cantidad',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 12 : 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 32 : 24),
              // Farm selection section
              _buildSection(
                title: 'Información de la Finca',
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                        ),
                        labelText: 'Selecciona la Finca',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 12 : 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'farm1', child: Text('Agropecuaria El Futuro')),
                        DropdownMenuItem(value: 'farm2', child: Text('Hato La Esperanza')),
                      ],
                      onChanged: (value) {},
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                        ),
                        labelText: 'Descripción',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 12 : 8,
                        ),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 32 : 24),
              // Featured checkbox
              _buildSection(
                child: Row(
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (value) {},
                    ),
                    Text(
                      'Marcar como Publicación Destacada',
                      style: TextStyle(fontSize: isTablet ? 16 : 14),
                    ),
                  ],
                ),
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 40 : 32),
              // Action buttons
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(fontSize: isTablet ? 16 : 14),
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF386A20),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                            ),
                          ),
                          child: Text(
                            'Publicar',
                            style: TextStyle(fontSize: isTablet ? 16 : 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    String? title,
    String? subtitle,
    required Widget child,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4ED),
        borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.grey,
                ),
              ),
            ],
            SizedBox(height: isTablet ? 20 : 16),
          ],
          child,
        ],
      ),
    );
  }
}
