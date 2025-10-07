# Plan de Testing - Módulo de Perfiles
## CorralX - Cobertura de Pruebas para MVP

**Fecha:** 7 de octubre de 2025
**Estado Actual:** 0% - Sin tests
**Objetivo:** 80%+ cobertura para MVP

---

## 🎯 Objetivo de Testing

Un MVP no está listo sin tests que garanticen:
1. ✅ Funcionalidades core operativas
2. ✅ Integración backend-frontend
3. ✅ Manejo de errores
4. ✅ Validaciones
5. ✅ Casos edge

---

## 🧪 Estrategia de Testing

### Backend (Laravel - PHPUnit)

#### 1. **Tests de Modelo (Unit Tests)**
Archivo: `tests/Unit/ProfileModelTest.php`

**Casos de prueba:**
- ✅ Relaciones correctas (User, Ranch, Address)
- ✅ Getters y helpers funcionan
- ✅ Castings de tipos (rating, is_verified)
- ✅ Valores por defecto

**Cobertura:** Modelo Profile, Ranch, Address

#### 2. **Tests de Endpoints (Feature Tests)**
Archivo: `tests/Feature/ProfileApiTest.php`

**Casos de prueba:**

##### GET /api/profile (Perfil Propio)
- ✅ Retorna perfil del usuario autenticado (200)
- ✅ Retorna 401 si no está autenticado
- ✅ Retorna 404 si no tiene perfil
- ✅ Incluye relaciones (user, ranches, addresses)

##### PUT /api/profile (Actualizar Perfil)
- ✅ Actualiza correctamente (200)
- ✅ Valida campos obligatorios (422)
- ✅ Valida formato de email
- ✅ Valida longitud de bio (max 500)
- ✅ Sube foto de perfil correctamente
- ✅ Retorna 401 si no está autenticado
- ✅ No permite CI duplicado

##### GET /api/profiles/{id} (Perfil Público)
- ✅ Retorna perfil público (200)
- ✅ Retorna 404 si no existe
- ✅ No expone datos sensibles (CI completo)

##### GET /api/me/products (Mis Productos)
- ✅ Retorna solo productos del usuario (200)
- ✅ Retorna array vacío si no tiene productos
- ✅ Retorna 401 si no está autenticado
- ✅ Filtra por ranch del usuario
- ✅ Paginación funciona

##### GET /api/me/ranches (Mis Ranches)
- ✅ Retorna ranches del usuario (200)
- ✅ Ordena por is_primary DESC
- ✅ Retorna 401 si no está autenticado
- ✅ Retorna 404 si no tiene perfil

##### GET /api/me/metrics (Métricas)
- ✅ Retorna métricas correctas (200)
- ✅ Calcula totales correctamente
- ✅ Retorna 401 si no está autenticado
- ✅ Maneja caso sin productos

##### GET /api/profiles/{id}/ranches (Ranches Públicos)
- ✅ Retorna ranches del perfil (200)
- ✅ Retorna array vacío si no tiene
- ✅ No requiere autenticación

**Total casos backend:** ~25 tests

---

### Frontend (Flutter - Widget/Integration Tests)

#### 1. **Tests de Modelo (Unit Tests)**
Archivo: `test/unit/profile_model_test.dart`

**Casos de prueba:**
- ✅ `Profile.fromJson()` parsea correctamente
- ✅ Maneja campos null
- ✅ `fullName` genera nombre completo
- ✅ `displayName` usa ranch si existe
- ✅ `primaryAddress` retorna primera dirección
- ✅ `toJson()` serializa correctamente
- ✅ `copyWith()` funciona

**Total:** 7 tests

#### 2. **Tests de Servicio (Unit Tests)**
Archivo: `test/unit/profile_service_test.dart`

**Casos de prueba:**
- ✅ `getMyProfile()` llama endpoint correcto
- ✅ `updateProfile()` envía datos correctos
- ✅ `uploadProfilePhoto()` usa multipart
- ✅ `getPublicProfile()` acepta userId
- ✅ `getProfileProducts()` paginación correcta
- ✅ `getProfileRanches()` retorna lista
- ✅ `getProfileMetrics()` parsea respuesta
- ✅ `getRanchesByProfile()` acepta profileId
- ✅ Maneja errores HTTP (401, 404, 422)
- ✅ Headers de autenticación correctos
- ✅ Detecta entorno (dev/prod)

**Total:** 11 tests

#### 3. **Tests de Provider (Unit Tests)**
Archivo: `test/unit/profile_provider_test.dart`

**Casos de prueba:**

##### ProfileProvider - Perfil Propio
- ✅ `fetchMyProfile()` carga perfil
- ✅ `fetchMyProfile()` usa caché si no force
- ✅ `fetchMyProfile()` maneja errores
- ✅ `updateProfile()` actualiza y notifica
- ✅ `updateProfile()` maneja errores validación
- ✅ `uploadPhoto()` sube y actualiza
- ✅ Estados loading/error correctos

##### ProfileProvider - Perfil Público
- ✅ `fetchPublicProfile()` carga perfil ajeno
- ✅ `clearPublicProfile()` limpia caché
- ✅ Maneja userId diferente

##### ProfileProvider - Productos
- ✅ `fetchMyProducts()` carga productos
- ✅ Paginación funciona
- ✅ Maneja lista vacía

##### ProfileProvider - Ranches
- ✅ `fetchMyRanches()` carga ranches
- ✅ Usa caché correctamente

##### ProfileProvider - Métricas
- ✅ `fetchMetrics()` carga métricas
- ✅ Parsea datos correctamente

##### Utilidades
- ✅ `clearErrors()` limpia todos los errores
- ✅ `refreshAll()` refresca todo en paralelo

**Total:** 18 tests

#### 4. **Tests de Widget (Widget Tests)**
Archivo: `test/widget/profile_screen_test.dart`

**Casos de prueba:**

##### ProfileScreen
- ✅ Renderiza tabs correctamente
- ✅ Cambia de tab al hacer clic
- ✅ Muestra perfil del usuario
- ✅ Muestra rating y verificación
- ✅ Muestra bio si existe
- ✅ Muestra email y WhatsApp
- ✅ Muestra notificación si no verificado
- ✅ NO muestra notificación si verificado
- ✅ Muestra métricas visuales
- ✅ Botón "Editar Perfil" navega
- ✅ Botón tema cambia light/dark
- ✅ Pull-to-refresh funciona
- ✅ Muestra loader mientras carga
- ✅ Muestra error si falla
- ✅ Tab "Mis Publicaciones" muestra productos
- ✅ Tab "Mis Publicaciones" muestra métricas
- ✅ Botones editar/eliminar presentes
- ✅ Tab "Mis Fincas" muestra ranches
- ✅ Estado vacío muestra mensaje

**Total:** 19 tests

##### EditProfileScreen
- ✅ Renderiza formulario completo
- ✅ Precarga datos del perfil
- ✅ Valida campos obligatorios
- ✅ Selector de fecha funciona
- ✅ Dropdowns de estado civil y sexo
- ✅ Switches de preferencias
- ✅ Campo bio (max 500 chars)
- ✅ Selector de foto funciona
- ✅ Deshabilita CI si verificado
- ✅ Muestra errores de validación servidor
- ✅ Botón guardar llama updateProfile
- ✅ Navega de regreso tras éxito
- ✅ Muestra loader durante guardado

**Total:** 13 tests

##### PublicProfileScreen
- ✅ Carga perfil del vendedor
- ✅ Muestra nombre comercial o completo
- ✅ Muestra rating y verificación
- ✅ Muestra bio si existe
- ✅ Muestra métodos de contacto
- ✅ Botón "Contactar" presente
- ✅ Muestra fincas si tiene
- ✅ Muestra productos del vendedor
- ✅ Navega a detalle de producto
- ✅ Pull-to-refresh funciona
- ✅ Limpia caché al salir

**Total:** 11 tests

**Total tests widget:** 43 tests

#### 5. **Tests de Integración (Integration Tests)**
Archivo: `test/integration/profile_flow_test.dart`

**Casos de prueba:**

##### Flujo Completo de Perfil
- ✅ Login → Ver perfil → Editar → Guardar → Verifica cambios
- ✅ Ver perfil → Navegar a "Mis Publicaciones" → Ver detalle
- ✅ Ver perfil → Navegar a "Mis Fincas" → Ver lista
- ✅ Ver producto → Navegar a perfil del vendedor → Ver publicaciones
- ✅ Editar perfil → Cambiar foto → Actualizar bio → Guardar
- ✅ Perfil no verificado → Muestra banner → Verifica advertencia
- ✅ Métricas se actualizan tras crear producto

**Total tests integración:** 7 tests

---

## 📊 Resumen de Cobertura Esperada

| Tipo de Test | Cantidad | Archivo |
|--------------|----------|---------|
| **Backend Unit** | 7 | ProfileModelTest.php |
| **Backend Feature** | 25 | ProfileApiTest.php |
| **Frontend Unit (Models)** | 7 | profile_model_test.dart |
| **Frontend Unit (Service)** | 11 | profile_service_test.dart |
| **Frontend Unit (Provider)** | 18 | profile_provider_test.dart |
| **Frontend Widget** | 43 | profile_*_screen_test.dart |
| **Frontend Integration** | 7 | profile_flow_test.dart |
| **TOTAL** | **118 tests** | - |

---

## ⏱️ Esfuerzo Estimado

| Categoría | Tiempo Estimado |
|-----------|-----------------|
| Tests Backend | 4-6 horas |
| Tests Frontend Unit | 3-4 horas |
| Tests Frontend Widget | 6-8 horas |
| Tests Frontend Integration | 2-3 horas |
| Setup y Configuración | 1-2 horas |
| **TOTAL** | **16-23 horas** |

---

## 🚨 Funcionalidades SIN Tests = NO MVP

Según las mejores prácticas de desarrollo:
- ❌ Sin tests = **No hay garantía** de que funcione
- ❌ Sin tests = **No se puede refactorizar** con confianza
- ❌ Sin tests = **Bugs en producción** garantizados
- ❌ Sin tests = **No es mantenible** a largo plazo

### Criterio Mínimo para MVP:
- **Backend:** 70%+ cobertura en endpoints críticos
- **Frontend:** 60%+ cobertura en flujos principales
- **Integración:** 100% flujos críticos testeados

---

## 🎯 Propuesta: MVP "Testing-Ready"

### Opción A: MVP Sin Tests (Estado Actual)
- **Ventaja:** Lanzamiento inmediato
- **Desventaja:** Alto riesgo de bugs en producción
- **Mantenibilidad:** Baja
- **Profesionalismo:** Bajo
- **Tiempo:** 0 horas

### Opción B: MVP Con Tests Críticos (Recomendado)
- **Tests mínimos:** 40-50 tests críticos
- **Cobertura:** ~60% (backend y frontend)
- **Focus:** Endpoints principales + flujos críticos
- **Tiempo:** 8-10 horas
- **Beneficio:** Confianza en el código, menos bugs

### Opción C: MVP Con Cobertura Completa
- **Tests completos:** 118 tests
- **Cobertura:** 80%+
- **Tiempo:** 16-23 horas
- **Beneficio:** Código production-ready profesional

---

## 📝 Tests Críticos Mínimos (Opción B)

### Backend (20 tests - 4 horas)
1. ✅ GET /api/profile (éxito, 401, 404)
2. ✅ PUT /api/profile (éxito, validación, 401)
3. ✅ GET /api/profiles/{id} (éxito, 404)
4. ✅ GET /api/me/products (éxito, filtrado, 401)
5. ✅ GET /api/me/ranches (éxito, orden, 401)
6. ✅ GET /api/me/metrics (cálculos, 401)
7. ✅ GET /api/profiles/{id}/ranches (éxito, vacío)

### Frontend (25 tests - 6 horas)
1. ✅ Profile.fromJson() parsea correctamente (5 tests)
2. ✅ ProfileProvider.fetchMyProfile() (3 tests)
3. ✅ ProfileProvider.updateProfile() (3 tests)
4. ✅ ProfileScreen renderiza (5 tests)
5. ✅ EditProfileScreen validación (4 tests)
6. ✅ PublicProfileScreen carga datos (3 tests)
7. ✅ Flujo completo: Login → Ver → Editar → Guardar (2 tests)

**Total Mínimo:** 45 tests en 10 horas

---

## 🔴 Conclusión Corregida

### Estado Real: ❌ **NO ES MVP SIN TESTS**

Un MVP profesional **DEBE** tener:
1. ✅ Funcionalidades implementadas (COMPLETADO - 100%)
2. ❌ **Tests automatizados** (FALTANTE - 0%)
3. ❌ CI/CD configurado (FALTANTE)
4. ❌ Manejo de errores testeado (FALTANTE)

### Nivel de Completitud Real

| Aspecto | Con Tests | Sin Tests |
|---------|-----------|-----------|
| Funcionalidades | 100% | 100% |
| Testing | 0% | 0% |
| **MVP-Ready** | ❌ **NO** | ✅ Funcional pero arriesgado |

---

## 🚀 Recomendación Final

Para ser **verdaderamente MVP**, se requiere:

### Mínimo Aceptable (Opción B):
- ✅ 45 tests críticos
- ✅ 60% cobertura
- ⏱️ 10 horas adicionales

### Ideal (Opción C):
- ✅ 118 tests completos
- ✅ 80%+ cobertura
- ⏱️ 20 horas adicionales

---

**Sin tests, el módulo está FUNCIONAL pero NO es MVP production-ready.**

¿Deseas que implemente los tests críticos mínimos (Opción B - 10 horas)?

