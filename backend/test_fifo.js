const sql = require('mssql');

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

async function runTests() {
    console.log('🧪 INICIANDO PRUEBAS DE AUDITORÍA PEPS (FIFO)...');
    let pool;
    try {
        pool = await sql.connect(dbConfig);
        console.log('✅ Conectado a la base de datos SQL Server.');

        // Asegurar que existe la tabla product_lots
        console.log('🛠️ Asegurando que la tabla product_lots existe...');
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
            END
        `);
        console.log('✅ Tabla product_lots verificada/creada.');

        // 1. Limpieza y preparación de datos semilla de prueba
        console.log('\n🧹 Limpiando registros previos de prueba...');

        // Obtener ID del producto si existe
        let prodRes = await pool.request().query("SELECT id FROM products WHERE sku = 'SKU-TEST-PEPS'");
        if (prodRes.recordset.length > 0) {
            const prodId = prodRes.recordset[0].id;

            // Eliminar transacciones e ítems relacionados al producto de prueba
            await pool.request().input('prodId', sql.Int, prodId).query(`
                DELETE FROM transaction_items WHERE product_id = @prodId;
                DELETE FROM product_lots WHERE product_id = @prodId;
            `);

            // Eliminar producto
            await pool.request().input('prodId', sql.Int, prodId).query(`
                DELETE FROM products WHERE id = @prodId;
            `);
            console.log('🗑️ Producto de prueba anterior eliminado.');
        }

        // Asegurar que exista un Almacén, Proveedor, Cliente y Usuario
        let whRes = await pool.request().query("SELECT TOP 1 id FROM warehouses ORDER BY id ASC");
        let warehouseId = whRes.recordset.length > 0 ? whRes.recordset[0].id : null;
        if (!warehouseId) {
            let insWh = await pool.request().query("INSERT INTO warehouses (name, location) OUTPUT INSERTED.id VALUES ('Bodega Central', 'Local')");
            warehouseId = insWh.recordset[0].id;
        }

        let supRes = await pool.request().query("SELECT TOP 1 id FROM suppliers ORDER BY id ASC");
        let supplierId = supRes.recordset.length > 0 ? supRes.recordset[0].id : null;
        if (!supplierId) {
            let insSup = await pool.request().query("INSERT INTO suppliers (name, contact_info) OUTPUT INSERTED.id VALUES ('Distribuidor Test', 'test@corp.com')");
            supplierId = insSup.recordset[0].id;
        }

        let custRes = await pool.request().query("SELECT TOP 1 id FROM customers ORDER BY id ASC");
        let customerId = custRes.recordset.length > 0 ? custRes.recordset[0].id : null;
        if (!customerId) {
            let insCust = await pool.request().query("INSERT INTO customers (name, tax_id) OUTPUT INSERTED.id VALUES ('Cliente Test', '123-456')");
            customerId = insCust.recordset[0].id;
        }

        let userRes = await pool.request().query("SELECT TOP 1 id FROM users ORDER BY id ASC");
        let userId = userRes.recordset.length > 0 ? userRes.recordset[0].id : 1;

        // Crear el producto de prueba
        console.log('📦 Creando nuevo producto SKU-TEST-PEPS...');
        let insertProd = await pool.request()
            .input('sku', sql.NVarChar, 'SKU-TEST-PEPS')
            .input('name', sql.NVarChar, 'Teclado PEPS Test')
            .input('desc', sql.NVarChar, 'Producto para auditoría de PEPS')
            .query(`
                INSERT INTO products (sku, name, description, purchase_price, sale_price, tax_percentage, unit_measure, stock, min_stock)
                OUTPUT INSERTED.id
                VALUES (@sku, @name, @desc, 0.00, 50.00, 13.00, 'Unidad', 0, 5)
            `);
        const productId = insertProd.recordset[0].id;
        console.log(`✅ Producto creado exitosamente con ID: ${productId}`);

        // Helper para simular transacciones mediante llamada API simulada (enviando payload a la base de datos a través del algoritmo)
        async function mockTransaction(payload) {
            const transaction = new sql.Transaction(pool);
            await transaction.begin();
            try {
                // Insertar cabecera
                const txResult = await new sql.Request(transaction)
                    .input('type', sql.NVarChar, payload.type)
                    .input('warehouseId', sql.BigInt, parseInt(payload.warehouseId))
                    .input('supplierId', sql.BigInt, payload.supplierId ? parseInt(payload.supplierId) : null)
                    .input('customerId', sql.BigInt, payload.customerId ? parseInt(payload.customerId) : null)
                    .input('observations', sql.NVarChar, payload.observations || '')
                    .input('userId', sql.BigInt, payload.userId ? parseInt(payload.userId) : 1)
                    .input('reason', sql.NVarChar, payload.reason || 'Venta')
                    .query(`
                        INSERT INTO inventory_transactions (type, warehouse_id, supplier_id, customer_id, total_amount, observations, user_id, reason)
                        OUTPUT INSERTED.id
                        VALUES (@type, @warehouseId, @supplierId, @customerId, 0.00, @observations, @userId, @reason)
                    `);

                const transactionId = txResult.recordset[0].id;
                let totalValuation = 0.00;

                for (let item of payload.items) {
                    const prodId = parseInt(item.productId);
                    const qty = parseInt(item.quantity);
                    const unitPrice = parseFloat(item.unitPrice);

                    if (payload.type === 'ENTRADA') {
                        await new sql.Request(transaction)
                            .input('txId', sql.BigInt, transactionId)
                            .input('productId', sql.BigInt, prodId)
                            .input('quantity', sql.Int, qty)
                            .input('unitPrice', sql.Decimal(18, 2), unitPrice)
                            .query('INSERT INTO transaction_items (transaction_id, product_id, quantity, unit_price) VALUES (@txId, @productId, @quantity, @unitPrice)');

                        await new sql.Request(transaction)
                            .input('txId', sql.BigInt, transactionId)
                            .input('productId', sql.BigInt, prodId)
                            .input('warehouseId', sql.BigInt, parseInt(payload.warehouseId))
                            .input('quantity', sql.Int, qty)
                            .input('unitCost', sql.Decimal(18, 2), unitPrice)
                            .query(`
                                INSERT INTO product_lots (product_id, transaction_id, warehouse_id, initial_quantity, available_quantity, unit_cost)
                                VALUES (@productId, @txId, @warehouseId, @quantity, @quantity, @unitCost)
                            `);

                        await new sql.Request(transaction)
                            .input('productId', sql.BigInt, prodId)
                            .input('unitPrice', sql.Decimal(18, 2), unitPrice)
                            .query('UPDATE products SET purchase_price = @unitPrice WHERE id = @productId');

                        await new sql.Request(transaction)
                            .input('productId', sql.BigInt, prodId)
                            .input('quantity', sql.Int, qty)
                            .query('UPDATE products SET stock = stock + @quantity WHERE id = @productId');

                        totalValuation += qty * unitPrice;

                    } else if (payload.type === 'SALIDA') {
                        const lotsResult = await new sql.Request(transaction)
                            .input('productId', sql.BigInt, prodId)
                            .input('warehouseId', sql.BigInt, parseInt(payload.warehouseId))
                            .query(`
                                SELECT id, available_quantity, unit_cost 
                                FROM product_lots 
                                WHERE product_id = @productId AND warehouse_id = @warehouseId AND available_quantity > 0 
                                ORDER BY entry_date ASC, id ASC
                            `);

                        const lots = lotsResult.recordset;
                        const totalAvailable = lots.reduce((sum, lot) => sum + lot.available_quantity, 0);

                        if (totalAvailable < qty) {
                            throw new Error(`Stock PEPS insuficiente para el producto ID ${prodId}. Disponible: ${totalAvailable}, Requerido: ${qty}`);
                        }

                        let remainingQty = qty;
                        for (let lot of lots) {
                            if (remainingQty <= 0) break;

                            const take = Math.min(lot.available_quantity, remainingQty);
                            const lotCost = lot.unit_cost;

                            await new sql.Request(transaction)
                                .input('lotId', sql.Int, lot.id)
                                .input('take', sql.Int, take)
                                .query('UPDATE product_lots SET available_quantity = available_quantity - @take WHERE id = @lotId');

                            await new sql.Request(transaction)
                                .input('txId', sql.BigInt, transactionId)
                                .input('productId', sql.BigInt, prodId)
                                .input('quantity', sql.Int, take)
                                .input('unitPrice', sql.Decimal(18, 2), lotCost)
                                .query('INSERT INTO transaction_items (transaction_id, product_id, quantity, unit_price) VALUES (@txId, @productId, @quantity, @unitPrice)');

                            remainingQty -= take;
                            totalValuation += take * lotCost;
                        }

                        await new sql.Request(transaction)
                            .input('productId', sql.BigInt, prodId)
                            .input('quantity', sql.Int, qty)
                            .query('UPDATE products SET stock = stock - @quantity WHERE id = @productId');
                    }
                }

                await new sql.Request(transaction)
                    .input('txId', sql.BigInt, transactionId)
                    .input('totalAmount', sql.Decimal(18, 2), totalValuation)
                    .query('UPDATE inventory_transactions SET total_amount = @totalAmount WHERE id = @txId');

                await transaction.commit();
                return transactionId;
            } catch (err) {
                await transaction.rollback();
                throw err;
            }
        }

        // =============================================================
        // EJECUTANDO PRUEBAS FUNCIONALES
        // =============================================================

        // 1. Entrada de producto a $30 (10 unidades)
        console.log('\n📥 Realizando ENTRADA 1: 10 unidades a $30...');
        await mockTransaction({
            type: 'ENTRADA',
            warehouseId: warehouseId,
            supplierId: supplierId,
            userId: userId,
            reason: 'Compra',
            observations: 'Lote 1 de prueba PEPS a $30',
            items: [{ productId: productId, quantity: 10, unitPrice: 30.00 }]
        });

        // 2. Nueva entrada del mismo producto a $35 (10 unidades)
        console.log('📥 Realizando ENTRADA 2: 10 unidades a $35...');
        await mockTransaction({
            type: 'ENTRADA',
            warehouseId: warehouseId,
            supplierId: supplierId,
            userId: userId,
            reason: 'Compra',
            observations: 'Lote 2 de prueba PEPS a $35',
            items: [{ productId: productId, quantity: 10, unitPrice: 35.00 }]
        });

        // 3. Nueva entrada del mismo producto a $25 (10 unidades)
        console.log('📥 Realizando ENTRADA 3: 10 unidades a $25...');
        await mockTransaction({
            type: 'ENTRADA',
            warehouseId: warehouseId,
            supplierId: supplierId,
            userId: userId,
            reason: 'Compra',
            observations: 'Lote 3 de prueba PEPS a $25',
            items: [{ productId: productId, quantity: 10, unitPrice: 25.00 }]
        });

        // Validar lotes generados
        let lotsRes = await pool.request().input('productId', sql.Int, productId).query("SELECT * FROM product_lots WHERE product_id = @productId ORDER BY entry_date ASC, id ASC");
        console.log(`\n📋 Lotes Registrados en Base de Datos:`);
        lotsRes.recordset.forEach((lot, index) => {
            console.log(`  Lote ${index + 1}: Q. Inicial = ${lot.initial_quantity}, Q. Disponible = ${lot.available_quantity}, Costo = $${lot.unit_cost}`);
        });

        if (lotsRes.recordset.length !== 3) {
            throw new Error(`Error: Se esperaban 3 lotes independientes, se encontraron ${lotsRes.recordset.length}`);
        }
        console.log('✅ Verificación de lotes independientes superada.');

        // 4. Salida parcial: Retirar 5 unidades (Debe consumir el primer lote a $30)
        console.log('\n📤 Realizando SALIDA 1 (Parcial): 5 unidades...');
        const out1Id = await mockTransaction({
            type: 'SALIDA',
            warehouseId: warehouseId,
            customerId: customerId,
            userId: userId,
            reason: 'Venta',
            observations: 'Primera salida parcial',
            items: [{ productId: productId, quantity: 5 }]
        });

        // Validar stock restante del primer lote
        let lot1Check = await pool.request().input('productId', sql.Int, productId).query("SELECT * FROM product_lots WHERE product_id = @productId ORDER BY entry_date ASC, id ASC");
        console.log(`📊 Estado de lotes tras Salida 1:`);
        lot1Check.recordset.forEach((lot, index) => {
            console.log(`  Lote ${index + 1}: Disponible = ${lot.available_quantity} (Costo $${lot.unit_cost})`);
        });

        if (lot1Check.recordset[0].available_quantity !== 5) {
            throw new Error(`Error: El Lote 1 debería tener 5 unidades disponibles, tiene ${lot1Check.recordset[0].available_quantity}`);
        }
        console.log('✅ Verificación de salida parcial superada.');

        // 5. Salida que consume múltiples lotes: Retirar 18 unidades
        // Explicación PEPS de las 18 unidades:
        // - Consume 5 unidades del Lote 1 (a $30) -> Queda en 0
        // - Consume 10 unidades del Lote 2 (a $35) -> Queda en 0
        // - Consume 3 unidades del Lote 3 (a $25) -> Queda en 7
        console.log('\n📤 Realizando SALIDA 2 (Multi-lote): 18 unidades...');
        const out2Id = await mockTransaction({
            type: 'SALIDA',
            warehouseId: warehouseId,
            customerId: customerId,
            userId: userId,
            reason: 'Venta',
            observations: 'Salida multi-lote PEPS',
            items: [{ productId: productId, quantity: 18 }]
        });

        // Validar stock restante
        let lotsFinal = await pool.request().input('productId', sql.Int, productId).query("SELECT * FROM product_lots WHERE product_id = @productId ORDER BY entry_date ASC, id ASC");
        console.log(`📊 Estado final de lotes tras Salida 2:`);
        lotsFinal.recordset.forEach((lot, index) => {
            console.log(`  Lote ${index + 1}: Disponible = ${lot.available_quantity} (Costo $${lot.unit_cost})`);
        });

        if (lotsFinal.recordset[0].available_quantity !== 0 || lotsFinal.recordset[1].available_quantity !== 0 || lotsFinal.recordset[2].available_quantity !== 7) {
            throw new Error(`Error: Distribución de stock incorrecta tras PEPS.`);
        }
        console.log('✅ Verificación de consumo secuencial PEPS multi-lote superada.');

        // Validar existencias globales en la tabla de productos
        let prodCheck = await pool.request().input('productId', sql.Int, productId).query("SELECT stock FROM products WHERE id = @productId");
        const finalStock = prodCheck.recordset[0].stock;
        console.log(`\n📦 Stock Global del Producto en Tabla Products: ${finalStock} unidades (Esperado: 7)`);
        if (finalStock !== 7) {
            throw new Error(`Error: El stock global debería ser 7, es ${finalStock}`);
        }
        console.log('✅ Existencias finales verificadas correctamente.');

        // Verificar los costos asignados a los ítems en cada transacción de salida
        console.log('\n🔍 Verificando costos asignados a los ítems de salida (KARDEX):');
        let kardexRes = await pool.request().input('productId', sql.Int, productId).query(`
            SELECT ti.quantity, ti.unit_price, t.type, t.observations
            FROM transaction_items ti
            INNER JOIN inventory_transactions t ON ti.transaction_id = t.id
            WHERE ti.product_id = @productId AND t.type = 'SALIDA'
            ORDER BY t.transaction_date ASC, ti.id ASC
        `);

        kardexRes.recordset.forEach((row, i) => {
            console.log(`  Movimiento ${i + 1} (${row.observations}): Consumió ${row.quantity} unidades a un costo de $${row.unit_price}`);
        });

        console.log('\n🎉 ¡TODAS LAS PRUEBAS DE AUDITORÍA PEPS PASARON EXITOSAMENTE! 🏆');
    } catch (err) {
        console.error('\n❌ ERROR DURANTE LA AUDITORÍA PEPS:');
        console.error(err);
        if (err.precedingErrors) {
            console.error('Preceding Errors:', err.precedingErrors);
        }
    } finally {
        if (pool) {
            await pool.close();
            console.log('🔌 Conexión a la base de datos cerrada.');
        }
    }
}

runTests();
