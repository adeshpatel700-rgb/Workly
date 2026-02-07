import firebase_admin
from firebase_admin import credentials, auth
import os

# 1. Initialize Firebase Admin SDK
cred_path = os.path.join(os.path.dirname(__file__), 'service_account.json')
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)

email = 'satyrendrapatel2302@gmail.com'
password = 'Try?12345'

# 2. Check if user exists
try:
    user = auth.get_user_by_email(email)
    print(f"User {email} found with UID: {user.uid}")
    
    # 3. Reset password
    print("Updating password...")
    auth.update_user(
        user.uid,
        password=password
    )
    print(f"✅ Successfully updated user {email} password to '{password}'")

except auth.UserNotFoundError:
    print(f"User {email} not found. Creating new user...")
    # 4. Create user if not exists
    user = auth.create_user(
        email=email,
        password=password
    )
    print(f"✅ Successfully created user {email} with UID: {user.uid}")

except Exception as e:
    print(f"❌ Error: {e}")
