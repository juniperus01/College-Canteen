import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler


class FoodTimePredictorModel:
    def __init__(self):
        self.le_dish = LabelEncoder()
        self.le_day = LabelEncoder()
        self.scaler = StandardScaler()
        self.model = RandomForestRegressor(
            n_estimators=200,
            max_depth=10,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=42
        )

    def prepare_features(self, df):
        # Encode categorical variables
        # Fit the label encoders only on the training data
        self.le_dish.fit(df['Dish Name'])
        self.le_day.fit(df['Day of Week'])
        
        dish_encoded = self.le_dish.transform(df['Dish Name'])
        day_encoded = self.le_day.transform(df['Day of Week'])

        # Process time slots
        df['Start_Hour'] = df['Timing Slot'].apply(lambda x: int(x.split('-')
                                                                 [0].split()[0]
                                                                 ))
        df['End_Hour'] = df['Timing Slot'].apply(lambda x: int(x.split('-')[1].
                                                               split()[0]))

        # Adjust for PM times
        pm_mask = df['Timing Slot'].str.contains('PM')
        df.loc[pm_mask & (df['Start_Hour'] != 12), 'Start_Hour'] += 12
        df.loc[pm_mask & (df['End_Hour'] != 12), 'End_Hour'] += 12

        # Combine features
        X = np.column_stack((
            dish_encoded,
            day_encoded,
            df['Start_Hour'],
            df['End_Hour']
        ))

        return self.scaler.fit_transform(X)

    def train(self, df):
        # Prepare features and target
        X = self.prepare_features(df)
        y = df['Time Estimation'].values

        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )

        # Train model
        self.model.fit(X_train, y_train)

        # Make predictions on test set
        y_pred = self.model.predict(X_test)

        # Calculate metrics
        rmse = np.sqrt(mean_squared_error(y_test, y_pred))
        mae = mean_absolute_error(y_test, y_pred)
        r2 = r2_score(y_test, y_pred)

        # Perform cross-validation
        cv_scores = cross_val_score(self.model, X, y, cv=5)

        return {
            'rmse': rmse,
            'mae': mae,
            'r2': r2,
            'cv_mean': cv_scores.mean(),
            'cv_std': cv_scores.std(),
            'test_predictions': y_pred,
            'test_actual': y_test
        }

    def predict_waiting_time(self, dish_name, time, day):
        time_slot = convert_to_time_slot(time)
        
        # Prepare single prediction features
        dish_encoded = self.le_dish.transform([dish_name])
        day_encoded = self.le_day.transform([day])

        # Process time slot
        start_hour = int(time_slot.split('-')[0].split()[0])
        end_hour = int(time_slot.split('-')[1].split()[0])
        if 'PM' in time_slot and start_hour != 12:
            start_hour += 12
        if 'PM' in time_slot and end_hour != 12:
            end_hour += 12

        # Create feature vector
        X = np.array([[
            dish_encoded[0],
            day_encoded[0],
            start_hour,
            end_hour
        ]])

        # Scale and predict
        X_scaled = self.scaler.transform(X)
        return round(float(self.model.predict(X_scaled)[0]), 1)


def convert_to_time_slot(time_str):
    # Convert the input time string into hours and minutes
    hours, minutes = map(int, time_str.split(':'))
    
    # Determine the start hour for the time slot
    start_hour = (hours % 12) or 12  # Convert to 12-hour format,
    end_hour = start_hour + 1  # The end hour is one hour later

    # Determine AM/PM based on the original hour
    period = 'AM' if hours < 12 else 'PM'

    # Format the time slot string
    time_slot = f"{start_hour}-{end_hour} {period}"
    
    return time_slot


def predict_waiting_time(dish_name, time, day):
    model_instance = FoodTimePredictorModel()
    time_slot = convert_to_time_slot(time)
    return model_instance.predict_waiting_time(dish_name, time_slot, day)


if __name__ == '__main__':
    # Load the data
    data = pd.read_csv('./assets/ml_dataset/canteen_data.csv')
    
    # Create an instance of the model
    predictor = FoodTimePredictorModel()
    
    # Train the model
    metrics = predictor.train(data)
    
    # Print the evaluation metrics
    print("Training completed with metrics:")
    print(f"RMSE: {metrics['rmse']}")
    print(f"MAE: {metrics['mae']}")
    print(f"R^2: {metrics['r2']}")
    print(f"Cross-validation mean: {metrics['cv_mean']}")
    print(f"Cross-validation std: {metrics['cv_std']}")

