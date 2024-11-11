import numpy as np
import pandas as pd
from flask import Flask, jsonify, request
from flask_cors import CORS

from estimate_waiting_time_model import FoodTimePredictorModel

app = Flask(__name__)
CORS(app)

# Create and train the predictor model
predictor = FoodTimePredictorModel()
data = pd.read_csv('./assets/ml_dataset/canteen_data.csv')  # Ensure the correct path to your CSV
predictor.train(data)  # Train the model on startup


@app.route('/estimate_wait_time', methods=['POST'])
def estimate_wait_time():
    try:
        data = request.json
        item_name = data.get('item_name')
        order_time = data.get('order_time')
        day_of_week = data.get('day_of_week')

        # Get the predicted waiting time from your model
        predicted_wait_time = predictor.predict_waiting_time(item_name, order_time, day_of_week)

        if isinstance(predicted_wait_time, (np.float32, np.float64)):
            predicted_wait_time = float(predicted_wait_time)

        print("ESTIMATE", item_name, predicted_wait_time)

        return jsonify({
            'item_name': item_name,
            'estimated_wait_time': predicted_wait_time,
            'order_time': order_time,
            'day_of_week': day_of_week
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
