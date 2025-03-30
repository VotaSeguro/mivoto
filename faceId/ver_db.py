import sqlite3

DB_NAME = 'votacion.db'

try:
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()

    print("--- Contenido de la tabla 'votantes' ---")
    cursor.execute("SELECT clave_lector, nombre_completo, correo, ya_voto FROM votantes")

    column_names = [description[0] for description in cursor.description]
    print(column_names)
    print("-" * 50)

    rows = cursor.fetchall()

    if not rows:
        print("La tabla está vacía.")
    else:
        for row in rows:
            print(row) 

    print("-" * 50)

except sqlite3.Error as e:
    print(f"Error al conectar o leer la base de datos: {e}")
finally:
    if conn:
        conn.close()