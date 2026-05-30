const express = require('express');
const cors = require('cors');
const sql = require('mssql');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// CONFIGURACIÓN DE CONEXIÓN A TU SQL SERVER CON TUS CREDENCIALES
const dbConfig = {
    user: 'Inventario_user',
    password: '123456789',
    database: 'inventario_multiplataforma',
    server: 'localhost',
    options: {
        encrypt: true,
        trustServerCertificate: true
    }
};

// Conectar a SQL Server
sql.connect(dbConfig)
    .then(pool => {
        if (pool.connected) {
            console.log('✅ Conectado exitosamente a SQL Server: inventario_multiplataforma');
        }
    })
    .catch(err => {
        console.error('❌ Error de conexión a SQL Server:', err.message);
    });

// ==========================================
// RESPALDOS AUTOMÁTICOS
// ==========================================
const backupDir = 'c:\\Workspace\\Repositorios\\AppInventario\\db\\backups';
if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
}

async function createBackup() {
    try {
        const pool = await sql.connect(dbConfig);
        const dateStr = new Date().toISOString().replace(/[:.]/g, '-');
        const backupPath = path.join(backupDir, `backup_${dateStr}.bak`);
        
        // Ejecutar query de backup en SQL Server
        const query = `BACKUP DATABASE [inventario_multiplataforma] TO DISK = '${backupPath}' WITH FORMAT, INIT, NAME = 'Full Backup de inventario_multiplataforma';`;
        await pool.request().query(query);
        console.log(`✅ Respaldo generado correctamente en: ${backupPath}`);
        return backupPath;
    } catch (err) {
        console.error('❌ Error al generar respaldo:', err.message);
        throw err;
    }
}

// Configurar respaldo automático diario a las 2:00 AM usando setInterval
setInterval(() => {
    const now = new Date();
    if (now.getHours() === 2 && now.getMinutes() === 0) {
        console.log('⏰ Iniciando respaldo automático diario...');
        createBackup().catch(() => {});
    }
}, 60 * 1000);

// Endpoint para forzar respaldo manual
app.post('/api/backup', async (req, res) => {
    try {
        const backupPath = await createBackup();
        res.json({ message: 'Respaldo generado exitosamente.', path: backupPath });
    } catch (err) {
        res.status(500).json({ message: 'Error al generar el respaldo.', error: err.message });
    }
});

// Endpoint para listar todos los respaldos creados
app.get('/api/backups', async (req, res) => {
    try {
        if (!fs.existsSync(backupDir)) {
            return res.json([]);
        }
        const files = fs.readdirSync(backupDir);
        const backups = files.map(file => {
            const filePath = path.join(backupDir, file);
            const stats = fs.statSync(filePath);
            return {
                name: file,
                date: stats.mtime,
                size: stats.size
            };
        });
        // Ordenar por fecha más reciente
        backups.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
        res.json(backups);
    } catch (err) {
        res.status(500).json({ message: 'Error al listar respaldos.', error: err.message });
    }
});

// ==========================================
// ENDPOINTS DE AUTENTICACIÓN
// ==========================================

// Login
app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request()
            .input('email', sql.NVarChar, email)
            .input('password', sql.NVarChar, password)
            .query('SELECT id, name, email, role, profile_image_url FROM users WHERE email = @email AND password = @password');

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            res.json({
                token: `mock_jwt_token_for_user_${user.id}`,
                user: {
                    id: user.id.toString(),
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    profileImageUrl: user.profile_image_url
                }
            });
        } else {
            res.status(401).json({ message: 'Correo o contraseña incorrectos.' });
        }
    } catch (err) {
        res.status(500).json({ message: 'Error en la base de datos.', error: err.message });
    }
});

// Registro
app.post('/api/auth/register', async (req, res) => {
    const { name, email, password } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        
        // Verificar si ya existe
        const checkUser = await pool.request()
            .input('email', sql.NVarChar, email)
            .query('SELECT id FROM users WHERE email = @email');

        if (checkUser.recordset.length > 0) {
            return res.status(400).json({ message: 'El correo electrónico ya está registrado.' });
        }

        // Insertar usuario
        const result = await pool.request()
            .input('name', sql.NVarChar, name)
            .input('email', sql.NVarChar, email)
            .input('password', sql.NVarChar, password)
            .query('INSERT INTO users (name, email, password, role) OUTPUT INSERTED.id, INSERTED.name, INSERTED.email, INSERTED.role VALUES (@name, @email, @password, \'ALMACENERO\')');

        const newUser = result.recordset[0];
        res.json({
            user: {
                id: newUser.id.toString(),
                name: newUser.name,
                email: newUser.email,
                role: newUser.role
            }
        });
    } catch (err) {
        res.status(500).json({ message: 'Error al registrar usuario.', error: err.message });
    }
});

// Actualizar contraseña
app.post('/api/auth/update-password', async (req, res) => {
    const { userId, currentPassword, newPassword } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        
        // Verificar contraseña actual
        const checkUser = await pool.request()
            .input('id', sql.BigInt, parseInt(userId))
            .input('password', sql.NVarChar, currentPassword)
            .query('SELECT id FROM users WHERE id = @id AND password = @password');

        if (checkUser.recordset.length === 0) {
            return res.status(400).json({ message: 'La contraseña actual es incorrecta.' });
        }

        // Actualizar contraseña
        await pool.request()
            .input('id', sql.BigInt, parseInt(userId))
            .input('password', sql.NVarChar, newPassword)
            .query('UPDATE users SET password = @password WHERE id = @id');

        res.json({ message: 'Contraseña actualizada exitosamente.' });
    } catch (err) {
        res.status(500).json({ message: 'Error al actualizar contraseña.', error: err.message });
    }
});

// ==========================================
// ENDPOINTS DE AUXILIARES (Almacenes, Proveedores, Clientes)
// ==========================================

app.get('/api/warehouses', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request().query('SELECT id, name, location, created_at FROM warehouses');
        res.json(result.recordset.map(w => ({ 
            id: w.id.toString(), 
            name: w.name, 
            location: w.location,
            createdAt: w.created_at
        })));
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Crear almacén
app.post('/api/warehouses', async (req, res) => {
    const { name, location } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request()
            .input('name', sql.NVarChar, name)
            .input('location', sql.NVarChar, location || '')
            .query('INSERT INTO warehouses (name, location) OUTPUT INSERTED.id, INSERTED.name, INSERTED.location, INSERTED.created_at VALUES (@name, @location)');
        
        const w = result.recordset[0];
        res.json({
            id: w.id.toString(),
            name: w.name,
            location: w.location,
            createdAt: w.created_at
        });
    } catch (err) {
        res.status(500).json({ message: 'Error al crear almacén.', error: err.message });
    }
});

// Actualizar almacén
app.put('/api/warehouses/:id', async (req, res) => {
    const { id } = req.params;
    const { name, location } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        await pool.request()
            .input('id', sql.BigInt, parseInt(id))
            .input('name', sql.NVarChar, name)
            .input('location', sql.NVarChar, location || '')
            .query('UPDATE warehouses SET name = @name, location = @location WHERE id = @id');
        
        res.json({ message: 'Almacén actualizado exitosamente.' });
    } catch (err) {
        res.status(500).json({ message: 'Error al actualizar almacén.', error: err.message });
    }
});

// Eliminar almacén
app.delete('/api/warehouses/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await sql.connect(dbConfig);
        await pool.request()
            .input('id', sql.BigInt, parseInt(id))
            .query('DELETE FROM warehouses WHERE id = @id');
            
        res.json({ message: 'Almacén eliminado exitosamente.' });
    } catch (err) {
        res.status(500).json({ message: 'Error al eliminar almacén.', error: err.message });
    }
});

// Obtener inventario detallado de un almacén específico
app.get('/api/warehouses/:id/inventory', async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await sql.connect(dbConfig);
        
        const query = `
            SELECT 
                p.id,
                p.sku,
                p.name,
                p.description,
                p.purchase_price AS purchasePrice,
                p.sale_price AS price,
                p.tax_percentage AS taxPercentage,
                p.unit_measure AS unitMeasure,
                p.min_stock AS minStock,
                p.image_url AS imageUrl,
                c.name AS category,
                COALESCE(
                    (SELECT SUM(
                        CASE 
                            WHEN tx.type = 'ENTRADA' THEN item.quantity
                            WHEN tx.type = 'SALIDA' THEN -item.quantity
                            WHEN tx.type = 'TRANSFERENCIA' AND tx.warehouse_id = @warehouseId THEN -item.quantity
                            WHEN tx.type = 'TRANSFERENCIA' AND tx.to_warehouse_id = @warehouseId THEN item.quantity
                            ELSE 0 
                        END)
                     FROM transaction_items item
                     INNER JOIN inventory_transactions tx ON item.transaction_id = tx.id
                     WHERE item.product_id = p.id AND (tx.warehouse_id = @warehouseId OR tx.to_warehouse_id = @warehouseId)), 
                    0
                ) AS stock
            FROM products p
            LEFT JOIN categories c ON p.category_id = c.id
        `;
        
        const result = await pool.request()
            .input('warehouseId', sql.BigInt, parseInt(id))
            .query(query);
            
        const products = result.recordset.map(p => ({
            id: p.id.toString(),
            sku: p.sku,
            name: p.name,
            description: p.description,
            price: parseFloat(p.price),
            purchasePrice: p.purchasePrice != null ? parseFloat(p.purchasePrice) : 0.0,
            taxPercentage: p.taxPercentage != null ? parseFloat(p.taxPercentage) : 0.0,
            stock: parseInt(p.stock),
            minStock: p.minStock != null ? parseInt(p.minStock) : 0,
            category: p.category || 'General',
            imageUrl: p.imageUrl,
            unitMeasure: p.unitMeasure || 'Unidad'
        }));
        
        res.json(products);
    } catch (err) {
        res.status(500).json({ message: 'Error al obtener inventario del almacén.', error: err.message });
    }
});


app.get('/api/suppliers', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request().query('SELECT id, name, contact_info FROM suppliers');
        res.json(result.recordset.map(s => ({ id: s.id.toString(), name: s.name, contactInfo: s.contact_info })));
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Crear proveedor
app.post('/api/suppliers', async (req, res) => {
    const { name, contactInfo } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request()
            .input('name', sql.NVarChar, name)
            .input('contactInfo', sql.NVarChar, contactInfo || '')
            .query('INSERT INTO suppliers (name, contact_info) OUTPUT INSERTED.id, INSERTED.name, INSERTED.contact_info VALUES (@name, @contactInfo)');
        
        const s = result.recordset[0];
        res.json({
            id: s.id.toString(),
            name: s.name,
            contactInfo: s.contact_info
        });
    } catch (err) {
        res.status(500).json({ message: 'Error al crear proveedor.', error: err.message });
    }
});

// Actualizar proveedor
app.put('/api/suppliers/:id', async (req, res) => {
    const { id } = req.params;
    const { name, contactInfo } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        await pool.request()
            .input('id', sql.BigInt, parseInt(id))
            .input('name', sql.NVarChar, name)
            .input('contactInfo', sql.NVarChar, contactInfo || '')
            .query('UPDATE suppliers SET name = @name, contact_info = @contactInfo WHERE id = @id');
        
        res.json({ message: 'Proveedor actualizado exitosamente.' });
    } catch (err) {
        res.status(500).json({ message: 'Error al actualizar proveedor.', error: err.message });
    }
});

// Eliminar proveedor
app.delete('/api/suppliers/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await sql.connect(dbConfig);
        await pool.request()
            .input('id', sql.BigInt, parseInt(id))
            .query('DELETE FROM suppliers WHERE id = @id');
            
        res.json({ message: 'Proveedor eliminado exitosamente.' });
    } catch (err) {
        res.status(500).json({ message: 'Error al eliminar proveedor.', error: err.message });
    }
});


app.get('/api/customers', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request().query('SELECT id, name, tax_id FROM customers');
        res.json(result.recordset.map(c => ({ id: c.id.toString(), name: c.name, taxId: c.tax_id })));
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// ==========================================
// ENDPOINTS DE PRODUCTOS (CRUD)
// ==========================================

// Obtener todos los productos
app.get('/api/products', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        const query = `
            SELECT 
                p.id, 
                p.sku,
                p.name, 
                p.description, 
                p.purchase_price, 
                p.sale_price, 
                p.tax_percentage, 
                p.unit_measure, 
                p.stock, 
                p.min_stock,
                p.image_url,
                c.name AS category
            FROM products p
            LEFT JOIN categories c ON p.category_id = c.id
        `;
        const result = await pool.request().query(query);
        
        const products = result.recordset.map(p => ({
            id: p.id.toString(),
            sku: p.sku,
            name: p.name,
            description: p.description,
            price: parseFloat(p.sale_price),
            purchasePrice: p.purchase_price != null ? parseFloat(p.purchase_price) : 0.0,
            taxPercentage: p.tax_percentage != null ? parseFloat(p.tax_percentage) : 0.0,
            stock: parseInt(p.stock),
            minStock: p.min_stock != null ? parseInt(p.min_stock) : 0,
            category: p.category || 'General',
            imageUrl: p.image_url,
            unitMeasure: p.unit_measure || 'Unidad'
        }));
        
        res.json(products);
    } catch (err) {
        res.status(500).json({ message: 'Error al obtener productos.', error: err.message });
    }
});

// Crear producto
app.post('/api/products', async (req, res) => {
    const { name, description, price, stock, category, sku, purchasePrice, taxPercentage, minStock, unitMeasure } = req.body;
    try {
        const pool = await sql.connect(dbConfig);

        const finalSku = sku || `PROD-${Date.now().toString().slice(-6)}`;
        
        let categoryId = 1;
        if (category) {
            const catResult = await pool.request()
                .input('catName', sql.NVarChar, category)
                .query('SELECT id FROM categories WHERE name = @catName');
            
            if (catResult.recordset.length > 0) {
                categoryId = catResult.recordset[0].id;
            } else {
                const newCat = await pool.request()
                    .input('catName', sql.NVarChar, category)
                    .query('INSERT INTO categories (name) OUTPUT INSERTED.id VALUES (@catName)');
                categoryId = newCat.recordset[0].id;
            }
        }

        const query = `
            INSERT INTO products (
                sku, name, description, category_id, purchase_price, sale_price, 
                tax_percentage, unit_measure, stock, min_stock
            ) 
            OUTPUT 
                INSERTED.id, INSERTED.sku, INSERTED.name, INSERTED.description, 
                INSERTED.purchase_price, INSERTED.sale_price, INSERTED.tax_percentage, 
                INSERTED.unit_measure, INSERTED.stock, INSERTED.min_stock
            VALUES (
                @sku, @name, @description, @categoryId, @purchasePrice, @salePrice, 
                @taxPercentage, @unitMeasure, @stock, @minStock
            )
        `;

        const result = await pool.request()
            .input('sku', sql.NVarChar, finalSku)
            .input('name', sql.NVarChar, name)
            .input('description', sql.NVarChar, description || '')
            .input('categoryId', sql.BigInt, categoryId)
            .input('purchasePrice', sql.Decimal(18, 2), purchasePrice !== undefined ? purchasePrice : ((price * 0.7) || 0.0))
            .input('salePrice', sql.Decimal(18, 2), price || 0.0)
            .input('taxPercentage', sql.Decimal(5, 2), taxPercentage !== undefined ? taxPercentage : 13.0)
            .input('unitMeasure', sql.NVarChar, unitMeasure || 'Unidad')
            .input('stock', sql.Int, stock || 0)
            .input('minStock', sql.Int, minStock !== undefined ? minStock : 0)
            .query(query);

        const p = result.recordset[0];
        res.json({
            id: p.id.toString(),
            sku: p.sku,
            name: p.name,
            description: p.description,
            price: parseFloat(p.sale_price),
            purchasePrice: p.purchase_price != null ? parseFloat(p.purchase_price) : 0.0,
            taxPercentage: p.tax_percentage != null ? parseFloat(p.tax_percentage) : 0.0,
            stock: parseInt(p.stock),
            minStock: p.min_stock != null ? parseInt(p.min_stock) : 0,
            category: category || 'General',
            imageUrl: p.image_url,
            unitMeasure: p.unit_measure || 'Unidad'
        });
    } catch (err) {
        res.status(500).json({ message: 'Error al crear producto.', error: err.message });
    }
});

// Eliminar producto
app.delete('/api/products/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await sql.connect(dbConfig);
        await pool.request()
            .input('id', sql.BigInt, parseInt(id))
            .query('DELETE FROM products WHERE id = @id');
            
        res.json({ message: 'Producto eliminado exitosamente.' });
    } catch (err) {
        res.status(500).json({ message: 'Error al eliminar producto.', error: err.message });
    }
});

// Obtener Kardex de un producto (Historial físico-valorado acumulativo)
app.get('/api/products/:id/kardex', async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await sql.connect(dbConfig);
        
        const query = `
            SELECT 
                t.transaction_date AS date,
                t.type AS type,
                i.quantity AS quantity,
                i.unit_price AS unitPrice,
                u.name AS userName,
                t.observations AS observations,
                w1.name AS originWarehouseName,
                w2.name AS destinationWarehouseName
            FROM transaction_items i
            INNER JOIN inventory_transactions t ON i.transaction_id = t.id
            INNER JOIN users u ON t.user_id = u.id
            LEFT JOIN warehouses w1 ON t.warehouse_id = w1.id
            LEFT JOIN warehouses w2 ON t.to_warehouse_id = w2.id
            WHERE i.product_id = @productId
            ORDER BY t.transaction_date ASC
        `;
        
        const result = await pool.request()
            .input('productId', sql.BigInt, parseInt(id))
            .query(query);
            
        let runningStock = 0;
        const kardex = result.recordset.map(item => {
            const qty = parseInt(item.quantity);
            if (item.type === 'ENTRADA') {
                runningStock += qty;
            } else if (item.type === 'SALIDA') {
                runningStock -= qty;
            }
            
            return {
                date: item.date,
                type: item.type,
                quantity: qty,
                unitPrice: parseFloat(item.unitPrice),
                runningStock: runningStock,
                userName: item.userName,
                observations: item.observations || '',
                originWarehouseName: item.originWarehouseName || null,
                destinationWarehouseName: item.destinationWarehouseName || null
            };
        });
        
        res.json(kardex);
    } catch (err) {
        res.status(500).json({ message: 'Error al obtener Kardex del producto.', error: err.message });
    }
});

// ==========================================
// ENDPOINTS DE TRANSACCIONES DE INVENTARIO (Entradas y Salidas)
// ==========================================

// Obtener todas las transacciones e items
app.get('/api/transactions', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        
        const txQuery = `
            SELECT 
                t.id, t.type, t.transaction_date, t.total_amount, t.observations,
                w.name AS warehouse_name,
                s.name AS supplier_name,
                c.name AS customer_name,
                u.name AS user_name
            FROM inventory_transactions t
            INNER JOIN warehouses w ON t.warehouse_id = w.id
            LEFT JOIN suppliers s ON t.supplier_id = s.id
            LEFT JOIN customers c ON t.customer_id = c.id
            INNER JOIN users u ON t.user_id = u.id
            ORDER BY t.transaction_date DESC
        `;
        const txResult = await pool.request().query(txQuery);
        
        const transactions = [];
        for (let tx of txResult.recordset) {
            const itemsQuery = `
                SELECT 
                    i.id, i.quantity, i.unit_price, i.subtotal,
                    p.name AS product_name, p.sku AS product_sku
                FROM transaction_items i
                INNER JOIN products p ON i.product_id = p.id
                WHERE i.transaction_id = @txId
            `;
            const itemsResult = await pool.request()
                .input('txId', sql.BigInt, tx.id)
                .query(itemsQuery);
                
            transactions.push({
                id: tx.id.toString(),
                type: tx.type,
                transactionDate: tx.transaction_date,
                totalAmount: parseFloat(tx.total_amount),
                observations: tx.observations,
                warehouseName: tx.warehouse_name,
                supplierName: tx.supplier_name || 'Consumo Interno',
                customerName: tx.customer_name || 'General',
                userName: tx.user_name,
                items: itemsResult.recordset.map(i => ({
                    id: i.id.toString(),
                    productName: i.product_name,
                    productSku: i.product_sku,
                    quantity: parseInt(i.quantity),
                    unitPrice: parseFloat(i.unit_price),
                    subtotal: parseFloat(i.subtotal)
                }))
            });
        }
        
        res.json(transactions);
    } catch (err) {
        res.status(500).json({ message: 'Error al obtener transacciones.', error: err.message });
    }
});

// Registrar nueva Transacción (Entrada/Salida) y actualizar Stock (ACID Transaccional)
app.post('/api/transactions', async (req, res) => {
    const { type, warehouseId, supplierId, customerId, observations, items, userId } = req.body;
    
    if (!items || items.length === 0) {
        return res.status(400).json({ message: 'Debe agregar al menos un producto a la transacción.' });
    }

    const pool = await sql.connect(dbConfig);
    const transaction = new sql.Transaction(pool);

    try {
        await transaction.begin();

        // 1. Calcular total_amount
        const totalAmount = items.reduce((sum, item) => sum + (item.quantity * item.unitPrice), 0);

        // 2. Insertar en inventory_transactions
        const txInsertQuery = `
            INSERT INTO inventory_transactions (
                type, warehouse_id, supplier_id, customer_id, total_amount, observations, user_id
            )
            OUTPUT INSERTED.id
            VALUES (
                @type, @warehouseId, @supplierId, @customerId, @totalAmount, @observations, @userId
            )
        `;

        const txRequest = new sql.Request(transaction);
        const txResult = await txRequest
            .input('type', sql.NVarChar, type)
            .input('warehouseId', sql.BigInt, parseInt(warehouseId))
            .input('supplierId', sql.BigInt, supplierId ? parseInt(supplierId) : null)
            .input('customerId', sql.BigInt, customerId ? parseInt(customerId) : null)
            .input('totalAmount', sql.Decimal(18, 2), totalAmount)
            .input('observations', sql.NVarChar, observations || '')
            .input('userId', sql.BigInt, userId ? parseInt(userId) : 1) // default admin
            .query(txInsertQuery);

        const transactionId = txResult.recordset[0].id;

        // 3. Insertar Items y actualizar Stock de cada producto
        for (let item of items) {
            const itemRequest = new sql.Request(transaction);
            
            // Insertar item
            await itemRequest
                .input('txId', sql.BigInt, transactionId)
                .input('productId', sql.BigInt, parseInt(item.productId))
                .input('quantity', sql.Int, parseInt(item.quantity))
                .input('unitPrice', sql.Decimal(18, 2), parseFloat(item.unitPrice))
                .query('INSERT INTO transaction_items (transaction_id, product_id, quantity, unit_price) VALUES (@txId, @productId, @quantity, @unitPrice)');

            // Actualizar stock del producto
            const stockRequest = new sql.Request(transaction);
            const stockOperator = type === 'ENTRADA' ? '+' : '-';
            
            await stockRequest
                .input('productId', sql.BigInt, parseInt(item.productId))
                .input('quantity', sql.Int, parseInt(item.quantity))
                .query(`UPDATE products SET stock = stock ${stockOperator} @quantity WHERE id = @productId`);
        }

        await transaction.commit();
        res.json({ message: 'Transacción registrada con éxito.', transactionId: transactionId.toString() });

    } catch (err) {
        await transaction.rollback();
        console.error('Error en transacción de stock:', err);
        res.status(500).json({ message: 'Error procesando la transacción de inventario.', error: err.message });
    }
});

// ==========================================
// ENDPOINTS DE TRANSFERENCIAS ENTRE ALMACENES
// ==========================================

// Obtener historial de transferencias
app.get('/api/transfers', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        const txQuery = `
            SELECT 
                t.id, t.transaction_date, t.total_amount, t.observations,
                w1.name AS origin_name,
                w2.name AS destination_name,
                u.name AS user_name
            FROM inventory_transactions t
            INNER JOIN warehouses w1 ON t.warehouse_id = w1.id
            INNER JOIN warehouses w2 ON t.to_warehouse_id = w2.id
            INNER JOIN users u ON t.user_id = u.id
            WHERE t.type = 'TRANSFERENCIA'
            ORDER BY t.transaction_date DESC
        `;
        const txResult = await pool.request().query(txQuery);
        
        const transfers = [];
        for (let tx of txResult.recordset) {
            const itemsQuery = `
                SELECT 
                    i.id, i.quantity, i.unit_price, i.subtotal,
                    p.name AS product_name, p.sku AS product_sku
                FROM transaction_items i
                INNER JOIN products p ON i.product_id = p.id
                WHERE i.transaction_id = @txId
            `;
            const itemsResult = await pool.request()
                .input('txId', sql.BigInt, tx.id)
                .query(itemsQuery);
                
            transfers.push({
                id: tx.id.toString(),
                transactionDate: tx.transaction_date,
                totalAmount: parseFloat(tx.total_amount),
                observations: tx.observations,
                originWarehouseName: tx.origin_name,
                destinationWarehouseName: tx.destination_name,
                userName: tx.user_name,
                items: itemsResult.recordset.map(i => ({
                    id: i.id.toString(),
                    productName: i.product_name,
                    productSku: i.product_sku,
                    quantity: parseInt(i.quantity),
                    unitPrice: parseFloat(i.unit_price),
                    subtotal: parseFloat(i.subtotal)
                }))
            });
        }
        res.json(transfers);
    } catch (err) {
        res.status(500).json({ message: 'Error al obtener transferencias.', error: err.message });
    }
});

// Registrar nueva transferencia (Validación de Stock + ACID)
app.post('/api/transfers', async (req, res) => {
    const { fromWarehouseId, toWarehouseId, observations, items, userId } = req.body;
    
    if (parseInt(fromWarehouseId) === parseInt(toWarehouseId)) {
        return res.status(400).json({ message: 'El almacén de origen y destino no pueden ser el mismo.' });
    }
    if (!items || items.length === 0) {
        return res.status(400).json({ message: 'Debe agregar al menos un producto a la transferencia.' });
    }

    const pool = await sql.connect(dbConfig);

    // VALIDACIÓN DE STOCK PREVIA EN ORIGEN
    try {
        for (let item of items) {
            const stockQuery = `
                SELECT COALESCE(
                    (SELECT SUM(
                        CASE 
                            WHEN tx.type = 'ENTRADA' THEN it.quantity
                            WHEN tx.type = 'SALIDA' THEN -it.quantity
                            WHEN tx.type = 'TRANSFERENCIA' AND tx.warehouse_id = @warehouseId THEN -it.quantity
                            WHEN tx.type = 'TRANSFERENCIA' AND tx.to_warehouse_id = @warehouseId THEN it.quantity
                            ELSE 0 
                        END)
                     FROM transaction_items it
                     INNER JOIN inventory_transactions tx ON it.transaction_id = tx.id
                     WHERE it.product_id = @productId AND (tx.warehouse_id = @warehouseId OR tx.to_warehouse_id = @warehouseId)), 
                    0
                ) AS stock
            `;
            const stockResult = await pool.request()
                .input('productId', sql.BigInt, parseInt(item.productId))
                .input('warehouseId', sql.BigInt, parseInt(fromWarehouseId))
                .query(stockQuery);
                
            const availableStock = stockResult.recordset[0] ? parseInt(stockResult.recordset[0].stock) : 0;
            if (parseInt(item.quantity) > availableStock) {
                const pInfo = await pool.request()
                    .input('id', sql.BigInt, parseInt(item.productId))
                    .query('SELECT name FROM products WHERE id = @id');
                const pName = pInfo.recordset[0] ? pInfo.recordset[0].name : `ID: ${item.productId}`;
                return res.status(400).json({ 
                    message: `Stock insuficiente para ${pName} en el almacén de origen. Disponible: ${availableStock}, Solicitado: ${item.quantity}` 
                });
            }
        }
    } catch (err) {
        return res.status(500).json({ message: 'Error validando disponibilidad de inventario.', error: err.message });
    }

    const transaction = new sql.Transaction(pool);
    try {
        await transaction.begin();

        // Calcular total de valoración de la transferencia
        const totalAmount = items.reduce((sum, item) => sum + (item.quantity * item.unitPrice), 0);

        // Registrar en inventory_transactions
        const txInsertQuery = `
            INSERT INTO inventory_transactions (
                type, warehouse_id, to_warehouse_id, total_amount, observations, user_id
            )
            OUTPUT INSERTED.id
            VALUES (
                'TRANSFERENCIA', @fromWarehouseId, @toWarehouseId, @totalAmount, @observations, @userId
            )
        `;

        const txRequest = new sql.Request(transaction);
        const txResult = await txRequest
            .input('fromWarehouseId', sql.BigInt, parseInt(fromWarehouseId))
            .input('toWarehouseId', sql.BigInt, parseInt(toWarehouseId))
            .input('totalAmount', sql.Decimal(18, 2), totalAmount)
            .input('observations', sql.NVarChar, observations || '')
            .input('userId', sql.BigInt, userId ? parseInt(userId) : 1)
            .query(txInsertQuery);

        const transactionId = txResult.recordset[0].id;

        // Insertar items de la transferencia
        for (let item of items) {
            const itemRequest = new sql.Request(transaction);
            await itemRequest
                .input('txId', sql.BigInt, transactionId)
                .input('productId', sql.BigInt, parseInt(item.productId))
                .input('quantity', sql.Int, parseInt(item.quantity))
                .input('unitPrice', sql.Decimal(18, 2), parseFloat(item.unitPrice))
                .query('INSERT INTO transaction_items (transaction_id, product_id, quantity, unit_price) VALUES (@txId, @productId, @quantity, @unitPrice)');
        }

        await transaction.commit();
        res.json({ message: 'Transferencia registrada con éxito.', transactionId: transactionId.toString() });

    } catch (err) {
        await transaction.rollback();
        console.error('Error registrando transferencia:', err);
        res.status(500).json({ message: 'Error procesando la transferencia de inventario.', error: err.message });
    }
});

// ==========================================
// ENDPOINTS DE REPORTES AVANZADOS
// ==========================================

// Obtener resumen analítico completo
app.get('/api/reports/summary', async (req, res) => {
    const { startDate, endDate } = req.query;
    
    // Configurar fechas por defecto si no vienen
    const start = startDate ? new Date(startDate) : new Date(new Date().setDate(new Date().getDate() - 30));
    const end = endDate ? new Date(endDate) : new Date();

    try {
        const pool = await sql.connect(dbConfig);

        // 1. Resumen Ejecutivo
        const execSummaryQuery = `
            SELECT 
                (SELECT SUM(stock * COALESCE(purchase_price, sale_price * 0.7)) FROM products) AS totalInventoryValue,
                (SELECT COUNT(id) FROM products) AS totalProducts,
                (SELECT COUNT(id) FROM warehouses) AS totalWarehouses,
                (SELECT COUNT(id) FROM suppliers) AS totalSuppliers,
                (SELECT COUNT(id) FROM inventory_transactions WHERE transaction_date BETWEEN @start AND @end) AS totalMovements
        `;
        const execSummaryRes = await pool.request()
            .input('start', sql.DateTime, start)
            .input('end', sql.DateTime, end)
            .query(execSummaryQuery);
        
        const execSummary = execSummaryRes.recordset[0] || {
            totalInventoryValue: 0.0,
            totalProducts: 0,
            totalWarehouses: 0,
            totalSuppliers: 0,
            totalMovements: 0
        };

        // 2. Estado de Inventario (Distribución por existencias)
        const stockDistributionQuery = `
            SELECT 
                SUM(CASE WHEN stock = 0 THEN 1 ELSE 0 END) AS agotado,
                SUM(CASE WHEN stock > 0 AND stock <= (COALESCE(min_stock, 0) * 0.5) THEN 1 ELSE 0 END) AS critico,
                SUM(CASE WHEN stock > (COALESCE(min_stock, 0) * 0.5) AND stock <= COALESCE(min_stock, 0) THEN 1 ELSE 0 END) AS bajo,
                SUM(CASE WHEN stock > COALESCE(min_stock, 0) THEN 1 ELSE 0 END) AS normal
            FROM products
        `;
        const stockDistributionRes = await pool.request().query(stockDistributionQuery);
        const stockDistribution = stockDistributionRes.recordset[0] || { agotado: 0, critico: 0, bajo: 0, normal: 0 };

        // 3. Volumen de Movimientos por Tipo
        const movementsVolumeQuery = `
            SELECT type, COUNT(id) AS count
            FROM inventory_transactions
            WHERE transaction_date BETWEEN @start AND @end
            GROUP BY type
        `;
        const movementsVolumeRes = await pool.request()
            .input('start', sql.DateTime, start)
            .input('end', sql.DateTime, end)
            .query(movementsVolumeQuery);
        
        const movementsVolume = { ENTRADA: 0, SALIDA: 0, TRANSFERENCIA: 0 };
        movementsVolumeRes.recordset.forEach(row => {
            if (movementsVolume[row.type] !== undefined) {
                movementsVolume[row.type] = row.count;
            }
        });

        // 4. Productos Métricas (Tops)
        // A. Mayor Valor Almacenado
        const valProductsQuery = `
            SELECT TOP 5 name, sku, (stock * COALESCE(purchase_price, sale_price * 0.7)) AS value
            FROM products
            ORDER BY value DESC
        `;
        const valProductsRes = await pool.request().query(valProductsQuery);

        // B. Más Movidos
        const mostMovedQuery = `
            SELECT TOP 5 p.name, p.sku, SUM(it.quantity) AS qty
            FROM transaction_items it
            INNER JOIN products p ON it.product_id = p.id
            INNER JOIN inventory_transactions tx ON it.transaction_id = tx.id
            WHERE tx.transaction_date BETWEEN @start AND @end
            GROUP BY p.name, p.sku
            ORDER BY qty DESC
        `;
        const mostMovedRes = await pool.request()
            .input('start', sql.DateTime, start)
            .input('end', sql.DateTime, end)
            .query(mostMovedQuery);

        // C. Menos Movidos
        const leastMovedQuery = `
            SELECT TOP 5 p.name, p.sku, SUM(it.quantity) AS qty
            FROM transaction_items it
            INNER JOIN products p ON it.product_id = p.id
            INNER JOIN inventory_transactions tx ON it.transaction_id = tx.id
            WHERE tx.transaction_date BETWEEN @start AND @end
            GROUP BY p.name, p.sku
            ORDER BY qty ASC
        `;
        const leastMovedRes = await pool.request()
            .input('start', sql.DateTime, start)
            .input('end', sql.DateTime, end)
            .query(leastMovedQuery);

        // D. Sin Movimiento
        const noMovedQuery = `
            SELECT TOP 5 name, sku 
            FROM products 
            WHERE id NOT IN (
                SELECT DISTINCT product_id 
                FROM transaction_items it
                INNER JOIN inventory_transactions tx ON it.transaction_id = tx.id
                WHERE tx.transaction_date BETWEEN @start AND @end
            )
        `;
        const noMovedRes = await pool.request()
            .input('start', sql.DateTime, start)
            .input('end', sql.DateTime, end)
            .query(noMovedQuery);

        const productMetrics = {
            highestValued: valProductsRes.recordset,
            mostMoved: mostMovedRes.recordset,
            leastMoved: leastMovedRes.recordset,
            noMovement: noMovedRes.recordset
        };

        // 5. Análisis Financiero
        // A. Costo Promedio
        const avgCostRes = await pool.request().query('SELECT AVG(COALESCE(purchase_price, sale_price * 0.7)) AS avgCost FROM products');
        const avgCost = avgCostRes.recordset[0] ? parseFloat(avgCostRes.recordset[0].avgCost || 0.0) : 0.0;

        // B. Valor por Categoría
        const valueByCategoryQuery = `
            SELECT c.name AS category, SUM(p.stock * COALESCE(p.purchase_price, p.sale_price * 0.7)) AS value
            FROM products p
            LEFT JOIN categories c ON p.category_id = c.id
            GROUP BY c.name
        `;
        const valueByCategoryRes = await pool.request().query(valueByCategoryQuery);

        const financialAnalysis = {
            averageCost: avgCost,
            valueByCategory: valueByCategoryRes.recordset.map(row => ({
                category: row.category || 'General',
                value: parseFloat(row.value || 0.0)
            }))
        };

        // Responder consolidado
        res.json({
            executiveSummary: {
                totalInventoryValue: parseFloat(execSummary.totalInventoryValue || 0.0),
                totalProducts: parseInt(execSummary.totalProducts || 0),
                totalWarehouses: parseInt(execSummary.totalWarehouses || 0),
                totalSuppliers: parseInt(execSummary.totalSuppliers || 0),
                totalMovements: parseInt(execSummary.totalMovements || 0)
            },
            stockDistribution: {
                agotado: parseInt(stockDistribution.agotado || 0),
                critico: parseInt(stockDistribution.critico || 0),
                bajo: parseInt(stockDistribution.bajo || 0),
                normal: parseInt(stockDistribution.normal || 0)
            },
            movementsVolume,
            productMetrics,
            financialAnalysis
        });

    } catch (err) {
        console.error('Error generando resumen de reportes:', err);
        res.status(500).json({ message: 'Error procesando estadísticas de reportes.', error: err.message });
    }
});

// Registrar auditoría de exportación
app.post('/api/reports/audit', async (req, res) => {
    const { userId, reportType, exportFormat } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        await pool.request()
            .input('userId', sql.BigInt, userId ? parseInt(userId) : 1)
            .input('reportType', sql.VarChar, reportType)
            .input('exportFormat', sql.VarChar, exportFormat)
            .query('INSERT INTO report_exports_audit (user_id, report_type, export_format) VALUES (@userId, @reportType, @exportFormat)');
        
        res.json({ message: 'Auditoría registrada con éxito.' });
    } catch (err) {
        res.status(500).json({ message: 'Error registrando auditoría de reportes.', error: err.message });
    }
});

// Iniciar servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 API REST adaptada y lista en http://localhost:${PORT}`);
    console.log(`🔗 Usando el esquema oficial de base de datos SQL Server: inventario_multiplataforma`);
});
