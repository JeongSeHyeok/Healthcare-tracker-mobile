from pydantic import BaseModel, EmailStr, Field
from typing import Optional

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=4)
    name: str = '사용자'
    age: Optional[int] = None
    height: Optional[float] = None
    weight: float = 60
    bmr: float = 1500
    muscleMass: float = 25

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class ExerciseRequest(BaseModel):
    type: str = '러닝머신'
    duration: int = 30
    speed: float = 6
    incline: float = 0
    exerciseDate: Optional[str] = None

class NutritionRequest(BaseModel):
    foodName: str
    calories: int

class GoalRequest(BaseModel):
    goalType: str
    targetValue: float
    currentValue: float = 0

class GoalUpdateRequest(BaseModel):
    currentValue: float

class WearableRequest(BaseModel):
    steps: int = 0
    heartRate: int = 0

class PrivacyConsentRequest(BaseModel):
    consent: bool
