const express = require('express');
const cors = require('cors');
const sql = require('mssql');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');

const app = express();
app.use(cors());
app.use(express.json());

// Servir la carpeta de imágenes del inventario para que la app pueda acceder a ellas por red
app.use('/api/uploads', express.static('C:\\Users\\aldo1\\Documents\\InventarioAPP'));

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
    .then(async (pool) => {
        if (pool.connected) {
            console.log('✅ Conectado exitosamente a SQL Server: inventario_multiplataforma');

            // Verificar y agregar columna 'username' a la tabla 'users' si no existe, y migrar contraseñas viejas
            try {
                await pool.request().query(`
                    IF NOT EXISTS (
                        SELECT * FROM sys.columns 
                        WHERE object_id = OBJECT_ID('users') AND name = 'username'
                    )
                    BEGIN
                        ALTER TABLE users ADD username NVARCHAR(100) NULL;
                    END
                `);
                console.log('✅ Columna "username" verificada/creada exitosamente en la tabla "users".');

                // Asignar username por defecto a usuarios existentes que lo tengan NULL
                await pool.request().query(`
                    UPDATE users 
                    SET username = SUBSTRING(email, 1, CHARINDEX('@', email) - 1) 
                    WHERE username IS NULL AND email LIKE '%@%';
                `);

                // Encriptar contraseñas antiguas de texto plano
                const usersResult = await pool.request().query('SELECT id, password FROM users');
                for (const u of usersResult.recordset) {
                    const pw = u.password;
                    if (pw && !pw.startsWith('$2a$') && !pw.startsWith('$2b$')) {
                        const hash = bcrypt.hashSync(pw, 10);
                        await pool.request()
                            .input('id', sql.BigInt, u.id)
                            .input('hash', sql.NVarChar, hash)
                            .query('UPDATE users SET password = @hash WHERE id = @id');
                        console.log(`🔐 Contraseña migrada y encriptada con bcryptjs para el usuario ID ${u.id}`);
                    }
                }
            } catch (dbErr) {
                console.error('⚠️ Advertencia en migración de usuarios:', dbErr.message);
            }

            // Verificar y agregar columna 'reason' si no existe, y crear tabla 'product_lots' para PEPS
            try {
                await pool.request().query(`
                    IF NOT EXISTS (
                        SELECT * FROM sys.columns 
                        WHERE object_id = OBJECT_ID('inventory_transactions') AND name = 'reason'
                    )
                    BEGIN
                        ALTER TABLE inventory_transactions ADD reason NVARCHAR(100) NULL DEFAULT 'Venta';
                    END
                `);
                console.log('✅ Columna "reason" verificada/creada exitosamente en la BD.');

                await pool.request().query(`
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

                        -- Poblar lotes iniciales para stock existente de modo que sean compatibles con PEPS
                        INSERT INTO product_lots (product_id, transaction_id, warehouse_id, entry_date, initial_quantity, available_quantity, unit_cost)
                        SELECT 
                            p.id, 
                            NULL, 
                            COALESCE((SELECT TOP 1 id FROM warehouses ORDER BY id ASC), 1),
                            GETDATE(), 
                            p.stock, 
                            p.stock, 
                            p.purchase_price
                        FROM products p
                        WHERE p.stock > 0;
                    END
                `);
                console.log('✅ Tabla "product_lots" de PEPS/FIFO verificada/creada exitosamente en la BD.');

                // Verificar y crear columna 'lot_id' en 'transaction_items' para traza PEPS
                await pool.request().query(`
                    IF NOT EXISTS (
                        SELECT * FROM sys.columns 
                        WHERE object_id = OBJECT_ID('transaction_items') AND name = 'lot_id'
                    )
                    BEGIN
                        ALTER TABLE transaction_items ADD lot_id BIGINT NULL FOREIGN KEY REFERENCES product_lots(id);
                    END
                `);
                console.log('✅ Columna "lot_id" en "transaction_items" verificada/creada exitosamente en la BD.');
            } catch (dbErr) {
                console.error('⚠️ Advertencia en inicialización de base de datos:', dbErr.message);
            }
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
        createBackup().catch(() => { });
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

// Helper para enviar correo de recuperación con nodemailer
async function sendRecoveryEmail(toEmail, userName, tempPassword) {
    let transporter;
    try {
        // Intentar crear cuenta de prueba en ethereal si no hay variables de entorno predefinidas
        const testAccount = await nodemailer.createTestAccount();
        transporter = nodemailer.createTransport({
            host: 'smtp.ethereal.email',
            port: 587,
            secure: false,
            auth: {
                user: testAccount.user,
                pass: testAccount.pass
            }
        });
    } catch (e) {
        // Fallback a transporter por defecto
        transporter = nodemailer.createTransport({
            host: 'smtp.ethereal.email',
            port: 587,
            secure: false,
            auth: {
                user: 'elizabeth.cummings71@ethereal.email',
                pass: 'GZgYQ7aG5yS9vF19f7'
            }
        });
    }

    const info = await transporter.sendMail({
        from: '"Sistema de Inventario" <soporte@inventarioapp.com>',
        to: toEmail,
        subject: 'Restablecimiento de Contraseña - Sistema de Inventario',
        text: `Hola ${userName},\n\nHemos recibido una solicitud para restablecer tu contraseña.\nTu contraseña temporal de acceso es: ${tempPassword}\n\nPor favor, inicia sesión con esta clave y cámbiala de inmediato desde la sección de ajustes.\n\nAtentamente,\nEl equipo de Inventario`,
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                <h2 style="color: #6200EE; text-align: center;">Restablecimiento de Contraseña</h2>
                <p>Hola <strong>${userName}</strong>,</p>
                <p>Hemos recibido una solicitud para restablecer tu contraseña en el Sistema de Inventario.</p>
                <div style="background-color: #f5f5f5; padding: 15px; text-align: center; border-radius: 5px; font-size: 18px; margin: 20px 0; border: 1px dashed #6200EE;">
                    Tu contraseña temporal de acceso es:<br>
                    <strong style="color: #03A9F4; font-size: 22px; letter-spacing: 1px;">${tempPassword}</strong>
                </div>
                <p>Por favor, ingresa a la aplicación utilizando esta contraseña y cámbiala de inmediato desde la sección de perfil/ajustes para mantener tu cuenta segura.</p>
                <p style="color: #888888; font-size: 12px; margin-top: 30px; border-top: 1px solid #e0e0e0; padding-top: 10px; text-align: center;">
                    Si no solicitaste este restablecimiento, puedes ignorar este correo.
                </p>
            </div>
        `
    });

    console.log(`✉️ Correo enviado: ${info.messageId}`);
    const previewUrl = nodemailer.getTestMessageUrl(info);
    if (previewUrl) {
        console.log(`🔗 URL de vista previa del correo: ${previewUrl}`);
    }
}

// Login
app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body; // email representa el identificador (correo o usuario)
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request()
            .input('identifier', sql.NVarChar, email)
            .query('SELECT id, name, email, username, password, role, profile_image_url FROM users WHERE email = @identifier OR username = @identifier');

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            const isMatch = bcrypt.compareSync(password, user.password);
            if (isMatch) {
                res.json({
                    token: `mock_jwt_token_for_user_${user.id}`,
                    user: {
                        id: user.id.toString(),
                        name: user.name,
                        email: user.email,
                        username: user.username,
                        role: user.role,
                        profileImageUrl: user.profile_image_url
                    }
                });
            } else {
                res.status(401).json({ message: 'Contraseña incorrecta.' });
            }
        } else {
            res.status(401).json({ message: 'Usuario o correo incorrectos.' });
        }
    } catch (err) {
        res.status(500).json({ message: 'Error en la base de datos.', error: err.message });
    }
});

// Registro
app.post('/api/auth/register', async (req, res) => {
    const { name, username, email, password } = req.body;
    try {
        const pool = await sql.connect(dbConfig);

        // Verificar si ya existe el correo
        const checkEmail = await pool.request()
            .input('email', sql.NVarChar, email)
            .query('SELECT id FROM users WHERE email = @email');

        if (checkEmail.recordset.length > 0) {
            return res.status(400).json({ message: 'El correo electrónico ya está registrado.' });
        }

        // Verificar si ya existe el usuario
        const checkUsername = await pool.request()
            .input('username', sql.NVarChar, username)
            .query('SELECT id FROM users WHERE username = @username');

        if (checkUsername.recordset.length > 0) {
            return res.status(400).json({ message: 'El nombre de usuario ya está en uso.' });
        }

        // Encriptar contraseña
        const hashedPassword = bcrypt.hashSync(password, 10);

        // Insertar usuario
        const result = await pool.request()
            .input('name', sql.NVarChar, name)
            .input('username', sql.NVarChar, username)
            .input('email', sql.NVarChar, email)
            .input('password', sql.NVarChar, hashedPassword)
            .query('INSERT INTO users (name, username, email, password, role) OUTPUT INSERTED.id, INSERTED.name, INSERTED.username, INSERTED.email, INSERTED.role VALUES (@name, @username, @email, @password, \'ALMACENERO\')');

        const newUser = result.recordset[0];
        res.json({
            user: {
                id: newUser.id.toString(),
                name: newUser.name,
                username: newUser.username,
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

        // Obtener la contraseña actual encriptada
        const checkUser = await pool.request()
            .input('id', sql.BigInt, parseInt(userId))
            .query('SELECT password FROM users WHERE id = @id');

        if (checkUser.recordset.length === 0) {
            return res.status(404).json({ message: 'Usuario no encontrado.' });
        }

        const user = checkUser.recordset[0];
        const isMatch = bcrypt.compareSync(currentPassword, user.password);

        if (!isMatch) {
            return res.status(400).json({ message: 'La contraseña actual es incorrecta.' });
        }

        // Encriptar la nueva contraseña
        const hashedPassword = bcrypt.hashSync(newPassword, 10);

        // Actualizar contraseña
        await pool.request()
            .input('id', sql.BigInt, parseInt(userId))
            .input('password', sql.NVarChar, hashedPassword)
            .query('UPDATE users SET password = @password WHERE id = @id');

        res.json({ message: 'Contraseña actualizada exitosamente.' });
    } catch (err) {
        res.status(500).json({ message: 'Error al actualizar contraseña.', error: err.message });
    }
});

// Recuperar contraseña (olvido de contraseña)
app.post('/api/auth/forgot-password', async (req, res) => {
    const { email } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        
        // Verificar si el usuario existe
        const checkUser = await pool.request()
            .input('email', sql.NVarChar, email)
            .query('SELECT id, name FROM users WHERE email = @email');

        if (checkUser.recordset.length === 0) {
            return res.status(404).json({ message: 'El correo electrónico no está registrado.' });
        }

        const user = checkUser.recordset[0];
        
        // Generar una contraseña temporal y encriptarla
        const tempPassword = `RESET-${Math.floor(100000 + Math.random() * 900000)}`;
        const hashedPassword = bcrypt.hashSync(tempPassword, 10);
        
        // Actualizar la contraseña en la base de datos
        await pool.request()
            .input('id', sql.BigInt, user.id)
            .input('password', sql.NVarChar, hashedPassword)
            .query('UPDATE users SET password = @password WHERE id = @id');

        console.log(`✉️ [MOCK EMAIL SENT TO ${email}]: Hola ${user.name}, tu nueva clave temporal de acceso es: ${tempPassword}`);

        // Enviar correo de verdad de manera asíncrona
        sendRecoveryEmail(email, user.name, tempPassword).catch(emailErr => {
            console.error('❌ Error al enviar correo de recuperación con nodemailer:', emailErr.message);
        });

        res.json({ 
            message: 'Instrucciones enviadas al correo.'
        });
    } catch (err) {
        res.status(500).json({ message: 'Error en el proceso de recuperación.', error: err.message });
    }
});


// Guardar Foto de Perfil del Usuario
function saveProfileImage(userId, base64Image) {
    if (!base64Image) return null;

    const rootDir = 'C:\\Users\\aldo1\\Documents\\InventarioAPP';
    const folderName = `perfil_${userId}`;
    const profileDir = path.join(rootDir, folderName);

    // Create directory if not exists
    if (!fs.existsSync(profileDir)) {
        fs.mkdirSync(profileDir, { recursive: true });
    }

    // Delete previous images in profileDir
    try {
        const files = fs.readdirSync(profileDir);
        for (const file of files) {
            fs.unlinkSync(path.join(profileDir, file));
        }
    } catch (e) {
        console.error("Error clearing profile directory:", e);
    }

    // Determine mime type and extension
    let ext = 'jpg';
    let base64Data = base64Image;
    if (base64Image.includes(';base64,')) {
        const parts = base64Image.split(';base64,');
        const mime = parts[0];
        base64Data = parts[1];
        if (mime.includes('png')) ext = 'png';
        else if (mime.includes('jpeg')) ext = 'jpeg';
        else if (mime.includes('gif')) ext = 'gif';
    }

    const filename = `photo_${Date.now()}.${ext}`;
    const filePath = path.join(profileDir, filename);

    fs.writeFileSync(filePath, Buffer.from(base64Data, 'base64'));

    return filePath;
}

// Endpoint para actualizar información de perfil
app.post('/api/auth/update-profile', async (req, res) => {
    const { userId, name, base64Image } = req.body;
    try {
        const pool = await sql.connect(dbConfig);

        let savedImagePath = null;
        if (base64Image) {
            savedImagePath = saveProfileImage(userId, base64Image);
        }

        let query = 'UPDATE users SET name = @name';
        if (savedImagePath) {
            query += ', profile_image_url = @profileImageUrl';
        }
        query += ' WHERE id = @id';

        const request = pool.request()
            .input('id', sql.BigInt, parseInt(userId))
            .input('name', sql.NVarChar, name);

        if (savedImagePath) {
            request.input('profileImageUrl', sql.NVarChar, savedImagePath);
        }

        await request.query(query);

        // Obtener usuario actualizado
        const getUpdatedQuery = 'SELECT id, name, email, role, profile_image_url FROM users WHERE id = @id';
        const updatedResult = await pool.request()
            .input('id', sql.BigInt, parseInt(userId))
            .query(getUpdatedQuery);

        if (updatedResult.recordset.length > 0) {
            const user = updatedResult.recordset[0];
            res.json({
                user: {
                    id: user.id.toString(),
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    profileImageUrl: user.profile_image_url
                }
            });
        } else {
            res.status(404).json({ message: 'Usuario no encontrado tras la actualización.' });
        }
    } catch (err) {
        res.status(500).json({ message: 'Error al actualizar perfil.', error: err.message });
    }
});

// Guardar Logo de la Empresa
function saveCompanyLogo(base64Image) {
    if (!base64Image) return null;

    const rootDir = 'C:\\Users\\aldo1\\Documents\\InventarioAPP';
    const folderName = 'logo';
    const logoDir = path.join(rootDir, folderName);

    // Create directory if not exists
    if (!fs.existsSync(logoDir)) {
        fs.mkdirSync(logoDir, { recursive: true });
    }

    // Delete previous images in logoDir
    try {
        const files = fs.readdirSync(logoDir);
        for (const file of files) {
            fs.unlinkSync(path.join(logoDir, file));
        }
    } catch (e) {
        console.error("Error clearing logo directory:", e);
    }

    // Determine mime type and extension
    let ext = 'png';
    let base64Data = base64Image;
    if (base64Image.includes(';base64,')) {
        const parts = base64Image.split(';base64,');
        const mime = parts[0];
        base64Data = parts[1];
        if (mime.includes('png')) ext = 'png';
        else if (mime.includes('jpeg') || mime.includes('jpg')) ext = 'jpg';
        else if (mime.includes('gif')) ext = 'gif';
    }

    const filename = `logo_${Date.now()}.${ext}`;
    const filePath = path.join(logoDir, filename);

    fs.writeFileSync(filePath, Buffer.from(base64Data, 'base64'));

    return filePath;
}

// Endpoint para obtener el logo actual de la empresa
app.get('/api/logo', (req, res) => {
    const logoDir = 'C:\\Users\\aldo1\\Documents\\InventarioAPP\\logo';
    if (!fs.existsSync(logoDir)) {
        return res.json({ logoUrl: null });
    }

    try {
        const files = fs.readdirSync(logoDir);
        if (files.length > 0) {
            res.json({ logoUrl: `logo/${files[0]}` });
        } else {
            res.json({ logoUrl: null });
        }
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Endpoint para subir o actualizar el logo de la empresa
app.post('/api/logo', (req, res) => {
    const { base64Image } = req.body;
    try {
        const savedPath = saveCompanyLogo(base64Image);
        if (savedPath) {
            const filename = path.basename(savedPath);
            res.json({ success: true, logoUrl: `logo/${filename}` });
        } else {
            res.status(400).json({ message: 'No se recibió ninguna imagen.' });
        }
    } catch (err) {
        res.status(500).json({ message: 'Error al guardar el logo.', error: err.message });
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

// Crear cliente
app.post('/api/customers', async (req, res) => {
    const { name, taxId } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request()
            .input('name', sql.NVarChar, name)
            .input('taxId', sql.NVarChar, taxId || 'N/D')
            .query('INSERT INTO customers (name, tax_id) OUTPUT INSERTED.id, INSERTED.name, INSERTED.tax_id VALUES (@name, @taxId)');

        const c = result.recordset[0];
        res.json({
            id: c.id.toString(),
            name: c.name,
            taxId: c.tax_id
        });
    } catch (err) {
        res.status(500).json({ message: 'Error al crear cliente.', error: err.message });
    }
});

// Actualizar cliente
app.put('/api/customers/:id', async (req, res) => {
    const { id } = req.params;
    const { name, taxId } = req.body;
    try {
        const pool = await sql.connect(dbConfig);
        await pool.request()
            .input('id', sql.BigInt, parseInt(id))
            .input('name', sql.NVarChar, name)
            .input('taxId', sql.NVarChar, taxId || 'N/D')
            .query('UPDATE customers SET name = @name, tax_id = @taxId WHERE id = @id');

        res.json({ message: 'Cliente actualizado exitosamente.' });
    } catch (err) {
        res.status(500).json({ message: 'Error al actualizar cliente.', error: err.message });
    }
});

// Eliminar cliente
app.delete('/api/customers/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await sql.connect(dbConfig);
        await pool.request()
            .input('id', sql.BigInt, parseInt(id))
            .query('DELETE FROM customers WHERE id = @id');

        res.json({ message: 'Cliente eliminado exitosamente.' });
    } catch (err) {
        res.status(500).json({ message: 'Error al eliminar cliente.', error: err.message });
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

function saveProductImage(productNameOrSku, base64Image) {
    if (!base64Image) return null;

    const rootDir = 'C:\\Users\\aldo1\\Documents\\InventarioAPP';
    // Clean folder name to prevent illegal file system chars
    const folderName = productNameOrSku.replace(/[^a-zA-Z0-9_-]/g, '_');
    const productDir = path.join(rootDir, folderName);

    // Create directory if not exists
    if (!fs.existsSync(productDir)) {
        fs.mkdirSync(productDir, { recursive: true });
    }

    // Delete previous images in productDir
    try {
        const files = fs.readdirSync(productDir);
        for (const file of files) {
            fs.unlinkSync(path.join(productDir, file));
        }
    } catch (e) {
        console.error("Error clearing directory:", e);
    }

    // Determine mime type and extension
    let ext = 'jpg';
    let base64Data = base64Image;
    if (base64Image.includes(';base64,')) {
        const parts = base64Image.split(';base64,');
        const mime = parts[0];
        base64Data = parts[1];
        if (mime.includes('png')) ext = 'png';
        else if (mime.includes('jpeg')) ext = 'jpeg';
        else if (mime.includes('gif')) ext = 'gif';
    }

    const filename = `photo_${Date.now()}.${ext}`;
    const filePath = path.join(productDir, filename);

    fs.writeFileSync(filePath, Buffer.from(base64Data, 'base64'));

    return filePath;
}

// Crear producto
app.post('/api/products', async (req, res) => {
    const { name, description, price, stock, category, sku, purchasePrice, taxPercentage, minStock, unitMeasure, base64Image } = req.body;
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

        // Handle Image upload if base64Image is present
        let savedImagePath = null;
        if (base64Image) {
            savedImagePath = saveProductImage(finalSku, base64Image);
        }

        const query = `
            INSERT INTO products (
                sku, name, description, category_id, purchase_price, sale_price, 
                tax_percentage, unit_measure, stock, min_stock, image_url
            ) 
            OUTPUT 
                INSERTED.id, INSERTED.sku, INSERTED.name, INSERTED.description, 
                INSERTED.purchase_price, INSERTED.sale_price, INSERTED.tax_percentage, 
                INSERTED.unit_measure, INSERTED.stock, INSERTED.min_stock, INSERTED.image_url
            VALUES (
                @sku, @name, @description, @categoryId, @purchasePrice, @salePrice, 
                @taxPercentage, @unitMeasure, @stock, @minStock, @imageUrl
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
            .input('imageUrl', sql.NVarChar, savedImagePath)
            .query(query);

        const p = result.recordset[0];
        
        // Si el producto se crea con stock inicial > 0, generar un lote inicial automático
        const newProductStock = parseInt(p.stock);
        if (newProductStock > 0) {
            const whRes = await pool.request().query("SELECT TOP 1 id FROM warehouses ORDER BY id ASC");
            const firstWhId = whRes.recordset.length > 0 ? whRes.recordset[0].id : 1;
            const newProductPurchasePrice = p.purchase_price != null ? parseFloat(p.purchase_price) : 0.0;
            
            const initialLotQuery = `
                INSERT INTO product_lots (product_id, transaction_id, warehouse_id, initial_quantity, available_quantity, unit_cost)
                VALUES (@productId, NULL, @warehouseId, @quantity, @quantity, @unitCost)
            `;
            await pool.request()
                .input('productId', sql.BigInt, p.id)
                .input('warehouseId', sql.BigInt, firstWhId)
                .input('quantity', sql.Int, newProductStock)
                .input('unitCost', sql.Decimal(18, 2), newProductPurchasePrice)
                .query(initialLotQuery);
        }

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

// Actualizar producto (Editar)
app.put('/api/products/:id', async (req, res) => {
    const { id } = req.params;
    const { name, description, price, stock, category, sku, purchasePrice, taxPercentage, minStock, unitMeasure, base64Image } = req.body;
    try {
        const pool = await sql.connect(dbConfig);

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

        // Handle Image upload if base64Image is present
        let savedImagePath = null;
        if (base64Image) {
            savedImagePath = saveProductImage(sku || name, base64Image);
        }

        let query = `
            UPDATE products 
            SET 
                name = @name,
                description = @description,
                category_id = @categoryId,
                purchase_price = @purchasePrice,
                sale_price = @salePrice,
                tax_percentage = @taxPercentage,
                unit_measure = @unitMeasure,
                stock = @stock,
                min_stock = @minStock
        `;

        if (sku) {
            query += `, sku = @sku`;
        }
        if (savedImagePath) {
            query += `, image_url = @imageUrl`;
        }

        query += ` WHERE id = @id`;

        const request = pool.request()
            .input('id', sql.BigInt, parseInt(id))
            .input('name', sql.NVarChar, name)
            .input('description', sql.NVarChar, description || '')
            .input('categoryId', sql.BigInt, categoryId)
            .input('purchasePrice', sql.Decimal(18, 2), purchasePrice !== undefined ? purchasePrice : ((price * 0.7) || 0.0))
            .input('salePrice', sql.Decimal(18, 2), price || 0.0)
            .input('taxPercentage', sql.Decimal(5, 2), taxPercentage !== undefined ? taxPercentage : 13.0)
            .input('unitMeasure', sql.NVarChar, unitMeasure || 'Unidad')
            .input('stock', sql.Int, stock || 0)
            .input('minStock', sql.Int, minStock !== undefined ? minStock : 0);

        if (sku) {
            request.input('sku', sql.NVarChar, sku);
        }
        if (savedImagePath) {
            request.input('imageUrl', sql.NVarChar, savedImagePath);
        }

        await request.query(query);

        // Obtener el producto completo actualizado para responderle al frontend
        const getUpdatedQuery = `
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
            WHERE p.id = @id
        `;
        const updatedResult = await pool.request()
            .input('id', sql.BigInt, parseInt(id))
            .query(getUpdatedQuery);

        if (updatedResult.recordset.length > 0) {
            const p = updatedResult.recordset[0];
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
                category: p.category || 'General',
                imageUrl: p.image_url,
                unitMeasure: p.unit_measure || 'Unidad'
            });
        } else {
            res.status(404).json({ message: 'Producto no encontrado tras la actualización.' });
        }
    } catch (err) {
        res.status(500).json({ message: 'Error al actualizar producto.', error: err.message });
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
                t.id AS transactionId,
                t.transaction_date AS date,
                t.type AS type,
                i.quantity AS quantity,
                i.unit_price AS unitPrice,
                i.lot_id AS lotId,
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
                transactionId: item.transactionId ? item.transactionId.toString() : null,
                date: item.date,
                type: item.type,
                quantity: qty,
                unitPrice: parseFloat(item.unitPrice),
                lotId: item.lotId ? item.lotId.toString() : null,
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


// Obtener todos los lotes de un producto (Soporta filtro por status = 'active' o 'depleted')
app.get('/api/products/:id/lots', async (req, res) => {
    const { id } = req.params;
    const { status } = req.query;
    try {
        const pool = await sql.connect(dbConfig);
        let query = `
            SELECT 
                pl.id,
                pl.product_id AS productId,
                pl.transaction_id AS transactionId,
                pl.warehouse_id AS warehouseId,
                w.name AS warehouseName,
                pl.entry_date AS entryDate,
                pl.initial_quantity AS initialQuantity,
                pl.available_quantity AS availableQuantity,
                pl.unit_cost AS unitCost,
                t.type AS originTransactionType,
                t.observations AS originObservations
            FROM product_lots pl
            INNER JOIN warehouses w ON pl.warehouse_id = w.id
            LEFT JOIN inventory_transactions t ON pl.transaction_id = t.id
            WHERE pl.product_id = @productId
        `;

        if (status === 'active') {
            query += ' AND pl.available_quantity > 0';
        } else if (status === 'depleted') {
            query += ' AND pl.available_quantity = 0';
        }

        query += ' ORDER BY pl.entry_date ASC, pl.id ASC';

        const result = await pool.request()
            .input('productId', sql.BigInt, parseInt(id))
            .query(query);

        res.json(result.recordset.map(row => ({
            id: row.id.toString(),
            productId: row.productId.toString(),
            transactionId: row.transactionId ? row.transactionId.toString() : null,
            warehouseId: row.warehouseId.toString(),
            warehouseName: row.warehouseName,
            entryDate: row.entryDate,
            initialQuantity: parseInt(row.initialQuantity),
            availableQuantity: parseInt(row.availableQuantity),
            unitCost: parseFloat(row.unitCost),
            originTransactionType: row.originTransactionType || 'Semilla / Inicial',
            originObservations: row.originObservations || 'Stock inicial de compatibilidad'
        })));
    } catch (err) {
        res.status(500).json({ message: 'Error al obtener lotes del producto.', error: err.message });
    }
});

// Obtener el detalle PEPS (desglose de consumo de lotes) de una transacción registrada
app.get('/api/transactions/:id/fifo-detail', async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await sql.connect(dbConfig);
        const query = `
            SELECT 
                ti.id,
                ti.lot_id AS lotId,
                ti.quantity,
                ti.unit_price AS unitPrice,
                pl.entry_date AS lotEntryDate,
                p.name AS productName,
                p.sku AS productSku
            FROM transaction_items ti
            LEFT JOIN product_lots pl ON ti.lot_id = pl.id
            INNER JOIN products p ON ti.product_id = p.id
            WHERE ti.transaction_id = @transactionId AND ti.lot_id IS NOT NULL
            ORDER BY ti.id ASC
        `;

        const result = await pool.request()
            .input('transactionId', sql.BigInt, parseInt(id))
            .query(query);

        res.json(result.recordset.map(row => ({
            id: row.id.toString(),
            lotId: row.lotId.toString(),
            quantity: parseInt(row.quantity),
            unitPrice: parseFloat(row.unitPrice),
            lotEntryDate: row.lotEntryDate,
            productName: row.productName,
            productSku: row.productSku
        })));
    } catch (err) {
        res.status(500).json({ message: 'Error al obtener detalle PEPS de la transacción.', error: err.message });
    }
});

// Obtener proyección de consumo PEPS en tiempo real (Vista Previa de Salidas)
app.get('/api/products/:id/lots/preview-peps', async (req, res) => {
    const { id } = req.params;
    const { qty, warehouseId } = req.query;

    if (!qty || !warehouseId) {
        return res.status(400).json({ message: 'Debe proporcionar la cantidad (qty) y el almacén (warehouseId).' });
    }

    try {
        const pool = await sql.connect(dbConfig);
        const query = `
            SELECT id, available_quantity, unit_cost, entry_date
            FROM product_lots
            WHERE product_id = @productId AND warehouse_id = @warehouseId AND available_quantity > 0
            ORDER BY entry_date ASC, id ASC
        `;

        const result = await pool.request()
            .input('productId', sql.BigInt, parseInt(id))
            .input('warehouseId', sql.BigInt, parseInt(warehouseId))
            .query(query);

        const lots = result.recordset;
        const targetQty = parseInt(qty);
        let remainingQty = targetQty;
        const breakdown = [];
        let totalValuation = 0.00;

        for (let lot of lots) {
            if (remainingQty <= 0) break;
            const take = Math.min(lot.available_quantity, remainingQty);
            breakdown.push({
                lotId: lot.id.toString(),
                quantity: take,
                unitCost: parseFloat(lot.unit_cost),
                entryDate: lot.entry_date
            });
            remainingQty -= take;
            totalValuation += take * parseFloat(lot.unit_cost);
        }

        res.json({
            productId: id,
            requestedQuantity: targetQty,
            satisfied: remainingQty === 0,
            remainingQuantity: remainingQty,
            totalCost: totalValuation,
            breakdown: breakdown
        });
    } catch (err) {
        res.status(500).json({ message: 'Error al calcular proyección PEPS.', error: err.message });
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
                t.id, t.type, t.transaction_date, t.total_amount, t.observations, t.reason,
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
                reason: tx.reason || 'Venta',
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

// Registrar nueva Transacción (Entrada/Salida) y actualizar Stock (ACID Transaccional con PEPS)
app.post('/api/transactions', async (req, res) => {
    const { type, warehouseId, supplierId, customerId, observations, items, userId, reason } = req.body;

    if (!items || items.length === 0) {
        return res.status(400).json({ message: 'Debe agregar al menos un producto a la transacción.' });
    }

    const pool = await sql.connect(dbConfig);
    const transaction = new sql.Transaction(pool);

    try {
        await transaction.begin();

        // 1. Insertar cabecera en inventory_transactions con total_amount temporal en 0.00
        const txInsertQuery = `
            INSERT INTO inventory_transactions (
                type, warehouse_id, supplier_id, customer_id, total_amount, observations, user_id, reason
            )
            OUTPUT INSERTED.id
            VALUES (
                @type, @warehouseId, @supplierId, @customerId, 0.00, @observations, @userId, @reason
            )
        `;

        const txRequest = new sql.Request(transaction);
        const txResult = await txRequest
            .input('type', sql.NVarChar, type)
            .input('warehouseId', sql.BigInt, parseInt(warehouseId))
            .input('supplierId', sql.BigInt, supplierId ? parseInt(supplierId) : null)
            .input('customerId', sql.BigInt, customerId ? parseInt(customerId) : null)
            .input('observations', sql.NVarChar, observations || '')
            .input('userId', sql.BigInt, userId ? parseInt(userId) : 1) // default admin
            .input('reason', sql.NVarChar, reason || 'Venta')
            .query(txInsertQuery);

        const transactionId = txResult.recordset[0].id;
        let totalValuation = 0.00;

        // 2. Procesar cada Item con PEPS/FIFO
        for (let item of items) {
            const productId = parseInt(item.productId);
            const qty = parseInt(item.quantity);
            const unitPrice = parseFloat(item.unitPrice);

            if (type === 'ENTRADA') {
                // ENTRADA: Crear un nuevo lote independiente para PEPS y obtener su ID
                const lotRequest = new sql.Request(transaction);
                const lotResult = await lotRequest
                    .input('txId', sql.BigInt, transactionId)
                    .input('productId', sql.BigInt, productId)
                    .input('warehouseId', sql.BigInt, parseInt(warehouseId))
                    .input('quantity', sql.Int, qty)
                    .input('unitCost', sql.Decimal(18, 2), unitPrice)
                    .query(`
                        INSERT INTO product_lots (product_id, transaction_id, warehouse_id, initial_quantity, available_quantity, unit_cost)
                        OUTPUT INSERTED.id
                        VALUES (@productId, @txId, @warehouseId, @quantity, @quantity, @unitCost)
                    `);

                const lotId = lotResult.recordset[0].id;

                // ENTRADA: Registrar item de transacción enlazado al lot_id
                const itemRequest = new sql.Request(transaction);
                await itemRequest
                    .input('txId', sql.BigInt, transactionId)
                    .input('productId', sql.BigInt, productId)
                    .input('quantity', sql.Int, qty)
                    .input('unitPrice', sql.Decimal(18, 2), unitPrice)
                    .input('lotId', sql.BigInt, lotId)
                    .query('INSERT INTO transaction_items (transaction_id, product_id, quantity, unit_price, lot_id) VALUES (@txId, @productId, @quantity, @unitPrice, @lotId)');

                // ENTRADA: Actualizar precio base del producto sin sobrescribir el costo de lotes históricos
                const priceRequest = new sql.Request(transaction);
                await priceRequest
                    .input('productId', sql.BigInt, productId)
                    .input('unitPrice', sql.Decimal(18, 2), unitPrice)
                    .query('UPDATE products SET purchase_price = @unitPrice WHERE id = @productId');

                // ENTRADA: Aumentar stock del producto
                const stockRequest = new sql.Request(transaction);
                await stockRequest
                    .input('productId', sql.BigInt, productId)
                    .input('quantity', sql.Int, qty)
                    .query('UPDATE products SET stock = stock + @quantity WHERE id = @productId');

                totalValuation += qty * unitPrice;

            } else if (type === 'SALIDA') {
                // SALIDA: Buscar lotes disponibles (PEPS: Ordenados por fecha y ID de forma ascendente)
                const lotsRequest = new sql.Request(transaction);
                const lotsResult = await lotsRequest
                    .input('productId', sql.BigInt, productId)
                    .input('warehouseId', sql.BigInt, parseInt(warehouseId))
                    .query(`
                        SELECT id, available_quantity, unit_cost 
                        FROM product_lots 
                        WHERE product_id = @productId AND warehouse_id = @warehouseId AND available_quantity > 0 
                        ORDER BY entry_date ASC, id ASC
                    `);

                const lots = lotsResult.recordset;
                const totalAvailable = lots.reduce((sum, lot) => sum + lot.available_quantity, 0);

                if (totalAvailable < qty) {
                    throw new Error(`Stock PEPS insuficiente para el producto ID ${productId}. Disponible en lotes: ${totalAvailable}, Requerido: ${qty}`);
                }

                let remainingQty = qty;
                for (let lot of lots) {
                    if (remainingQty <= 0) break;

                    const take = Math.min(lot.available_quantity, remainingQty);
                    const lotCost = lot.unit_cost;

                    // SALIDA: Reducir cantidad disponible del lote en base de datos
                    const deductRequest = new sql.Request(transaction);
                    await deductRequest
                        .input('lotId', sql.Int, lot.id)
                        .input('take', sql.Int, take)
                        .query('UPDATE product_lots SET available_quantity = available_quantity - @take WHERE id = @lotId');

                    // SALIDA: Registrar item de transacción con el costo exacto del lote consumido y enlazado a su lot_id
                    const itemRequest = new sql.Request(transaction);
                    await itemRequest
                        .input('txId', sql.BigInt, transactionId)
                        .input('productId', sql.BigInt, productId)
                        .input('quantity', sql.Int, take)
                        .input('unitPrice', sql.Decimal(18, 2), lotCost)
                        .input('lotId', sql.BigInt, lot.id)
                        .query('INSERT INTO transaction_items (transaction_id, product_id, quantity, unit_price, lot_id) VALUES (@txId, @productId, @quantity, @unitPrice, @lotId)');

                    remainingQty -= take;
                    totalValuation += take * lotCost;
                }

                // SALIDA: Disminuir stock del producto
                const stockRequest = new sql.Request(transaction);
                await stockRequest
                    .input('productId', sql.BigInt, productId)
                    .input('quantity', sql.Int, qty)
                    .query('UPDATE products SET stock = stock - @quantity WHERE id = @productId');
            }
        }

        // 3. Actualizar la valoración final acumulada en la cabecera de la transacción
        const updateHeaderRequest = new sql.Request(transaction);
        await updateHeaderRequest
            .input('txId', sql.BigInt, transactionId)
            .input('totalAmount', sql.Decimal(18, 2), totalValuation)
            .query('UPDATE inventory_transactions SET total_amount = @totalAmount WHERE id = @txId');

        await transaction.commit();
        res.json({ message: 'Transacción registrada con éxito en sistema PEPS.', transactionId: transactionId.toString() });

    } catch (err) {
        await transaction.rollback();
        console.error('Error en transacción de stock PEPS:', err);
        res.status(500).json({ message: 'Error procesando la transacción PEPS.', error: err.message });
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
                (SELECT COUNT(id) FROM customers) AS totalCustomers,
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
            totalCustomers: 0,
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
                totalCustomers: parseInt(execSummary.totalCustomers || 0),
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
