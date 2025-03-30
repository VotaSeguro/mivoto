from django.shortcuts import render
import requests
from django.http import JsonResponse

from .scrapper import buscar_cedula
from django.views.decorators.csrf import csrf_exempt


def landing_page(request):
    return render(request, 'index.html')  # Llama al template landing.html
def votacion(request):
    return render(request, 'votacion.html')  # Llama al template landing.html
def identidad(request):
    return render(request, 'identidad.html')  # Llama al template landing.html
def informate(request):
    return render(request, 'informate.html')  # Llama al template landing.html
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

@csrf_exempt  # Si estás haciendo una solicitud GET sin CSRF
def consultar_datos(request):
    print("[INFO] Entrando en la vista consultar_datos")
    
    if request.method == "GET":
        nombre = request.GET.get("nombre", "").strip()
        paterno = request.GET.get("paterno", "").strip()
        materno = request.GET.get("materno", "").strip()
        
        print(f"[INFO] Recibiendo parámetros: nombre={nombre}, paterno={paterno}, materno={materno}")

        if nombre and paterno and materno:
            try:
                print("[INFO] Todos los campos están completos. Llamando a buscar_cedula...")
                datos = buscar_cedula(nombre, paterno, materno)
                print(f"[INFO] Datos recibidos de buscar_cedula: {datos}")

                if datos:
                    print("[INFO] Se encontraron datos, enviando respuesta JSON.")
                    return JsonResponse({"resultado": datos})
                else:
                    print("[INFO] No se encontraron datos.")
                    return JsonResponse({"error": "No se encontraron datos"}, status=404)
            except Exception as e:
                print(f"[ERROR] Ocurrió un error en la consulta con Selenium: {e}")
                return JsonResponse({"error": "Ocurrió un error en la consulta"}, status=500)
        else:
            print("[INFO] Faltan campos, regresando error.")
            return JsonResponse({"error": "Por favor, completa todos los campos"}, status=400)
    
    print("[INFO] Método no es GET, renderizando consulta_datos.html.")
    return render(request, 'consulta_datos.html')


# views.py
from django.shortcuts import render, redirect

def login_view(request):
    if request.method == 'POST':
        # Aquí no validamos los datos, simplemente redirigimos
        return redirect('identidad')  # Redirige a la URL de votación
    return render(request, 'loginidentidad.html')
