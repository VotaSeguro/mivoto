from flask import Flask, render_template, request, abort

form_app = Flask(__name__)


@form_app.route('/tu-formulario') 
def mostrar_formulario():
    token_recibido = request.args.get('token')

    if not token_recibido:
        abort(400, description="Falta el token de acceso en la URL.")

   
    return render_template('form.html', token=token_recibido)

if __name__ == '__main__':
   
    print("Servidor del formulario iniciado en http://127.0.0.1:5001")
    form_app.run(port=5001, debug=True) 