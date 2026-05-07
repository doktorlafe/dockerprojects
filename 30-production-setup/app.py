from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/api/data')
def data():
    return jsonify({"data": "production data"})

if __name__ == '__main__':
    app.run()
