def normalize_wearable_payload(steps: int = 0, heartRate: int = 0):
    return {
        'steps': int(steps or 0),
        'heart_rate': int(heartRate or 0),
        'source': 'simulation/mock-wearable-api'
    }
