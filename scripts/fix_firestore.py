import firebase_admin
from firebase_admin import credentials, auth, firestore
import os

# 1. Initialize Firebase Admin SDK
cred_path = os.path.join(os.path.dirname(__file__), 'service_account.json')
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)

email = 'satyrendrapatel2302@gmail.com'
db = firestore.client()

try:
    # Get User UID
    user = auth.get_user_by_email(email)
    print(f"✅ Auth User found: {user.uid}")

    # Check/Create Firestore Doc
    doc_ref = db.collection('users').document(user.uid)
    doc = doc_ref.get()

    if doc.exists:
        print(f"ℹ️ Firestore document exists. Data: {doc.to_dict()}")
        # Unconditionally update role to admin just in case
        doc_ref.update({'role': 'admin', 'email': email})
        print("✅ Updated role to 'admin'.")
    else:
        print("⚠️ Firestore document MISSING. Creating now...")
        doc_ref.set({
            'email': email,
            'role': 'admin',
            'createdAt': firestore.SERVER_TIMESTAMP
        })
        print("✅ Created Admin Firestore document.")

except auth.UserNotFoundError:
    print(f"❌ User {email} not found in Auth. Please run reset_admin.py first.")
except Exception as e:
    print(f"❌ Error: {e}")
