from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import time

def buscar_cedula(nombre, primer_apellido, segundo_apellido):
    url = "https://www.cedulaprofesional.sep.gob.mx/cedula/presidencia/indexAvanzada.action"

    # Configuración de Selenium
    options = webdriver.ChromeOptions()
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")

    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    
    try:
        print("[INFO] Abriendo página...")
        driver.get(url)

        # Esperar a que los campos de entrada sean visibles
        wait = WebDriverWait(driver, 10)
        print("[INFO] Página cargada, esperando que los campos sean visibles...")

        print("[INFO] Ingresando datos en el formulario...")
        input_nombre = wait.until(EC.presence_of_element_located((By.ID, "nombre")))
        print(f"[INFO] Ingresando nombre: {nombre}")
        input_nombre.click()
        input_nombre.send_keys(nombre)

        input_paterno = wait.until(EC.presence_of_element_located((By.ID, "paterno")))
        print(f"[INFO] Ingresando apellido paterno: {primer_apellido}")
        input_paterno.click()
        input_paterno.send_keys(primer_apellido)

        input_materno = wait.until(EC.presence_of_element_located((By.ID, "materno")))
        print(f"[INFO] Ingresando apellido materno: {segundo_apellido}")
        input_materno.click()
        input_materno.send_keys(segundo_apellido)

        # Hacer clic en el botón "Consultar"
        boton_consultar = wait.until(EC.element_to_be_clickable((By.ID, "dijit_form_Button_0_label")))
        print("[INFO] Clic en botón 'Consultar'")
        boton_consultar.click()

        print("[INFO] Esperando resultados...")
        time.sleep(5)  # Esperar a que la tabla se cargue

        # Buscar el primer resultado en la tabla
        resultados = []
        try:
            print("[INFO] Buscando el primer resultado...")
            primer_resultado = wait.until(EC.presence_of_element_located((By.XPATH, "//td[@idx='0']")))
            primer_resultado.click()

            time.sleep(3)

            # Extraer la información relevante del HTML
            print("[INFO] Extrayendo datos...")
            page_source = driver.page_source
            soup = BeautifulSoup(page_source, 'html.parser')

    # Extraer la información relevante
            cedula = soup.find('div', {'id': 'detalleCedula'}).text.strip()
            nombre = soup.find('div', {'id': 'detalleNombre'}).text.strip()
            genero = soup.find('div', {'id': 'detalleGenero'}).text.strip()
            profesion = soup.find('div', {'id': 'detalleProfesion'}).text.strip()
            fecha = soup.find('div', {'id': 'detalleFecha'}).text.strip()
            institucion = soup.find('div', {'id': 'detalleInstitucion'}).text.strip()
            tipo = soup.find('div', {'id': 'detalleTipo'}).text.strip()

    # Imprimir el HTML en consola
            # Imprimir los datos extraídos
            print(f"[INFO] Cédula: {cedula}")
            print(f"[INFO] Nombre: {nombre}")
            print(f"[INFO] Género: {genero}")
            print(f"[INFO] Profesión: {profesion}")
            print(f"[INFO] Año de expedición: {fecha}")
            print(f"[INFO] Institución: {institucion}")
            print(f"[INFO] Tipo: {tipo}")
            cédula = driver.find_element(By.XPATH, "//td[contains(text(),'Cédula:')]/following-sibling::td").text
            nombre_completo = driver.find_element(By.XPATH, "//td[contains(text(),'Nombre:')]/following-sibling::td").text
            print(f"[INFO] Datos extraídos: Cédula={cédula}, Nombre={nombre_completo}")
            resultados.append({
                'cedula': cédula,
                'nombre': nombre_completo
            })
        except Exception as e:
            print("[INFO] No se encontraron resultados.")
            return None

        print("[INFO] Resultados encontrados: ", resultados)
        return resultados  # Devuelve los datos en formato de lista
    except Exception as e:
        print(f"[ERROR] Ocurrió un error: {e}")
    finally:
        print("[INFO] Cerrando navegador...")
        driver.quit()  # Cierra el navegador
