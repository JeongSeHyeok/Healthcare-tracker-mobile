def calculate_exercise_calories(weight=60, duration=30, speed=5, incline=0, bmr=1500, muscle_mass=25):
    speed = float(speed or 0); incline = float(incline or 0)
    base_met = 8.3 if speed >= 8 else 6.0 if speed >= 6 else 3.8
    incline_bonus = 1 + max(incline, 0) * 0.035
    bmr_factor = float(bmr or 1500) / 1500
    muscle_factor = 1 + (float(muscle_mass or 25) - 25) * 0.01
    kcal = base_met * 3.5 * float(weight or 60) / 200 * float(duration or 0) * incline_bonus * bmr_factor * muscle_factor
    return max(0, round(kcal))
