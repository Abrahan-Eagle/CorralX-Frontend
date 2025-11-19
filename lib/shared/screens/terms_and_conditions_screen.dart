import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  final String title;
  final String type; // 'terms' o 'privacy'

  const TermsAndConditionsScreen({
    super.key,
    this.title = 'Términos y Condiciones',
    this.type = 'terms',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 32 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título principal
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 28 : 24,
                    color: colorScheme.onSurface,
                  ),
                ),

                SizedBox(height: isTablet ? 24 : 20),

                // Fecha de última actualización
                Container(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.update,
                        size: isTablet ? 20 : 18,
                        color: colorScheme.primary,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: isTablet ? 16 : 14,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 32 : 24),

                // Contenido
                _buildContent(theme, colorScheme, isTablet),

                SizedBox(height: isTablet ? 40 : 32),

                // Botón de aceptar (solo si viene desde el registro)
                if (ModalRoute.of(context)?.settings.arguments ==
                    'from_registration')
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: isTablet ? 32 : 24),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: Icon(Icons.check_circle, size: isTablet ? 24 : 20),
                      label: Text(
                        'Aceptar',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 18 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    if (type == 'privacy') {
      return _buildPrivacyPolicy(theme, colorScheme, isTablet);
    }
    return _buildTermsAndConditions(theme, colorScheme, isTablet);
  }

  Widget _buildTermsAndConditions(
      ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '1. Aceptación de los Términos',
          'Al acceder y utilizar CorralX, aceptas cumplir con estos Términos y Condiciones. Si no estás de acuerdo con alguna parte de estos términos, no debes utilizar nuestros servicios.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '2. Descripción del Servicio',
          'CorralX es una plataforma digital que conecta a productores ganaderos, compradores y vendedores de ganado, facilitando transacciones comerciales en el sector agropecuario.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '3. Registro y Cuenta de Usuario',
          'Para utilizar nuestros servicios, debes crear una cuenta proporcionando información veraz y actualizada. Eres responsable de mantener la confidencialidad de tus credenciales y de todas las actividades que ocurran bajo tu cuenta.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '4. Uso de la Plataforma',
          'Te comprometes a utilizar CorralX de manera legal y ética. Está prohibido:\n\n• Publicar información falsa o engañosa\n• Realizar actividades fraudulentas\n• Infringir derechos de propiedad intelectual\n• Violar cualquier ley o regulación aplicable',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '5. Publicaciones y Contenido',
          'Eres responsable del contenido que publiques en la plataforma. CorralX se reserva el derecho de moderar, editar o eliminar cualquier contenido que viole estos términos o las políticas de la plataforma.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '6. Transacciones Comerciales',
          'CorralX actúa como intermediario facilitando la conexión entre compradores y vendedores. No somos parte de las transacciones comerciales ni garantizamos la calidad de los productos. Las transacciones son responsabilidad exclusiva de las partes involucradas.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '7. Privacidad y Protección de Datos',
          'El manejo de tus datos personales se rige por nuestra Política de Privacidad. Al utilizar nuestros servicios, aceptas la recopilación y uso de información según se describe en dicha política.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '8. Propiedad Intelectual',
          'Todos los derechos de propiedad intelectual sobre la plataforma, incluyendo diseño, logos, y contenido, son propiedad de CorralX. No puedes reproducir, distribuir o crear obras derivadas sin autorización previa.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '9. Limitación de Responsabilidad',
          'CorralX no se hace responsable por daños directos, indirectos, incidentales o consecuentes derivados del uso o la imposibilidad de usar nuestros servicios.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '10. Modificaciones de los Términos',
          'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios entrarán en vigor al ser publicados en la plataforma. Es tu responsabilidad revisar periódicamente estos términos.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '11. Terminación',
          'Podemos suspender o terminar tu cuenta en cualquier momento si violas estos términos o cualquier política de la plataforma.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '12. Ley Aplicable',
          'Estos términos se rigen por las leyes de Venezuela. Cualquier disputa será resuelta en los tribunales competentes del país.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '13. Contacto',
          'Para consultas sobre estos términos, puedes contactarnos a través de los canales de soporte disponibles en la plataforma.',
        ),
      ],
    );
  }

  Widget _buildPrivacyPolicy(
      ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '1. Información que Recopilamos',
          'Recopilamos información que nos proporcionas directamente, incluyendo:\n\n• Datos de registro (nombre, email, teléfono)\n• Información del perfil\n• Datos de ubicación\n• Información de publicaciones y transacciones',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '2. Uso de la Información',
          'Utilizamos tu información para:\n\n• Proporcionar y mejorar nuestros servicios\n• Personalizar tu experiencia\n• Comunicarnos contigo\n• Cumplir con obligaciones legales',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '3. Compartir Información',
          'No vendemos tu información personal. Podemos compartir información solo en los siguientes casos:\n\n• Con tu consentimiento explícito\n• Para cumplir con obligaciones legales\n• Con proveedores de servicios que nos ayudan a operar la plataforma',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '4. Seguridad de los Datos',
          'Implementamos medidas de seguridad técnicas y organizativas para proteger tu información personal contra acceso no autorizado, pérdida o destrucción.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '5. Tus Derechos',
          'Tienes derecho a:\n\n• Acceder a tu información personal\n• Rectificar datos inexactos\n• Solicitar la eliminación de tus datos\n• Oponerte al procesamiento de tus datos',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '6. Cookies y Tecnologías Similares',
          'Utilizamos cookies y tecnologías similares para mejorar tu experiencia y analizar el uso de la plataforma.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '7. Retención de Datos',
          'Conservamos tu información mientras tu cuenta esté activa o según sea necesario para proporcionar servicios o cumplir con obligaciones legales.',
        ),
        _buildSection(
          theme,
          colorScheme,
          isTablet,
          '8. Cambios en la Política',
          'Podemos actualizar esta política periódicamente. Te notificaremos sobre cambios significativos.',
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isTablet,
    String title,
    String content,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 20 : 18,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 10),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: isTablet ? 16 : 14,
              color: colorScheme.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
