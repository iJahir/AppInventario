-- =======================================================
-- MASTER DEPLOYMENT SCRIPT - SQL SERVER
-- Base de Datos: [inventario_multiplataforma]
-- ERP & Sistema de Inventario Corporativo
-- =======================================================

-- 1. Crear Base de Datos si no existe
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'inventario_multiplataforma')
BEGIN
    CREATE DATABASE inventario_multiplataforma;
END
GO

USE [inventario_multiplataforma];
GO

-- 2. Tabla de Usuarios
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='users' AND xtype='U')
BEGIN
    CREATE TABLE users (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(100) NOT NULL,
        email NVARCHAR(100) UNIQUE NOT NULL,
        password NVARCHAR(255) NOT NULL,
        role NVARCHAR(50) DEFAULT 'ALMACENERO',
        profile_image_url NVARCHAR(255) NULL
    );
END
GO

-- 3. Tabla de Categorías
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='categories' AND xtype='U')
BEGIN
    CREATE TABLE categories (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(100) NOT NULL UNIQUE
    );
END
GO

-- 4. Tabla de Proveedores
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='suppliers' AND xtype='U')
BEGIN
    CREATE TABLE suppliers (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(150) NOT NULL,
        contact_info NVARCHAR(255) NULL
    );
END
GO

-- 5. Tabla de Clientes
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='customers' AND xtype='U')
BEGIN
    CREATE TABLE customers (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(150) NOT NULL,
        tax_id NVARCHAR(50) NULL
    );
END
GO

-- 6. Tabla de Almacenes (Bodegas)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='warehouses' AND xtype='U')
BEGIN
    CREATE TABLE warehouses (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(100) NOT NULL,
        location NVARCHAR(255) NULL,
        created_at DATETIME DEFAULT GETDATE()
    );
END
GO

-- 7. Tabla de Productos
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='products' AND xtype='U')
BEGIN
    CREATE TABLE products (
        id INT IDENTITY(1,1) PRIMARY KEY,
        sku NVARCHAR(50) UNIQUE NOT NULL,
        name NVARCHAR(100) NOT NULL,
        description NVARCHAR(255) NULL,
        category_id INT NULL FOREIGN KEY REFERENCES categories(id),
        purchase_price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        sale_price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        tax_percentage DECIMAL(5,2) DEFAULT 13.00,
        unit_measure NVARCHAR(50) DEFAULT 'Unidad',
        stock INT NOT NULL DEFAULT 0,
        min_stock INT DEFAULT 0,
        image_url NVARCHAR(255) NULL
    );
END
GO

-- 8. Tabla de Transacciones (Cabecera)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='inventory_transactions' AND xtype='U')
BEGIN
    CREATE TABLE inventory_transactions (
        id INT IDENTITY(1,1) PRIMARY KEY,
        type NVARCHAR(50) NOT NULL,
        warehouse_id INT NOT NULL FOREIGN KEY REFERENCES warehouses(id),
        to_warehouse_id INT NULL FOREIGN KEY REFERENCES warehouses(id), -- Usado solo en TRANSFERENCIA
        supplier_id INT NULL FOREIGN KEY REFERENCES suppliers(id),       -- Usado solo en ENTRADA
        customer_id INT NULL FOREIGN KEY REFERENCES customers(id),       -- Usado solo en SALIDA
        total_amount DECIMAL(18,2) DEFAULT 0.00,
        observations NVARCHAR(255) NULL,
        user_id INT NOT NULL FOREIGN KEY REFERENCES users(id),
        transaction_date DATETIME DEFAULT GETDATE(),
        CONSTRAINT CK_inventory_transactions_type CHECK (type IN ('ENTRADA', 'SALIDA', 'TRANSFERENCIA'))
    );
END
GO

-- 9. Tabla de Lotes de Producto (Para PEPS / FIFO)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='product_lots' AND xtype='U')
BEGIN
    CREATE TABLE product_lots (
        id INT IDENTITY(1,1) PRIMARY KEY,
        product_id BIGINT NOT NULL FOREIGN KEY REFERENCES products(id),
        transaction_id BIGINT NULL FOREIGN KEY REFERENCES inventory_transactions(id),
        warehouse_id BIGINT NOT NULL FOREIGN KEY REFERENCES warehouses(id),
        entry_date DATETIME DEFAULT GETDATE(),
        initial_quantity INT NOT NULL CHECK (initial_quantity >= 0),
        available_quantity INT NOT NULL CHECK (available_quantity >= 0),
        unit_cost DECIMAL(18,2) NOT NULL
    );
END
GO

-- 9.5. Tabla de Detalles de Transacción (Cuerpo) con Relación a Lotes
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='transaction_items' AND xtype='U')
BEGIN
    CREATE TABLE transaction_items (
        id INT IDENTITY(1,1) PRIMARY KEY,
        transaction_id INT NOT NULL FOREIGN KEY REFERENCES inventory_transactions(id) ON DELETE CASCADE,
        product_id INT NOT NULL FOREIGN KEY REFERENCES products(id),
        quantity INT NOT NULL CHECK (quantity > 0),
        unit_price DECIMAL(18,2) NOT NULL,
        lot_id BIGINT NULL FOREIGN KEY REFERENCES product_lots(id),
        subtotal AS (quantity * unit_price)
    );
END
GO


-- 10. Tabla de Auditoría de Reportes
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='report_exports_audit' AND xtype='U')
BEGIN
    CREATE TABLE report_exports_audit (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL FOREIGN KEY REFERENCES users(id),
        report_type VARCHAR(100) NOT NULL,
        export_format VARCHAR(20) NOT NULL,
        exported_at DATETIME DEFAULT GETDATE()
    );
END
GO

-- =======================================================
-- DATOS SEMILLA (Para pruebas de despliegue)
-- =======================================================

-- 1. Insertar Categoría Inicial
IF NOT EXISTS (SELECT * FROM categories WHERE name = 'Electrónica')
BEGIN
    INSERT INTO categories (name) VALUES ('Electrónica'), ('Hogar'), ('Papelería');
END
GO

-- 2. Insertar Administrador
IF NOT EXISTS (SELECT * FROM users WHERE email = 'admin@inventario.com')
BEGIN
    INSERT INTO users (name, email, password, role)
    VALUES ('Administrador ERP', 'admin@inventario.com', 'admin123', 'admin');
END
GO

-- 3. Insertar Almacenes Semilla
IF NOT EXISTS (SELECT * FROM warehouses WHERE name = 'Bodega Central')
BEGIN
    INSERT INTO warehouses (name, location)
    VALUES ('Bodega Central', 'Ciudad Central - Edificio A'),
           ('Sucursal Norte', 'Avenida Norte #404');
END
GO

-- 4. Insertar Proveedores y Clientes Semilla
IF NOT EXISTS (SELECT * FROM suppliers WHERE name = 'Distribuidora Global')
BEGIN
    INSERT INTO suppliers (name, contact_info) VALUES ('Distribuidora Global', 'contacto@global.com');
    INSERT INTO customers (name, tax_id) VALUES ('Cliente General', 'N/D');
END
GO

-- 5. Insertar Productos Semilla
IF NOT EXISTS (SELECT * FROM products WHERE name = 'Teclado Mecánico Pro')
BEGIN
    INSERT INTO products (sku, name, description, category_id, purchase_price, sale_price, tax_percentage, unit_measure, stock, min_stock)
    VALUES 
    ('SKU-TEC-01', 'Teclado Mecánico Pro', 'Teclado mecánico con retroiluminación RGB', 1, 45.00, 89.99, 13.00, 'Unidad', 50, 5),
    ('SKU-MOU-02', 'Mouse Ergonómico', 'Mouse inalámbrico vertical recargable', 1, 20.00, 45.50, 13.00, 'Unidad', 30, 8),
    ('SKU-MON-03', 'Monitor 24" IPS', 'Monitor Full HD para diseño', 1, 110.00, 180.00, 13.00, 'Unidad', 15, 3);
END
GO
