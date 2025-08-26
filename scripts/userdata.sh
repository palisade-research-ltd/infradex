#!/bin/bash

# Update system and install dependencies
yum update -y
yum install -y git curl wget unzip

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create directories for our services
mkdir -p /opt/data-pipeline/{data-pipeline,ml-service,clickhouse,logs,data}
chmod -R 755 /opt/data-pipeline
chown -R ec2-user:ec2-user /opt/data-pipeline

# Create Data Pipeline Dockerfile
cat <<'EOF' > /opt/data-pipeline/data-pipeline/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p logs data

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start the application
CMD ["python", "pipeline.py"]
EOF

# Create Data Pipeline requirements.txt
cat <<'EOF' > /opt/data-pipeline/data-pipeline/requirements.txt
flask==2.3.3
pandas==2.1.1
numpy==1.24.3
requests==2.31.0
clickhouse-driver==0.2.6
schedule==1.2.0
python-dotenv==1.0.0
pyyaml==6.0.1
uvicorn==0.23.2
fastapi==0.103.1
EOF

# Create Data Pipeline application
cat <<'EOF' > /opt/data-pipeline/data-pipeline/pipeline.py
from flask import Flask, jsonify, request
import pandas as pd
import numpy as np
import requests
import schedule
import time
import threading
from datetime import datetime, timedelta
import logging
import os
from clickhouse_driver import Client
import yaml

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
CLICKHOUSE_HOST = os.getenv('CLICKHOUSE_HOST', 'localhost')
CLICKHOUSE_PORT = int(os.getenv('CLICKHOUSE_PORT', 8123))

class DataPipeline:
    def __init__(self):
        self.clickhouse_client = None
        self.connect_to_clickhouse()
        self.setup_database()

    def connect_to_clickhouse(self):
        """Connect to ClickHouse database"""
        try:
            self.clickhouse_client = Client(host=CLICKHOUSE_HOST, port=CLICKHOUSE_PORT)
            logger.info("Connected to ClickHouse successfully")
        except Exception as e:
            logger.error(f"Failed to connect to ClickHouse: {e}")

    def setup_database(self):
        """Setup initial database schema"""
        try:
            # Create sample data table
            create_table_query = '''
            CREATE TABLE IF NOT EXISTS sample_data (
                id UInt64,
                timestamp DateTime,
                value Float64,
                category String,
                processed_at DateTime DEFAULT now()
            ) ENGINE = MergeTree()
            ORDER BY (timestamp, id)
            '''
            self.clickhouse_client.execute(create_table_query)
            logger.info("Database schema setup completed")
        except Exception as e:
            logger.error(f"Failed to setup database: {e}")

    def generate_sample_data(self, n=100):
        """Generate sample data for the pipeline"""
        data = []
        for i in range(n):
            data.append({
                'id': i,
                'timestamp': datetime.now() - timedelta(seconds=np.random.randint(0, 3600)),
                'value': np.random.normal(100, 15),
                'category': np.random.choice(['A', 'B', 'C'])
            })
        return data

    def process_data(self):
        """Main data processing logic"""
        try:
            logger.info("Starting data processing...")
            
            # Generate sample data (in real scenario, this would come from external sources)
            data = self.generate_sample_data()
            
            # Transform data
            df = pd.DataFrame(data)
            df['value_normalized'] = (df['value'] - df['value'].mean()) / df['value'].std()
            
            # Insert into ClickHouse
            insert_query = '''
            INSERT INTO sample_data (id, timestamp, value, category) VALUES
            '''
            
            for _, row in df.iterrows():
                self.clickhouse_client.execute(
                    "INSERT INTO sample_data (id, timestamp, value, category) VALUES",
                    [(row['id'], row['timestamp'], row['value'], row['category'])]
                )
            
            logger.info(f"Processed and inserted {len(data)} records")
            return True
            
        except Exception as e:
            logger.error(f"Data processing failed: {e}")
            return False

    def get_pipeline_stats(self):
        """Get pipeline statistics"""
        try:
            result = self.clickhouse_client.execute('''
                SELECT 
                    count() as total_records,
                    avg(value) as avg_value,
                    max(processed_at) as last_processed
                FROM sample_data
            ''')
            return result[0] if result else (0, 0, None)
        except Exception as e:
            logger.error(f"Failed to get stats: {e}")
            return (0, 0, None)

# Initialize pipeline
pipeline = DataPipeline()

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})

@app.route('/process')
def process_data():
    """Trigger data processing manually"""
    success = pipeline.process_data()
    return jsonify({"success": success, "timestamp": datetime.now().isoformat()})

@app.route('/stats')
def get_stats():
    """Get pipeline statistics"""
    total, avg_val, last_processed = pipeline.get_pipeline_stats()
    return jsonify({
        "total_records": total,
        "average_value": avg_val,
        "last_processed": last_processed.isoformat() if last_processed else None
    })

# Schedule automatic data processing
def run_scheduled_tasks():
    """Run scheduled tasks in background"""
    schedule.every(5).minutes.do(pipeline.process_data)
    
    while True:
        schedule.run_pending()
        time.sleep(1)

# Start background scheduler
scheduler_thread = threading.Thread(target=run_scheduled_tasks, daemon=True)
scheduler_thread.start()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
EOF

# Create ML Service Dockerfile
cat <<'EOF' > /opt/data-pipeline/ml-service/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p logs models

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Start the application
CMD ["python", "model_service.py"]
EOF

# Create ML Service requirements.txt
cat <<'EOF' > /opt/data-pipeline/ml-service/requirements.txt
flask==2.3.3
scikit-learn==1.3.0
pandas==2.1.1
numpy==1.24.3
joblib==1.3.2
clickhouse-driver==0.2.6
python-dotenv==1.0.0
matplotlib==3.7.2
seaborn==0.12.2
EOF

# Create ML Service application
cat <<'EOF' > /opt/data-pipeline/ml-service/model_service.py
from flask import Flask, request, jsonify
import pandas as pd
import numpy as np
import pickle
import joblib
import logging
from datetime import datetime
import os
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
from clickhouse_driver import Client

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
MODEL_PATH = os.getenv('MODEL_PATH', '/app/models')
CLICKHOUSE_HOST = os.getenv('CLICKHOUSE_HOST', 'localhost')
CLICKHOUSE_PORT = int(os.getenv('CLICKHOUSE_PORT', 8123))

class MLService:
    def __init__(self):
        self.model = None
        self.model_version = None
        self.clickhouse_client = None
        self.connect_to_clickhouse()
        self.load_or_train_model()

    def connect_to_clickhouse(self):
        """Connect to ClickHouse database"""
        try:
            self.clickhouse_client = Client(host=CLICKHOUSE_HOST, port=CLICKHOUSE_PORT)
            logger.info("Connected to ClickHouse successfully")
        except Exception as e:
            logger.error(f"Failed to connect to ClickHouse: {e}")

    def load_or_train_model(self):
        """Load existing model or train a new one"""
        model_file = os.path.join(MODEL_PATH, 'model.pkl')
        
        if os.path.exists(model_file):
            try:
                self.model = joblib.load(model_file)
                self.model_version = datetime.now().strftime("%Y%m%d_%H%M%S")
                logger.info("Model loaded successfully")
            except Exception as e:
                logger.error(f"Failed to load model: {e}")
                self.train_new_model()
        else:
            self.train_new_model()

    def train_new_model(self):
        """Train a new model with sample data"""
        try:
            logger.info("Training new model...")
            
            # Generate sample data for training
            X, y = self.generate_training_data()
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42
            )
            
            # Train model
            self.model = RandomForestClassifier(n_estimators=100, random_state=42)
            self.model.fit(X_train, y_train)
            
            # Evaluate model
            y_pred = self.model.predict(X_test)
            accuracy = accuracy_score(y_test, y_pred)
            
            logger.info(f"Model trained with accuracy: {accuracy:.4f}")
            
            # Save model
            os.makedirs(MODEL_PATH, exist_ok=True)
            model_file = os.path.join(MODEL_PATH, 'model.pkl')
            joblib.dump(self.model, model_file)
            
            self.model_version = datetime.now().strftime("%Y%m%d_%H%M%S")
            logger.info("Model saved successfully")
            
        except Exception as e:
            logger.error(f"Failed to train model: {e}")

    def generate_training_data(self, n=1000):
        """Generate sample training data"""
        np.random.seed(42)
        
        # Generate features
        feature1 = np.random.normal(0, 1, n)
        feature2 = np.random.normal(0, 1, n)
        feature3 = np.random.normal(0, 1, n)
        
        # Generate target based on features
        y = (feature1 + feature2 - feature3 > 0).astype(int)
        
        X = np.column_stack([feature1, feature2, feature3])
        
        return X, y

    def predict(self, features):
        """Make predictions using the trained model"""
        if self.model is None:
            raise ValueError("Model not trained or loaded")
        
        # Ensure features is a 2D array
        if isinstance(features, list):
            features = np.array(features).reshape(1, -1)
        elif len(features.shape) == 1:
            features = features.reshape(1, -1)
        
        prediction = self.model.predict(features)
        probabilities = self.model.predict_proba(features)
        
        return {
            'prediction': prediction.tolist(),
            'probabilities': probabilities.tolist(),
            'model_version': self.model_version
        }

    def get_model_info(self):
        """Get model information"""
        return {
            'model_type': 'RandomForestClassifier',
            'model_version': self.model_version,
            'is_trained': self.model is not None,
            'features_expected': 3
        }

# Initialize ML service
ml_service = MLService()

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy", 
        "timestamp": datetime.now().isoformat(),
        "model_loaded": ml_service.model is not None
    })

@app.route('/predict', methods=['POST'])
def predict():
    """Prediction endpoint"""
    try:
        data = request.json
        if 'features' not in data:
            return jsonify({"error": "Missing 'features' in request"}), 400
        
        features = data['features']
        result = ml_service.predict(features)
        
        return jsonify({
            "success": True,
            "result": result,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/model-info')
def model_info():
    """Get model information"""
    return jsonify(ml_service.get_model_info())

@app.route('/retrain', methods=['POST'])
def retrain():
    """Retrain the model"""
    try:
        ml_service.train_new_model()
        return jsonify({
            "success": True,
            "message": "Model retrained successfully",
            "model_version": ml_service.model_version,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Retraining error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Create directories for data and logs
mkdir -p /opt/data-pipeline/{data/{clickhouse,pipeline,models},logs/{clickhouse,data-pipeline,ml-service}}

# Set permissions
chown -R ec2-user:ec2-user /opt/data-pipeline

# Start the services
cd /opt/data-pipeline
docker-compose up -d

# Create systemd service for auto-start
cat <<'EOF' > /etc/systemd/system/data-pipeline.service
[Unit]
Description=Data Pipeline Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/data-pipeline
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl enable data-pipeline.service

# Wait for services to start
sleep 30

# Test services
echo "Testing services..."
curl -f http://localhost:8123/ping || echo "ClickHouse not ready"
curl -f http://localhost:8080/health || echo "Data Pipeline not ready"
curl -f http://localhost:5000/health || echo "ML Service not ready"

logger.info "Data pipeline setup completed successfully"
