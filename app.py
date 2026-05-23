from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
# Initialize Prometheus metrics (automatically exposes the /metrics endpoint)
metrics = PrometheusMetrics(app)

# Add static information as a metric for tracking app versions in Prometheus
metrics.info('app_info', 'Application info', version='1.0.0')

@app.route('/')
def home():
    return "Hello from Flask app deployed via Jenkins CI/CD!"

@app.route('/health')
@metrics.do_not_track()  # Exclude health checks from metrics to avoid noise
def health():
    return {'status': 'ok'}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
