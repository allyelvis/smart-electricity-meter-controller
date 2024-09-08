#!/bin/bash

# Update package list and upgrade existing packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Python, pip, and virtual environment
sudo apt-get install -y python3 python3-pip python3-venv

# Install SQLite for local database management
sudo apt-get install -y sqlite3

# Create a project directory
PROJECT_DIR=~/smart_meter_system
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Set up a Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install necessary Python packages
pip install flask sqlalchemy cryptography paho-mqtt

# Create the main Flask application file
cat <<EOF > app.py
from flask import Flask, request, jsonify
from sqlalchemy import create_engine, Column, Integer, String, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

app = Flask(__name__)
Base = declarative_base()

# Database setup
DATABASE_URL = "sqlite:///smart_meter.db"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Models
class Meter(Base):
    __tablename__ = 'meters'
    id = Column(Integer, primary_key=True, index=True)
    location = Column(String, index=True)
    reading = Column(Float)

Base.metadata.create_all(bind=engine)

@app.route('/data', methods=['POST'])
def receive_data():
    data = request.json
    db = SessionLocal()
    meter = Meter(location=data['location'], reading=data['reading'])
    db.add(meter)
    db.commit()
    db.refresh(meter)
    db.close()
    return jsonify({'status': 'success', 'data': data})

@app.route('/billing', methods=['GET'])
def get_billing_records():
    db = SessionLocal()
    meters = db.query(Meter).all()
    db.close()
    return jsonify([{'id': meter.id, 'location': meter.location, 'reading': meter.reading} for meter in meters])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Create a simple README file
cat <<EOF > README.md
# Smart Meter System

## Overview
This project provides a smart electricity meter controller and e-billing system. It includes a Flask application that stores meter readings and provides billing records.

## Setup
1. Clone the repository.
2. Create and activate a virtual environment:
    \`\`\`
    python3 -m venv venv
    source venv/bin/activate
    \`\`\`
3. Install dependencies:
    \`\`\`
    pip install -r requirements.txt
    \`\`\`
4. Run the application:
    \`\`\`
    python app.py
    \`\`\`

## Endpoints
- POST /data: Submit meter readings.
- GET /billing: Retrieve billing records.
EOF

# Generate requirements.txt for the project
pip freeze > requirements.txt

# Provide instructions to the user
echo "Smart meter system setup complete. Follow these steps to get started:"
echo "1. Navigate to the project directory: cd $PROJECT_DIR"
echo "2. Activate the virtual environment: source venv/bin/activate"
echo "3. Run the application: python app.py"
echo "4. Use POST /data to submit meter readings and GET /billing to retrieve billing records."

# Exit the script
exit 0
