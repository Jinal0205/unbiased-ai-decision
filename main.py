import os
from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
from aif360.datasets import BinaryLabelDataset
from aif360.metrics import BinaryLabelDatasetMetric

app = Flask(__name__)
CORS(app)

def calculate_bias(data_list):
    df = pd.DataFrame(data_list)
    # BinaryLabelDataset: decision (1=Approve, 0=Deny), protected_attr (1=Privileged, 0=Minority)
    dataset = BinaryLabelDataset(df=df, label_name='decision', protected_attribute_names=['protected_attr'])
    
    metric = BinaryLabelDatasetMetric(dataset, 
                                     unprivileged_groups=[{'protected_attr': 0}],
                                     privileged_groups=[{'protected_attr': 1}])
    return metric.disparate_impact()

@app.route('/analyze', methods=['POST'])
def analyze():
    content = request.json
    raw_data = content.get('data', [])
    
    if not raw_data:
        return jsonify({"error": "No data provided"}), 400

    score = calculate_bias(raw_data)
    
    # Logic for Google Solution Challenge Impact
    status = "FAIR" if score >= 0.8 else "BIASED"
    recommendation = "Maintain current parameters." if status == "FAIR" else "Adjust decision thresholds for unprivileged groups."
    
    return jsonify({
        "disparate_impact_score": round(score, 3),
        "status": status,
        "recommendation": recommendation,
        "sdg_target": "Goal 10: Reduced Inequalities"
    })

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=int(os.environ.get("PORT", 8080)))