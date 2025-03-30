import cv2
import qrcode
import uuid
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import time
import threading 
from flask import Flask, request, jsonify, render_template, redirect, url_for, flash, session
from flask_cors import CORS
from PIL import Image
import io
import os
import numpy as np
import face_recognition
from datetime import datetime
import sqlite3 
import queue 

#Variables de entorno
KNOWN_FACES_DIR = 'known_faces'
BASE_FORM_URL = "http://127.0.0.1:5001/tu-formulario"
EMAIL_ADDRESS = "varg.finance@gmail.com"
EMAIL_PASSWORD = "glwf qhhq lagx kgnf" 
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
FACE_MATCH_TOLERANCE = 0.45 #Lo minimo necesario para identificar una cara
DB_NAME = 'votacion.db'
PORT = 8000 

app = Flask(__name__)
CORS(app)
app.secret_key = 'tu_super_secreto_key_para_flask_session'


camera_trigger_queue = queue.Queue()


TOKENS_PENDIENTES = {}
active_qr_person_id = None
active_qr_image = None

#Funcion para cargar imagen guardada y codificar lo encodings
def load_and_encode_single_face(clave_lector):
    print(f"Intentando codificar cara para: {clave_lector}") 

    base_path = os.path.join(KNOWN_FACES_DIR, clave_lector) #Se accede a la carpeta known_faces y busca la imagen con el nombre del lector
    possible_extensions = ['.jpg', '.png', '.jpeg']
    image_path = None
    for ext in possible_extensions:
        if os.path.exists(base_path + ext):
            image_path = base_path + ext
            break

    if not image_path:
        print(f"Error: Imagen no encontrada para {clave_lector} en {KNOWN_FACES_DIR}")
        return None 

    try:
        known_image = face_recognition.load_image_file(image_path)
        encodings = face_recognition.face_encodings(known_image)

        if encodings:
            encoding = encodings[0] 
            print(f"-> Codificada cara para {clave_lector}")
            return encoding 
        else:
             print(f"Advertencia: No se encontró cara en la imagen de referencia para {clave_lector} ({image_path}).")
             return None 

    except Exception as e:
        print(f"Error CRÍTICO procesando imagen para {clave_lector} en {image_path}.")
        print(f"Detalle de la excepción: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        return None 

#Se genera un qr con un token dinamico para prevenir fraudes 
def generar_qr_con_token(clave_lector_votante):
    global active_qr_person_id, active_qr_image, TOKENS_PENDIENTES
    
    token = str(uuid.uuid4())
    TOKENS_PENDIENTES[token] = clave_lector_votante
    form_url = f"{BASE_FORM_URL}?token={token}"
    print(f"Generando QR para Clave Lector {clave_lector_votante}: {form_url}")

    qr = qrcode.QRCode(version=1, error_correction=qrcode.constants.ERROR_CORRECT_L, box_size=10, border=4)
    qr.add_data(form_url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white").convert('RGB')
    img_open_cv = np.array(img)[:, :, ::-1].copy()

    active_qr_person_id = clave_lector_votante
    active_qr_image = img_open_cv

    print(f"Token {token} asociado a Clave Lector {clave_lector_votante}")

#Enviar un correo de confirmacion al momento de votar
def enviar_correo_confirmacion(destinatario_email, nombre_persona, submission_time):
     print(f"Intentando enviar correo a {destinatario_email}...")

     formatted_time = submission_time.strftime("%Y-%m-%d a las %H:%M:%S") 

     try:
         msg = MIMEMultipart()
         msg['From'] = EMAIL_ADDRESS
         msg['To'] = destinatario_email
         msg['Subject'] = "Confirmación de tu Votación" 

         cuerpo_mensaje = f"Hola {nombre_persona},\n\n"
         cuerpo_mensaje += "¡Felicidades por ejercer tu voto!\n\n"
         cuerpo_mensaje += f"Tu voto fue registrado exitosamente el {formatted_time}.\n"
         cuerpo_mensaje += "Si tienes alguna duda sobre este proceso o sientes que hubo alguna irregularidad, "
         cuerpo_mensaje += "por favor contáctanos respondiendo a este correo o escribiendo a correo@inventado.com.\n\n" 
         cuerpo_mensaje += "Gracias por tu participación."

         msg.attach(MIMEText(cuerpo_mensaje, 'plain'))

         server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
         server.starttls()
         server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
         texto = msg.as_string()
         server.sendmail(EMAIL_ADDRESS, destinatario_email, texto)
         server.quit()
         print(f"Correo enviado exitosamente a {destinatario_email}")
         return True
     except smtplib.SMTPAuthenticationError:
         print(f"Error de autenticación SMTP.")
         return False
     except Exception as e:
         print(f"Error al enviar correo a {destinatario_email}: {e}")
         return False

#Se abre la camara para validar la identidad de la persona
def procesar_camara_para_uno(target_encoding, target_clave_lector, votante_nombre):
    global active_qr_person_id, active_qr_image

    print(f"\n[Hilo Principal] Iniciando cámara para verificar: {votante_nombre} ({target_clave_lector})")
    match_found_and_qr_generated = False
    qr_generated_in_this_run = False

    cap = cv2.VideoCapture(0)
    if not cap.isOpened(): print("Error: No se pudo abrir la cámara."); return False

    qr_window_name = 'Escanea este QR para Votar'

    while True: 
        ret, frame = cap.read()
        if not ret: time.sleep(0.1); continue

       
        small_frame = cv2.resize(frame, (0, 0), fx=0.25, fy=0.25)
        rgb_small_frame = cv2.cvtColor(small_frame, cv2.COLOR_BGR2RGB)
        face_locations = face_recognition.face_locations(rgb_small_frame)
        face_encodings_in_frame = face_recognition.face_encodings(rgb_small_frame, face_locations)
        found_match_in_frame = False
        for face_encoding, face_location in zip(face_encodings_in_frame, face_locations):
            match = face_recognition.compare_faces([target_encoding], face_encoding, tolerance=FACE_MATCH_TOLERANCE)
            top, right, bottom, left = face_location; top *= 4; right *= 4; bottom *= 4; left *= 4
            label = "Buscando..."; color = (0, 255, 255)
            if match[0]:
                label = f"{votante_nombre} (Coincide!)"; color = (0, 255, 0)
                found_match_in_frame = True
                if not match_found_and_qr_generated:
                    print(f"[Hilo Principal] ¡Coincidencia Válida! Persona: {votante_nombre}. Generando QR.")
                    generar_qr_con_token(target_clave_lector)
                    match_found_and_qr_generated = True
                    qr_generated_in_this_run = True
            else: label = "Rostro no coincide"; color = (0, 0, 255)
            cv2.rectangle(frame, (left, top), (right, bottom), color, 2)
            cv2.rectangle(frame, (left, bottom - 35), (right, bottom), color, cv2.FILLED)
            cv2.putText(frame, label, (left + 6, bottom - 6), cv2.FONT_HERSHEY_DUPLEX, 0.8, (0, 0, 0), 1)

        cv2.imshow(f'Verificando: {votante_nombre} - Presiona Q para salir', frame)

        should_show_qr = active_qr_image is not None; qr_window_visible = False
        try:
            if cv2.getWindowProperty(qr_window_name, cv2.WND_PROP_VISIBLE) >= 1: qr_window_visible = True
        except cv2.error: pass
        if should_show_qr: cv2.imshow(qr_window_name, active_qr_image)
        elif qr_window_visible: 
            try: 
                cv2.destroyWindow(qr_window_name); 
            except cv2.error: pass

        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            print("[Hilo Principal] Verificación cancelada manualmente.")
            break

    print("[Hilo Principal] Cerrando cámara...")
    cap.release()
    cv2.destroyAllWindows()
    try: cv2.destroyWindow(qr_window_name); 
    except cv2.error: pass
    print("[Hilo Principal] Proceso de cámara terminado.")
    active_qr_person_id = None; active_qr_image = None
    return qr_generated_in_this_run

#Ruta para renderizar la pagina principal
@app.route('/', methods=['GET'])
def index():
    return render_template('ingreso_clave.html')

#Ruta para verificar la clave del lector y verificar si ya voto
@app.route('/verificar', methods=['POST'])
def verificar_clave():

    clave_procesada = request.form.get('clave_lector', '').strip().upper()
    print("-" * 30)
    print(f"[Flask] Verificando clave: '{clave_procesada}'")

    if not clave_procesada or len(clave_procesada) != 18:
        flash('Clave inválida.', 'error'); print("[Flask] Error: Clave inválida."); print("-" * 30)
        return redirect(url_for('index'))

    votante_data = None; conn = None
    try:
        conn = sqlite3.connect(DB_NAME); cursor = conn.cursor()
        cursor.execute("SELECT nombre_completo, correo, ya_voto FROM votantes WHERE clave_lector = ?", (clave_procesada,))
        votante_data = cursor.fetchone()
    except sqlite3.Error as e: print(f"Error DB: {e}"); flash('Error DB.', 'error'); return redirect(url_for('index'))
    finally:
        if conn: conn.close()

    if not votante_data:
        flash(f'Clave "{clave_procesada}" no encontrada.', 'error'); print("[Flask] No encontrado."); print("-" * 30)
        return redirect(url_for('index'))

    nombre_completo, correo, ya_voto_db = votante_data
    ya_voto = bool(ya_voto_db)
    print(f"[Flask] Encontrado: {nombre_completo}, Votó: {ya_voto}")

    if ya_voto:
        flash(f'{nombre_completo}, ya ha votado.', 'warning'); print("[Flask] Ya votó."); print("-" * 30)
        return redirect(url_for('index'))

    target_encoding = load_and_encode_single_face(clave_procesada)
    if target_encoding is None:
        flash(f'Error img para {nombre_completo}.', 'error'); print("[Flask] Error encoding."); print("-" * 30)
        return redirect(url_for('index'))

    print(f"[Flask] Poniendo datos en la cola para iniciar cámara para {nombre_completo}")
    camera_trigger_queue.put((target_encoding, clave_procesada, nombre_completo))
    
    flash(f'Iniciando verificación para {nombre_completo}. Una ventana de cámara debería abrirse pronto.', 'info')
    print("[Flask] Redirigiendo a index mientras hilo principal procesa cámara.")
    print("-" * 30)
    return redirect(url_for('index'))

#Ruta para renderizar el formulario
@app.route('/api/submit-form', methods=['POST'])
def handle_form_submission():
   
    data = request.json
    print(f"Recibida llamada API para registrar voto: {data}") 

    token_recibido = data.get('token')

   
    if not token_recibido:
        return jsonify({"error": "Faltan datos (token)"}), 400

   
    if token_recibido in TOKENS_PENDIENTES:
       
        clave_lector_a_actualizar = TOKENS_PENDIENTES[token_recibido]
        print(f"Intentando actualizar estado para: {clave_lector_a_actualizar}")

        conn = None
        votante_correo = None
        votante_nombre = None
        actualizacion_exitosa = False
        ya_habia_votado = False 

        try:
            conn = sqlite3.connect(DB_NAME)
            cursor = conn.cursor()

            print(f"Ejecutando SELECT para {clave_lector_a_actualizar}")
            cursor.execute("SELECT nombre_completo, correo, ya_voto FROM votantes WHERE clave_lector = ?", (clave_lector_a_actualizar,))
            votante_info = cursor.fetchone() 

            if not votante_info:
                print(f"Error CRÍTICO: Votante {clave_lector_a_actualizar} no encontrado al intentar actualizar.")
                raise ValueError("Votante no encontrado para actualizar") 

            votante_nombre = votante_info[0]
            votante_correo = votante_info[1]
            ya_habia_votado = bool(votante_info[2]) 

            if ya_habia_votado:
                 print(f"Advertencia: Votante {clave_lector_a_actualizar} ya había votado (chequeo en API).")
                
                 actualizacion_exitosa = True
            else:
                print(f"Ejecutando UPDATE para {clave_lector_a_actualizar}")
                cursor.execute("UPDATE votantes SET ya_voto = 1 WHERE clave_lector = ?", (clave_lector_a_actualizar,))
               
                conn.commit()

             
                if cursor.rowcount > 0:
                    print("Actualización en DB exitosa.")
                    actualizacion_exitosa = True
                else:
                   
                     print("Error: La actualización no afectó ninguna fila.")
                     raise sqlite3.Error("Update failed to affect rows")

       
        except (sqlite3.Error, ValueError) as e:
            print(f"Error al procesar la base de datos: {e}")
            votante_correo = None 
            actualizacion_exitosa = False 

       
        finally:
              
            if conn:
                conn.close()
           
            if token_recibido in TOKENS_PENDIENTES:
                print(f"Limpiando token: {token_recibido}")
                del TOKENS_PENDIENTES[token_recibido]

       
        if actualizacion_exitosa and not ya_habia_votado and votante_correo and votante_nombre:
            hora_actual = datetime.now()
            exito_correo = enviar_correo_confirmacion(votante_correo, votante_nombre, hora_actual)
            if exito_correo:
                return jsonify({"message": "Voto registrado y correo enviado."}), 200
            else:
                
                 return jsonify({"message": "Voto registrado, pero falló el envío del correo.", "warning": "email_failed"}), 200
       
        elif actualizacion_exitosa and ya_habia_votado:
             return jsonify({"message": "Este voto ya fue registrado anteriormente."}), 200
       
        else:
            return jsonify({"error": "Error interno al registrar el voto en la base de datos."}), 500

  
    else:
        print(f"Token inválido o expirado recibido: {token_recibido}")
       
        return jsonify({"error": "Token inválido o expirado."}), 400

def iniciar_servidor_flask_en_hilo():
    print(f"Iniciando servidor Flask en http://127.0.0.1:{PORT} (en hilo)")
    app.run(host='0.0.0.0', port=PORT, debug=False, use_reloader=False) 

if __name__ == "__main__":
    PORT = 8000
    if not os.path.exists(DB_NAME): print(f"ADVERTENCIA: DB '{DB_NAME}' no existe."); 

    flask_thread = threading.Thread(target=iniciar_servidor_flask_en_hilo, daemon=True)
    flask_thread.start()
    time.sleep(1) 

    print(f"\nServidor Flask corriendo en http://127.0.0.1:{PORT}")

    try:
        while True:
            try:
                trigger_data = camera_trigger_queue.get(block=True, timeout=1.0)

                target_encoding, clave, nombre = trigger_data
                print(f"\n[Hilo Principal] Datos recibidos de la cola. Iniciando cámara para {nombre}...")

                procesar_camara_para_uno(target_encoding, clave, nombre)

                print("\n[Hilo Principal] Proceso de cámara terminado. Esperando nueva señal...")

            except queue.Empty:
               
                pass
            except Exception as e:
                 print(f"[Hilo Principal] Error inesperado en bucle principal: {e}")
                 time.sleep(1) 

    except KeyboardInterrupt:
        print("\n[Hilo Principal] Proceso terminado por el usuario.")