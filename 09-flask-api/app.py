from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"message": "Hello from Flask API!"})

@app.route('/api/users')
def users():
    return jsonify({"users": [
        {"id": 1, "name": "Alice"},
        {"id": 2, "name": "Bob"}
    ]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
