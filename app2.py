from distutils.command.config import config
import os
from flask import Flask, render_template, request, flash, request, redirect, url_for
from flask_cors import CORS
import subprocess
from pathlib import Path
from werkzeug.utils import secure_filename

UPLOAD_FOLDER = './uploaded_files'
ALLOWED_EXTENSIONS = {'zip', 'c', 'cpp'}

app = Flask(__name__, template_folder='.')
CORS(app)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['SECRET_KEY'] = 'fvbdgfbfg'


@app.route('/')
def hello():
    return render_template("index.html")


@app.route('/get_file')
def get_file():
    # get the source for this filename.
    file_path = request.args.get('see_sourcecode')
    contents = Path(file_path).read_text()
    return contents



@app.route('/optvis_request')
def optvis_request():
    command = request.args.get('command').split(' ') # /g/g0/pascal/inputs/1/a.out'
    out = subprocess.check_output( command )
    return out


def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# curl -XPOST http://172.17.0.2:5000/uploadandbuild -F file=@TestFile.c
@app.route('/uploadandbuild', methods=['GET', 'POST'])
def upload_build():
    if request.method == 'POST':
        # check if the post request has the file part
        if 'file' not in request.files:
            flash('No file part')
            return redirect(request.url)
        file = request.files['file']
        # If the user does not select a file, the browser submits an
        # empty file without a filename.
        if file.filename == '':
            flash('No selected file')
            return redirect(request.url)
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            # return redirect(url_for('download_file', name=filename))
            binary = filename.split('.')[0] + ".out"
            run_cmd = f"gcc -g -O0 {app.config['UPLOAD_FOLDER']}/{filename} -o {binary}"
            output, error = subprocess.Popen(run_cmd.split(), stdout=subprocess.PIPE).communicate()
            return {
                'result': 'success',
                'source': filename,
                'binary': binary
            }
    return {"result": "No files found"}