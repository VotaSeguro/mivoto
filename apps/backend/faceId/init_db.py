import sqlite3

DB_NAME = 'votacion.db'

conn = sqlite3.connect(DB_NAME)
cursor = conn.cursor()

cursor.execute('''
CREATE TABLE IF NOT EXISTS votantes (
    clave_lector TEXT PRIMARY KEY,
    nombre_completo TEXT NOT NULL,
    correo TEXT NOT NULL UNIQUE,
    ya_voto BOOLEAN NOT NULL DEFAULT 0
)
''')


votantes_iniciales = [
    ('RJGMVC04111314H400', 'Victor Alejandro Rojas Gamez', 'vr3hackveneno@gmail.com', 0),
    ('RDLPAL04120487H700', 'Alejandro Rodriguez Lopez', 'likesupergamer@gmail.com', 0),
    ('OCGZKN06100814H800', 'Kanet Sahid Ochoa Guzman', 'kanetsahid@gmail.com', 0), 
]

cursor.executemany('INSERT OR IGNORE INTO votantes (clave_lector, nombre_completo, correo, ya_voto) VALUES (?, ?, ?, ?)', votantes_iniciales)

conn.commit()
conn.close()

print(f"Base de datos '{DB_NAME}' inicializada/verificada.")