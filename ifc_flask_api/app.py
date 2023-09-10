from flask import Flask, request, send_file

import subprocess
import os

app = Flask(__name__)

@app.route('/')
def index():
    return 'Startup page'

def ifc_to_glb(ifc_file, glb_file_path):
    # in production ifcconvert needs to be installed on the server and path to ifcconvert needs to be specified
    if os.path.exists(glb_file_path):
        os.remove(glb_file_path)

    ifc_file.save('temporary.ifc')
    command = f"/Applications/IfcConvert temporary.ifc {glb_file_path}"
    subprocess.run(command, shell=True)
    os.remove('temporary.ifc')

@app.route('/convert_ifc_to_glb', methods=['POST', 'GET'])
def convert_ifc_to_glb_endpoint():
    
    # file sent must be named 'ifc_file'
    ifc_file = request.files['ifc_file']
    
    glb_file_path = 'output.glb'
    
    ifc_to_glb(ifc_file, glb_file_path)
    
    return send_file(glb_file_path, as_attachment=True)

if __name__ == '__main__':
    app.run(debug=True)


