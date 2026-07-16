from flask import Flask, jsonify
import os

app = Flask(__name__)

# The version environment variable helps verify deployments are actively updating
APP_VERSION = os.getenv("APP_VERSION", "v1.0.0")

@app.route("/")
def home():
    return jsonify({
        "service": "order-processing-api",
        "status": "online",
        "version": APP_VERSION,
        "message": "Continuous Deployment to Kubernetes via Bastion Complete!"
    })

# The critical path Kubernetes uses to gauge system health.
# A return status code of 200 tells K8s everything is running normally.
@app.route("/health")
def health_check():
    # Intentionally returning 500 to simulate a critical application crash!
    return jsonify({"status": "CRITICAL FAILURE"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)