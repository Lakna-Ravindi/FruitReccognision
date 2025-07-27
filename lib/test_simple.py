from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/', methods=['GET'])
def home():
    return jsonify({'message': 'Server is running!'})

@app.route('/api/profile', methods=['POST'])
def test_profile():
    return jsonify({'message': 'Profile endpoint reached!'})

if __name__ == '__main__':
    print("=== Starting Flask server ===")
    app.run(host='127.0.0.1', port=5000, debug=True)
    print("=== Server started ===")