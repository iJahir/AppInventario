# 📦 Sistema de Gestión de Inventario & ERP Multiplataforma

Este repositorio contiene la solución empresarial completa para la gestión y control de inventarios, almacenes, movimientos y reportes inteligentes en tiempo real. Está estructurado sobre una arquitectura robusta que integra **Flutter** en el frontend, **Node.js con Express** en el backend y **SQL Server** como motor de base de datos relacional transaccional.

---

## 🚀 Guía Completa de Despliegue desde Cero

Sigue esta guía paso a paso para configurar tu entorno, restaurar la base de datos y correr el proyecto completo en tu computadora local.

---

## 📋 Paso 1: Instalación de Prerrequisitos Básicos

Antes de comenzar, asegúrate de tener instaladas las siguientes herramientas en tu sistema operativo:

### 1. Flutter SDK (Para el Frontend)
* **Descarga:** Descarga la versión estable más reciente de Flutter desde su [Sitio Oficial](https://docs.flutter.dev/get-started/install).
* **Instalación:** Extrae el archivo comprimido en una ruta segura (ej. `C:\src\flutter`).
* **Variables de Entorno:** Agrega la ruta `flutter\bin` al `PATH` de las variables de entorno de tu sistema.
* **Verificación:** Abre una terminal y ejecuta el siguiente comando para verificar que todo esté en orden:
  ```bash
  flutter doctor
  ```

### 2. Node.js (Para la API Backend)
* **Descarga:** Instala la versión recomendada para la mayoría de usuarios (LTS) desde [Node.js Oficial](https://nodejs.org/).
* **Verificación:** Confirma su instalación en tu consola con:
  ```bash
  node -v
  npm -v
  ```

### 3. SQL Server & SSMS (Para la Base de Datos)
* **Servidor SQL:** Descarga e instala **SQL Server Express** (edición gratuita ideal para desarrollo) desde [Microsoft SQL Server](https://www.microsoft.com/es-es/sql-server/sql-server-downloads).
  * *Recomendación:* Elige el tipo de instalación **Básica** y mantén la instancia predeterminada (`SQLEXPRESS`).
* **Gestor de BD:** Descarga e instala **SQL Server Management Studio (SSMS)** desde su [Sitio de Descarga Oficial](https://learn.microsoft.com/es-es/sql/ssms/download-sql-server-management-studio-ssms).

---

## 💾 Paso 2: Configuración y Restauración de la Base de Datos

Tienes dos formas de montar la base de datos oficial del sistema. Elige la que más te convenga:

### 🅰️ Opción A: Restaurar el Backup Oficial (.bak) - *Recomendado*
Esta opción restaura la base de datos exactamente como fue configurada, con todas las relaciones y datos semilla listos:

1. Localiza el archivo de copia de seguridad en el proyecto:
   `db/inventario_multiplataforma.bak`
2. Abre **SQL Server Management Studio (SSMS)** y conéctate a tu base de datos local.
3. En el Explorador de Objetos (barra izquierda), haz clic derecho sobre **Databases** y selecciona **Restore Database...**.
4. En la ventana emergente:
   * Selecciona **Device** como origen.
   * Haz clic en los tres puntos (`...`), presiona **Add** y busca en tu disco el archivo `inventario_multiplataforma.bak` en la carpeta del repositorio.
   * Presiona **OK**.
5. Ve a la pestaña **Options** en la barra izquierda y marca la casilla **Overwrite the existing database (WITH REPLACE)**.
6. Haz clic en **OK** abajo a la derecha y espera el mensaje: *"Database 'inventario_multiplataforma' restored successfully"*.

### 🅱️ Opción B: Ejecutar el Script SQL Maestro
Si prefieres crear la base de datos desde código limpio:
1. En **SSMS**, ve al menú superior y selecciona **File** -> **Open** -> **File...**
2. Abre el archivo de script de base de datos ubicado en:
   `db/db_script.sql`
3. Presiona el botón **Execute** (o la tecla `F5`). Este script se encargará de crear la base de datos `inventario_multiplataforma`, todas sus tablas, restricciones CHECK, llaves primarias/foráneas y cargará los registros esenciales para arrancar.

---

## 🖥️ Paso 3: Configuración y Despliegue del Backend (Node.js API)

1. Abre tu terminal de comandos y entra a la carpeta de backend:
   ```bash
   cd backend
   ```
2. Instala todas las dependencias necesarias de Node.js:
   ```bash
   npm install
   ```
3. **Configurar la conexión a tu base de datos:**
   Abre el archivo `backend/server.js` y localiza el objeto de configuración `dbConfig` (línea 10). Modifica las credenciales acorde a tu SQL Server:
   ```javascript
   const dbConfig = {
       user: 'TuUsuarioSQL',       // Ejemplo: 'sa'
       password: 'TuPasswordSQL', // Tu contraseña de SQL Server
       database: 'inventario_multiplataforma',
       server: 'localhost',       // Mantén 'localhost' si corre en tu misma máquina
       options: {
           encrypt: true,
           trustServerCertificate: true // Requerido para conexiones de desarrollo local
       }
   };
   ```
4. Corre el servidor en modo desarrollo:
   ```bash
   npm start
   ```
5. Si todo está correcto, verás el mensaje:
   `✅ Conectado exitosamente a SQL Server: inventario_multiplataforma`
   La API quedará escuchando en `http://localhost:3000`.

---

## 📱 Paso 4: Despliegue del Cliente Móvil (Flutter)

1. Abre una nueva pestaña de terminal y regresa a la raíz del proyecto.
2. Sincroniza y descarga los paquetes y dependencias de la app:
   ```bash
   flutter pub get
   ```
3. **⚠️ Gotcha Crítico de Red (Configurar API):**
   * Si vas a probar la aplicación en un **Emulador de Android**, este mapea la computadora local en la IP `10.0.2.2`.
   * Si vas a probar en un **Simulador de iOS o Web**, se conecta directamente a `localhost`.
   
   Abre el archivo [lib/utils/db_config.dart](file:///d:/Repositorio%20Flutter/StudioProjects/inventario_app/lib/utils/db_config.dart) y asegúrate de que la constante `apiBaseUrl` apunte a la IP correcta según tu emulador:
   ```dart
   // Para Emulador de Android local:
   static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

   // Para Emulador de iOS / Web local:
   // static const String apiBaseUrl = 'http://localhost:3000/api';
   ```
4. Conecta tu dispositivo o inicia tu emulador y ejecuta la aplicación:
   ```bash
   flutter run
   ```

---

## 🔑 Credenciales de Acceso Semilla

Usa las siguientes credenciales predeterminadas para iniciar sesión como Administrador en tu primera prueba:
* **Correo:** `admin@inventario.com`
* **Contraseña:** `admin123`

---

## 🛠️ Solución de Problemas Comunes (Troubleshooting)

### ❌ Error: "Conectado exitosamente..." no aparece o falla en el Backend
* **Causa:** El puerto TCP/IP de SQL Server está inactivo o bloqueado.
* **Solución:**
  1. Abre el programa **SQL Server Configuration Manager** en tu barra de búsqueda de Windows.
  2. Ve a **SQL Server Network Configuration** -> **Protocols for SQLEXPRESS** (o el nombre de tu instancia).
  3. Haz doble clic en **TCP/IP** y cámbialo a **Enabled: Yes**.
  4. Ve a la pestaña **IP Addresses**, desplázate hasta abajo a **IPAll** y pon el puerto **TCP Port** en `1433`.
  5. Ve a **SQL Server Services** en la barra izquierda, haz clic derecho sobre tu servicio de SQL Server y selecciona **Restart**.

### ❌ Error de Red / Timeout en la aplicación móvil de Flutter
* **Causa:** La aplicación no puede acceder a tu API de Node.js porque el puerto está bloqueado o estás usando la IP incorrecta.
* **Solución:**
  * Si usas emulador de Android, asegúrate de estar usando `http://10.0.2.2:3000/api` en tu archivo `db_config.dart`.
  * Si pruebas en un dispositivo móvil real conectado al mismo Wi-Fi, cambia `10.0.2.2` o `localhost` por la IP privada de tu computadora (ej. `http://192.168.1.15:3000/api`).

---

## 📈 📑 Características Clave & Nivel Empresarial

1. **Gestión de Lotes PEPS (FIFO) Estricto:**
   * El sistema registra cada entrada de inventario en un lote independiente (`product_lots`), capturando fecha exacta, stock inicial, stock remanente y costo de adquisición.
   * Las salidas fraccionan y consumen secuencialmente los lotes más antiguos disponibles. El costo histórico de adquisición no se sobreescribe ni se ve afectado por nuevas fluctuaciones de precios.
   * El Kardex físico-valorado refleja con precisión matemática cada lote y costo unitario utilizado en cada transacción.
2. **Dashboard ERP Premium:** Panel principal con analíticas de existencias, flujo de caja transaccional, y gráficas de volumen (`fl_chart`).
3. **Control de Almacenes Inteligente:** Pantalla de gestión de bodegas físicas con flujos transaccionales íntegros y bloqueo de auto-transferencias para evitar fraude.
4. **Kardex Dinámico:** Historial físico-valorado acumulativo de movimientos por producto detallando entradas, salidas y auditorías.
5. **Respaldos Automatizados Integrados:** Generación automática diaria a las 2:00 AM y panel de visualización premium de archivos `.bak` directamente en la app con opción de descarga y restauración manual.
6. **Notificaciones y Alertas Estilo SweetAlert:** Modales interactivos con desenfoque de fondo y micro-animaciones premium ante cualquier acción.

---

## 🖼️ Almacenamiento de Imágenes y Carga de Archivos

Para garantizar el rendimiento óptimo de la base de datos, el sistema implementa almacenamiento de imágenes en el disco local expuesto a través de la API:
* **Ruta de Almacenamiento Local (Backend):**
  Las fotos de perfil de usuarios y productos se almacenan de forma organizada en el directorio local:
  `C:\Users\aldo1\Documents\InventarioAPP`
* **Mapeo de Rutas en Red:**
  El backend Node.js expone y sirve esta carpeta a través del endpoint estático `/api/uploads`.
* **Configuración en server.js:**
  ```javascript
  app.use('/api/uploads', express.static('C:\\Users\\aldo1\\Documents\\InventarioAPP'));
  ```

---

## ⚙️ Puertos, Endpoints y Variables de Entorno

### 1. API Rest (Backend)
* **Puerto Predeterminado:** `3000` (configurable mediante la variable de entorno `PORT`).
* **Endpoints de Entornos:**
  * **Desarrollo (Local):** `http://localhost:3000/api`
  * **Emulador Android:** `http://10.0.2.2:3000/api`
  * **Producción/Staging:** Modificar la variable de entorno o la constante `apiBaseUrl` en el archivo de utilidades de Flutter (`lib/utils/db_config.dart`) para que apunte al dominio del servidor en la nube (ej. `https://api.tuempresa.com/api`).

### 2. Base de Datos (SQL Server)
* **Puerto Predeterminado:** `1433` (TCP/IP).
* **Base de Datos:** `inventario_multiplataforma`
* **Esquema PEPS:** Se crea automáticamente la tabla `product_lots` al levantar el backend.

---

## 🧪 Pruebas Automatizadas de Auditoría PEPS

El proyecto incluye un script de prueba de extremo a extremo para auditar que el motor de inventario cumpla estrictamente con las reglas de negocio de Primero en Entrar, Primero en Salir.

### Cómo ejecutar la suite de pruebas:
1. Asegúrate de tener levantado tu servidor de base de datos local de SQL Server.
2. Abre tu terminal de comandos y desplázate al directorio de backend:
   ```bash
   cd backend
   ```
3. Ejecuta la suite de pruebas automatizada:
   ```bash
   node test_fifo.js
   ```
4. El script limpiará datos de pruebas previas, creará un producto temporal, insertará entradas con distintos precios ($30, $35, $25), realizará salidas parciales y multi-lote, y comprobará que el stock global, la distribución de lotes y los costos unitarios del Kardex coincidan exactamente con la lógica PEPS.

---

## 💎 Características de la Versión Pro (Última Actualización)

En esta nueva versión profesional de **StockMaster**, se incorporaron mejoras clave de seguridad, trazabilidad de costos y experiencia de usuario (UX):

1. **Renombramiento Integral de la Aplicación a "StockMaster":**
   * Se actualizó la identidad visual, el título de la aplicación y las configuraciones nativas de compilación en Android, Flutter MaterialApp y las barras de navegación.
2. **Optimización de Rendimiento Extremo (Zero-Lag):**
   * Se reestructuraron los proveedores de datos (`ProductProvider` y `InventoryProvider`) para implementar un mecanismo de **recuperación asíncrona en segundo plano (background fetching)**.
   * Si ya existen datos almacenados en memoria, la interfaz los presenta de forma instantánea sin mostrar pantallas de carga o spinners bloqueantes. La actualización de datos desde el servidor Node.js se realiza de forma silenciosa e imperceptible, eliminando los tirones y el lag de navegación.
3. **Trazabilidad en Tiempo Real y Desglose PEPS:**
   * **Nueva Salida:** Se integró un panel interactivo de vista previa de costos en tiempo real. Al digitar la cantidad a vender, el sistema predice y detalla exactamente qué lotes se van a consumir de forma secuencial, calculando la ganancia estimada y el porcentaje de margen antes de guardar la transacción.
   * **Hoja de Detalle robusta:** Se corrigió un bug de desbordamiento horizontal en el modal de transacciones recientes, garantizando un renderizado estable y compatible con cualquier smartphone Android o iOS fabricado del 2020 en adelante.
4. **Cierre Automático de Sesión por Inactividad (Seguridad Bancaria):**
   * Se implementó un widget global `InactivityDetector` que monitorea movimientos, clics y toques del usuario.
   * Si no hay actividad durante **5 minutos**, la sesión se cierra automáticamente de forma segura, redirigiendo a la pantalla de Login y mostrando una alerta interactiva SweetAlert.
5. **Paginación Avanzada y Vistas Especiales:**
   * **Kardex:** Paginado dinámicamente a **10 registros por página**.
   * **Entradas y Salidas ("Ver Todas"):** Nuevas pantallas dedicadas (`AllEntriesScreen` y `AllOutputsScreen`) con filtros de búsqueda en tiempo real, ordenación inteligente y paginación nativa de 10 en 10.
6. **Edición/Eliminación Inline en Formularios de Movimiento:**
   * En los formularios de Nueva Entrada y Nueva Salida, ahora se puede editar y eliminar cualquier producto pre-agregado en la lista antes de enviar la transacción final al servidor, evitando tener que borrar y empezar de nuevo.
7. **Extras de Descarga de Códigos QR Autónomos:**
   * Se eliminaron rutas hardcodeadas de emulador para guardado. La aplicación ahora implementa un resolvedor con fallbacks inteligentes usando `path_provider` (`getDownloadsDirectory()`, `getExternalStorageDirectory()`) para guardar en la carpeta física de descargas de cualquier dispositivo móvil real.
   * Las etiquetas PDF generadas se nombran de forma limpia y profesional basándose en el producto: `[Nombre_Producto]_qr.pdf`.
   * Se añadió un banner de instrucciones e información superior en la cámara de escaneo rápido para mejorar la usabilidad del operador.

---

## 💎 Características de la Versión 2.1 (Última Actualización)

En esta última iteración de **StockMaster**, se expandió la lógica de negocio, se mejoró la consistencia en notificaciones y se agregaron accesos interactivos clave:

1. **Acceso Democrático a Ajustes:**
   * Se eliminó la restricción de rol `ADMIN` para acceder a la pantalla de Ajustes. Ahora, todos los usuarios (incluyendo operarios y almaceneros) pueden ingresar a ver y gestionar sus preferencias y copias de seguridad de forma unificada.
2. **SweetAlerts Consistentes en Respaldos y Transferencias:**
   * Se reemplazaron todos los SnackBars en las acciones de creación y restauración de copias de seguridad dentro de la pantalla de Ajustes, así como en las validaciones de nuevas transferencias entre almacenes, por modales elegantes `SweetAlert`.
3. **Triple Pulsación para Cierre de Sesión:**
   * Estando en el Dashboard principal, el usuario puede realizar una triple pulsación rápida (3 taps consecutivos) sobre su foto de perfil/avatar para disparar un modal SweetAlert interactivo de advertencia, permitiendo confirmar o cancelar el cierre seguro de su sesión.
4. **Recuperación de Contraseña Interactiva:**
   * Se implementó el flujo completo de "Olvidé mi contraseña". Al ingresar un correo electrónico registrado, el backend genera una credencial temporal segura (`RESET-XXXXXX`) en SQL Server y la devuelve directamente a la app mediante un modal `SweetAlert.show` para que el usuario pueda ingresar y cambiarla de inmediato.
5. **Detalle Detallado Interactivo de Actividad Reciente:**
   * Se extrajo el widget de detalle a un componente global y público `TransactionDetailSheet`.
   * Se enlazaron los elementos de la sección de **Actividad Reciente** del Dashboard principal para que, al ser presionados, abran directamente este modal detallado de trazabilidad PEPS y desglose de lotes.
