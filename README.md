# 📦 Sistema de Gestión de Inventario & ERP Multiplataforma

Este repositorio contiene la solución empresarial completa para la gestión y control de inventarios, almacenes, movimientos y reportes inteligentes en tiempo real, integrada con una arquitectura robusta de **Node.js, Express, SQL Server y Flutter**.

---

## 🛠️ Requisitos del Entorno

Asegúrate de contar con las siguientes herramientas instaladas antes de iniciar el despliegue:
* **Flutter SDK** (versión stable `>= 3.10.0`)
* **Node.js** (versión LTS recomendada)
* **SQL Server** (Express, Developer o Enterprise) con soporte de autenticación mixta (SQL y Windows).
* Un emulador Android (por ejemplo, Android Studio virtual device) o dispositivo físico en modo depuración.

---

## 💾 Paso 1: Configuración de la Base de Datos (SQL Server)

Tienes dos alternativas profesionales para inicializar la base de datos de la solución:

### 🅰️ Opción A: Ejecutar el Script SQL Maestro (Recomendado para instalaciones limpias)
1. Abre tu herramienta gestora de base de datos (**SQL Server Management Studio** o **Azure Data Studio**).
2. Conéctate a tu servidor SQL local.
3. Abre y ejecuta por completo el script maestro de base de datos ubicado en:
   👉 [db/db_script.sql](file:///d:/Repositorio%20Flutter/StudioProjects/inventario_app/db/db_script.sql)
4. El script creará la base de datos `inventario_multiplataforma`, todas las tablas operativas con relaciones íntegras, restricciones CHECK para transacciones y transferencias, auditorías, y un catálogo inicial de datos semilla listos para operar.

### 🅱️ Opción B: Restaurar la Base de Datos desde el Backup (.bak)
Si prefieres iniciar con la base de datos idéntica en datos históricos y configuración a la usada en producción:
1. Localiza el archivo de copia de seguridad en el repositorio:
   👉 `db/inventario_multiplataforma.bak`
2. En **SQL Server Management Studio**, haz clic derecho sobre "Databases" y selecciona **Restore Database...**.
3. Selecciona la opción **Device**, busca el archivo `inventario_multiplataforma.bak` y procede con la restauración.
4. Asegúrate de configurar los permisos del usuario de base de datos correspondiente de acuerdo a tu servidor.

---

## 🖥️ Paso 2: Despliegue del Backend (Node.js REST API)

1. Abre tu terminal de comandos y desplázate al directorio de backend:
   ```bash
   cd backend
   ```
2. Instala todas las dependencias requeridas (Express, CORS, mssql):
   ```bash
   npm install
   ```
3. Configura la conexión a base de datos en `server.js` (línea 10):
   ```javascript
   const dbConfig = {
       user: 'TuUsuarioSQL',
       password: 'TuPasswordSQL',
       database: 'inventario_multiplataforma',
       server: 'localhost',
       options: {
           encrypt: true,
           trustServerCertificate: true
       }
   };
   ```
4. Inicia el servidor de backend en modo desarrollo:
   ```bash
   npm start
   ```
5. El servidor se activará escuchando peticiones en: `http://localhost:3000` y confirmando la conexión exitosa a SQL Server.

---

## 📱 Paso 3: Despliegue del Cliente Móvil (Flutter)

1. Desplázate al directorio raíz del proyecto Flutter:
   ```bash
   cd ..
   ```
2. Descarga y sincroniza las dependencias (Provider, fl_chart, etc.):
   ```bash
   flutter pub get
   ```
3. Verifica la salud y formato sintáctico del código:
   ```bash
   flutter analyze
   ```
4. Conecta tu emulador Android y corre la aplicación en modo desarrollo:
   ```bash
   flutter run
   ```

### 🗝️ Credenciales de Acceso Semilla:
* **Correo:** `admin@inventario.com`
* **Contraseña:** `admin123`

---

## 📑 Características y Módulos Implementados

1. **Dashboard ERP:** Panel de control principal con KPIs totalizados de inventario, actividad transaccional reciente, y métricas dinámicas de movimientos por sucursal.
2. **Catálogo de Productos:** CRUD completo de productos con control de SKUs únicos, categorías, precios de compra/venta, cálculo de márgenes comerciales automáticos, stock y stock mínimo.
3. **Gestión de Almacenes:** Pantalla especializada de administración de bodegas (`WarehousesManagementScreen`) para crear, editar, listar y buscar sucursales físicas.
4. **Control de Flujo de Inventario:**
   * Registro obligatorio de bodega de almacenamiento en todas las **Entradas** y **Salidas** comerciales.
   * Módulo robusto de **Transferencias entre Almacenes** para reubicar existencias sin alterar la valoración global, previniendo stock negativo y auto-transferencias mediante lógica transaccional ACID en el backend.
5. **Kardex Dinámico:** Historial físico-valorado acumulativo de movimientos por producto detallando fecha, tipo, cantidades, precios unitarios, stock resultante y el usuario responsable del registro.
6. **Inventario por Almacén:** Filtro interactivo para auditar el portafolio financiero (`existencias * precio de compra`) de forma independiente en cada sucursal física.
7. **Centro de Reportes Avanzados:** Gráficas circulares e interactivas de stock (`fl_chart`), gráficos de barras para volumen de transacciones, costo promedio e informe de exportación descargable en CSV y PDF con registro transparente de auditorías.
