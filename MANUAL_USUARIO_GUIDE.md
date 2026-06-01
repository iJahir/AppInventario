# 📘 Guía de Actualización para el Manual de Usuario — ERP StockMaster

Este documento sirve como guía paso a paso con las descripciones funcionales redactadas y las indicaciones exactas de **qué capturas de pantalla (fotos)** debes tomar en tu teléfono e insertar en tu documento de Word (`manual_usuario.doc`) para dejarlo 100% al día y profesional.

---

## 📸 Sección 1: El Nuevo Panel de Desglose PEPS en Tiempo Real (Nueva Salida)

### 📝 Descripción Funcional para el Manual:
> "La interfaz de **Nueva Salida** de **StockMaster** incorpora un motor predictivo del método PEPS (Primero en Entrar, Primero en Salir / FIFO). Al momento de agregar un producto y digitar la cantidad a vender, el sistema consulta de forma automática la base de datos y presenta al operador una vista previa en tiempo real. Esta vista detalla con precisión matemática qué lotes se verán afectados (indicando número de lote, cantidad fraccionada y costo unitario de adquisición), el costo total estimado de ventas (COGS) y el porcentaje proyectado de ganancia neta. Esto le permite al administrador auditar la salida y conocer la rentabilidad de la transacción antes de confirmarla."

### 🖼️ Indicación de Captura de Pantalla a Colocar en Word:
* **Qué capturar:** Abre la pantalla de **Nueva Salida**, agrega un producto (por ejemplo, los *Audífonos Sony WH-1000XM5* con una cantidad de *12*), y toma captura de pantalla enfocando el recuadro azul/violeta inferior titulado **"Costo PEPS Estimado"**.
* **Título sugerido de la imagen en Word:** `Figura X. Módulo de simulación predictiva y desglose PEPS en tiempo real previo al registro de una salida.`

---

## 📸 Sección 2: Trazabilidad Histórica de Lotes PEPS (Detalle de Movimientos)

### 📝 Descripción Funcional para el Manual:
> "El historial completo de transacciones en **StockMaster** permite realizar una auditoría retrospectiva de inventarios. Al seleccionar cualquier movimiento registrado (Entrada o Salida), se despliega una hoja informativa inferior enriquecida. En esta sección se muestra el bloque de **Trazabilidad PEPS**, donde se detalla:
> 1. En **Entradas**: Los lotes específicos generados por el ingreso de mercadería, indicando fecha de ingreso y costo unitario.
> 2. En **Salidas**: El desglose exacto de qué lotes físicos fueron consumidos para suplir la venta, garantizando una auditoría transparente del movimiento de costos históricos."

### 🖼️ Indicación de Captura de Pantalla a Colocar en Word:
* **Qué capturar:** Ve a la pestaña **Salidas** o **Entradas**, presiona cualquier movimiento de la lista para abrir la hoja de detalles que se desliza desde abajo. Toma captura enfocando la parte inferior que contiene el encabezado **"Trazabilidad PEPS — Consumo por Lote"** donde se listan las tarjetas de los lotes consumidos (`Lote #XX`).
* **Título sugerido de la imagen en Word:** `Figura Y. Detalle transaccional interactivo con desglose de trazabilidad histórica de lotes consumidos.`

---

## 📸 Sección 3: Edición y Eliminación Inline en el Carrito de Movimientos

### 📝 Descripción Funcional para el Manual:
> "Los formularios de **Nueva Entrada** y **Nueva Salida** cuentan con un carrito dinámico de transacciones. Esto permite al operador agregar múltiples productos y realizar modificaciones sobre la marcha antes de consolidar el movimiento en el servidor. El operador puede presionar el botón de **Editar** (ícono de lápiz) sobre cualquier fila para ajustar la cantidad o precio unitario al instante, o bien presionar **Eliminar** (ícono de bote de basura) para remover el ítem del carrito, recalculando los subtotales de forma inmediata y automática sin tener que reiniciar todo el formulario."

### 🖼️ Indicación de Captura de Pantalla a Colocar en Word:
* **Qué capturar:** Abre el formulario de **Nueva Entrada**, agrega 2 o 3 productos a la lista, y toma captura enfocando la fila de productos donde se muestran los botones de acción rápida de edición (lápiz violeta) y eliminación (bote de basura rojo).
* **Título sugerido de la imagen en Word:** `Figura Z. Interfaz de edición rápida y remoción inline de ítems en la lista de preparación de movimientos.`

---

## 📸 Sección 4: Cierre de Sesión Automatizado por Inactividad (Seguridad ERP)

### 📝 Descripción Funcional para el Manual:
> "Para salvaguardar la integridad de los datos comerciales y cumplir con los estándares de seguridad corporativa, **StockMaster** implementa un detector inteligente de inactividad a nivel de aplicación. Si el dispositivo no registra toques, gestos o pulsaciones durante **5 minutos consecutivos**, el ERP finalizará de manera automática la sesión activa del usuario, redirigiéndolo a la pantalla de autenticación y presentando un aviso SweetAlert informativo sobre el cierre preventivo."

### 🖼️ Indicación de Captura de Pantalla a Colocar en Word:
* **Qué capturar:** Deja la aplicación inactiva por 5 minutos hasta que se cierre sola, o simula el cierre por inactividad y toma una captura de la pantalla de **Login** con la alerta interactiva en pantalla que indica: *"Sesión Cerrada: Tu sesión ha expirado debido a inactividad por su seguridad."*
* **Título sugerido de la imagen en Word:** `Figura W. Alerta interactiva preventiva de cierre automático de sesión tras exceder el tiempo límite de inactividad.`
