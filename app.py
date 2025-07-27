from flask import Flask, request, jsonify
from flask_cors import CORS
import tensorflow as tf
import numpy as np
from PIL import Image
from rdflib import Graph
import io
import logging

app = Flask(__name__)
CORS(app)
logging.basicConfig(level=logging.DEBUG)

# Paths to model and labels
MODEL_PATH = r"D:\fruit_nutrition_app\model\model.tflite"
LABELS_PATH = r"D:\fruit_nutrition_app\model\labels.txt"
OWL_PATH = r"D:\fruit_nutrition_app\fruit.owl"

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Load OWL ontology
g = Graph()
g.parse(OWL_PATH, format="xml")


# Load labels from file
def load_labels(path):
    with open(path, "r") as f:
        return [line.strip() for line in f.readlines()]

FRUIT_LABELS = load_labels(LABELS_PATH)
logging.debug(f"Labels loaded: {FRUIT_LABELS}")

def preprocess_image(image):
    img = image.resize((224, 224))
    img = np.array(img) / 255.0
    img = np.expand_dims(img, axis=0).astype(np.float32)
    return img

@app.route('/predict', methods=['POST'])
def predict():
    # Accept image via multipart or raw bytes
    if 'image' in request.files:
        image_file = request.files['image']
        image = Image.open(image_file.stream).convert('RGB')
    elif request.data:
        try:
            image = Image.open(io.BytesIO(request.data)).convert('RGB')
        except Exception as e:
            return jsonify({'error': f'Invalid image data: {str(e)}'}), 400
    else:
        return jsonify({'error': 'No image uploaded'}), 400

    input_data = preprocess_image(image)
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])

    pred_idx = int(np.argmax(output_data))
    try:
        fruit = FRUIT_LABELS[pred_idx]
    except IndexError:
        return jsonify({'error': 'Prediction index out of range'}), 500

    logging.debug(f"Predicted fruit: {fruit}")
    return jsonify({'fruit': fruit})

@app.route('/nutrition', methods=['POST'])
def nutrition():
    data = request.get_json()
    fruit = data.get('fruit')
    if not fruit:
        return jsonify({'error': 'No fruit name provided'}), 400

    logging.debug(f"Nutrition query for fruit: {fruit}")

    query = f"""
    PREFIX ns: <http://example.org/fruit_recommendation.owl#>
    SELECT ?calories ?sugar ?vitaminC WHERE {{
      ns:{fruit} ns:calories ?calories ;
                 ns:sugarContent ?sugar ;
                 ns:vitaminC ?vitaminC .
    }}
    """
    qres = g.query(query)
    results = list(qres)
    if not results:
        return jsonify({'error': 'Nutrition info not found for this fruit'}), 404

    row = results[0]
    return jsonify({
        'calories': str(row.calories),
        'sugarContent': str(row.sugar),
        'vitaminC': str(row.vitaminC)
    })
# NEW ENDPOINT: Profile submission from Flutter



@app.route('/api/profile', methods=['POST'])
def submit_profile():
    try:
        logging.debug("Profile submission endpoint called")
        
        # Get profile data from Flutter
        profile_data = request.get_json()
        logging.debug(f"Received profile data: {profile_data}")
        
        if not profile_data:
            return jsonify({'error': 'No profile data provided'}), 400
        
        # Validate required fields
        if 'name' not in profile_data or not str(profile_data['name']).strip():
           return jsonify({'error': 'name is required'}), 400

        if 'age' not in profile_data or not isinstance(profile_data['age'], int) or profile_data['age'] <= 0:
           return jsonify({'error': 'age must be a positive number'}), 400
        
        # Extract profile information
        name = profile_data.get('name')
        age = profile_data.get('age')
        gender = profile_data.get('gender', 'Female')
        fitness_goal = profile_data.get('fitnessGoal', 'None')
        dietary_preference = profile_data.get('dietaryPreference', 'None')
        health_conditions = profile_data.get('healthConditions', [])
        
        logging.debug(f"Processing profile for {name}, age {age}")
        
        # Generate personalized fruit recommendations
        recommendations = generate_personalized_recommendations(
            age=age,
            gender=gender,
            fitness_goal=fitness_goal,
            dietary_preference=dietary_preference,
            health_conditions=health_conditions
        )
        
        # Store profile (you can add database storage here)
        profile_response = {
            'name': name,
            'age': age,
            'gender': gender,
            'fitnessGoal': fitness_goal,
            'dietaryPreference': dietary_preference,
            'healthConditions': health_conditions
        }
        
        return jsonify({
            'success': True,
            'message': f'Profile created successfully for {name}',
            'profile': profile_response,
            'recommendations': recommendations
        })
        
    except Exception as e:
        logging.error(f"Error in profile submission: {str(e)}")
        import traceback
        logging.error(f"Traceback: {traceback.format_exc()}")
        return jsonify({'error': f'Server error: {str(e)}'}), 500

def generate_personalized_recommendations(age, gender, fitness_goal, dietary_preference, health_conditions):
    """Generate personalized fruit recommendations based on user profile"""
    try:
        logging.debug(f"Generating recommendations for: age={age}, gender={gender}, goal={fitness_goal}, diet={dietary_preference}, health={health_conditions}")
        
        # Get nutrition data from OWL ontology
        def get_fruit_nutrition_from_owl(fruit_name):
            try:
                # Handle the typo in OWL file - Strawberry is spelled as "Stawberry"
                owl_fruit_name = fruit_name.replace("Strawberry", "Stawberry")
                
                query = f"""
                PREFIX ns: <http://example.org/fruit_recommendation.owl#>
                SELECT ?calories ?sugar ?vitaminC WHERE {{
                  ns:{owl_fruit_name} ns:calories ?calories ;
                             ns:sugarContent ?sugar ;
                             ns:vitaminC ?vitaminC .
                }}
                """
                logging.debug(f"Querying OWL for: {owl_fruit_name}")
                qres = g.query(query)
                results = list(qres)
                
                if results:
                    row = results[0]
                    nutrition_data = {
                        "name": fruit_name,
                        "sugar": float(str(row.sugar)),
                        "calories": float(str(row.calories)),
                        "vitaminC": float(str(row.vitaminC))
                    }
                    logging.debug(f"Found nutrition data for {fruit_name}: {nutrition_data}")
                    return nutrition_data
                else:
                    logging.debug(f"No nutrition data found for {owl_fruit_name}")
                    return None
            except Exception as e:
                logging.error(f"Error querying OWL for {fruit_name}: {e}")
                return None

        # Get all available fruits from your labels
        fruits_data = []
        
        # Try to get data from OWL first
        for fruit_label in FRUIT_LABELS:
            nutrition = get_fruit_nutrition_from_owl(fruit_label)
            if nutrition:
                fruits_data.append(nutrition)
        
        logging.debug(f"Fruits data from OWL: {len(fruits_data)} items")
        
        # If OWL data is not available, fallback to hard-coded data
        # if not fruits_data:
        #     logging.warning("No nutrition data found in OWL, using fallback data")
        #     fruits_data = [
        #         {"name": "Apple_Unripe", "sugar": 8, "calories": 45, "vitaminC": 3},
        #         {"name": "Apple_Ripe", "sugar": 10, "calories": 52, "vitaminC": 4.6},
        #         {"name": "Apple_Overripe", "sugar": 12, "calories": 55, "vitaminC": 2.5},
        #         {"name": "Banana_Unripe", "sugar": 6, "calories": 89, "vitaminC": 8.7},
        #         {"name": "Banana_Ripe", "sugar": 12, "calories": 90, "vitaminC": 9},
        #         {"name": "Banana_Overripe", "sugar": 15, "calories": 95, "vitaminC": 6},
        #         {"name": "Dragonfruit_Unripe", "sugar": 6, "calories": 45, "vitaminC": 1.5},
        #         {"name": "Dragonfruit_Ripe", "sugar": 8, "calories": 50, "vitaminC": 3},
        #         {"name": "Mango_Unripe", "sugar": 6, "calories": 60, "vitaminC": 27},
        #         {"name": "Mango_Ripe", "sugar": 14, "calories": 70, "vitaminC": 36},
        #         {"name": "Mango_Overripe", "sugar": 16, "calories": 75, "vitaminC": 20},
        #         {"name": "Orange_Unripe", "sugar": 5, "calories": 40, "vitaminC": 40},
        #         {"name": "Orange_Ripe", "sugar": 9, "calories": 47, "vitaminC": 53},
        #         {"name": "Orange_Overripe", "sugar": 10, "calories": 50, "vitaminC": 30},
        #         {"name": "Strawberry_Unripe", "sugar": 3, "calories": 28, "vitaminC": 30},
        #         {"name": "Strawberry_Ripe", "sugar": 4.9, "calories": 32, "vitaminC": 59},
        #         {"name": "Strawberry_Overripe", "sugar": 5.5, "calories": 35, "vitaminC": 40}
        #     ]

        def passes_profile_rules(fruit):
            """Enhanced rule checking based on complete user profile"""
            logging.debug(f"Checking profile rules for: {fruit['name']}")
            
            # Age-based rules
            if age > 60:  # Senior citizens
                if fruit["sugar"] > 10:
                    logging.debug(f"  Rejected: Senior age rule (sugar {fruit['sugar']} > 10)")
                    return False
            elif age < 18:  # Young people
                if fruit["calories"] < 40:
                    logging.debug(f"  Rejected: Young age rule (calories {fruit['calories']} < 40)")
                    return False
            
            # Gender-based recommendations
            if gender == "Female":
                # Women generally need more vitamin C
                if fruit["vitaminC"] < 5:
                    logging.debug(f"  Rejected: Female gender rule (vitaminC {fruit['vitaminC']} < 5)")
                    return False
            
            # Health condition rules
            for condition in health_conditions:
                if condition == "Diabetes" and fruit["sugar"] > 8:
                    logging.debug(f"  Rejected: Diabetes rule (sugar {fruit['sugar']} > 8)")
                    return False
                if condition == "Hypertension" and fruit["calories"] > 60:
                    logging.debug(f"  Rejected: Hypertension rule (calories {fruit['calories']} > 60)")
                    return False
                if condition == "Allergies" and fruit["name"].startswith("Strawberry"):
                    logging.debug(f"  Rejected: Allergies rule (strawberry)")
                    return False
            
            # Dietary preference rules
            if dietary_preference == "Keto" and fruit["sugar"] > 6:
                logging.debug(f"  Rejected: Keto rule (sugar {fruit['sugar']} > 6)")
                return False
            elif dietary_preference == "Vegan":
                # All fruits are vegan, but prefer high vitamin C
                if fruit["vitaminC"] < 10:
                    logging.debug(f"  Rejected: Vegan rule (vitaminC {fruit['vitaminC']} < 10)")
                    return False
            elif dietary_preference == "Vegetarian":
                # Similar to vegan but less strict
                if fruit["vitaminC"] < 5:
                    logging.debug(f"  Rejected: Vegetarian rule (vitaminC {fruit['vitaminC']} < 5)")
                    return False
            
            # Fitness goal rules
            if fitness_goal == "Weight Loss" and fruit["calories"] > 55:
                logging.debug(f"  Rejected: Weight Loss rule (calories {fruit['calories']} > 55)")
                return False
            elif fitness_goal == "Muscle Gain":
                if fruit["calories"] < 50 or fruit["vitaminC"] < 8:
                    logging.debug(f"  Rejected: Muscle Gain rule (calories {fruit['calories']} < 50 or vitaminC {fruit['vitaminC']} < 8)")
                    return False
            
            logging.debug(f"  Accepted: {fruit['name']}")
            return True

        # Filter fruits based on profile rules
        recommended_fruits = []
        for fruit in fruits_data:
            if passes_profile_rules(fruit):
                # Add detailed recommendation info
                recommendation = {
                    "fruit": fruit["name"],
                    "reason": generate_recommendation_reason(fruit, age, gender, fitness_goal, dietary_preference, health_conditions),
                    "nutritional_benefits": generate_nutritional_benefits(fruit),
                    "nutrition": {
                        "calories": fruit["calories"],
                        "sugar": fruit["sugar"],
                        "vitaminC": fruit["vitaminC"]
                    }
                }
                recommended_fruits.append(recommendation)
        
        logging.debug(f"Final recommendations: {len(recommended_fruits)} fruits")
        
        # Sort by relevance (you can implement custom scoring)
        recommended_fruits.sort(key=lambda x: x["nutrition"]["vitaminC"], reverse=True)
        
        # Limit to top 5 recommendations
        return recommended_fruits[:5]
        
    except Exception as e:
        logging.error(f"Error generating recommendations: {str(e)}")
        return []

def generate_recommendation_reason(fruit, age, gender, fitness_goal, dietary_preference, health_conditions):
    """Generate personalized reason for recommendation"""
    reasons = []
    
    if fitness_goal == "Weight Loss" and fruit["calories"] <= 55:
        reasons.append("low in calories for weight management")
    
    if fitness_goal == "Muscle Gain" and fruit["vitaminC"] >= 8:
        reasons.append("high vitamin C supports muscle recovery")
    
    if "Diabetes" not in health_conditions and fruit["sugar"] <= 8:
        reasons.append("moderate sugar content")
    
    if age > 60 and fruit["vitaminC"] > 20:
        reasons.append("high vitamin C supports immune system")
    
    if gender == "Female" and fruit["vitaminC"] > 10:
        reasons.append("excellent vitamin C for women's health")
    
    if dietary_preference in ["Vegan", "Vegetarian"]:
        reasons.append("perfect for plant-based diet")
    
    if not reasons:
        reasons.append("nutritionally balanced for your profile")
    
    return ", ".join(reasons)

def generate_nutritional_benefits(fruit):
    """Generate list of nutritional benefits"""
    benefits = []
    
    if fruit["vitaminC"] > 20:
        benefits.append("High Vitamin C")
    elif fruit["vitaminC"] > 10:
        benefits.append("Good Vitamin C")
    
    if fruit["calories"] < 50:
        benefits.append("Low Calorie")
    elif fruit["calories"] > 70:
        benefits.append("Energy Rich")
    
    if fruit["sugar"] < 6:
        benefits.append("Low Sugar")
    elif fruit["sugar"] > 12:
        benefits.append("Natural Sugars")
    
    benefits.append("Antioxidants")
    benefits.append("Fiber")
    
    return benefits


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
