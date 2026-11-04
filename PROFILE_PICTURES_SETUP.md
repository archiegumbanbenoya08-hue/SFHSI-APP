# Parent Profile Pictures - Setup Guide

## 📍 Profile Images Location
All profile images should be saved to:
```
backend/app/static/profiles/
```

## 👥 Parent Accounts with Profile Pictures

### 1. **Kent** (Parent Two Parent)
- **Email**: parent2@example.com
- **Password**: your_configured_parent_password
- **Profile Image**: `kent.jpg` or `kent.png`
- **Status**: Ready for profile picture

### 2. **Archie** (Parent One Parent)
- **Email**: parent1@example.com
- **Password**: your_configured_parent_password
- **Profile Image**: `archie.jpg` or `archie.png`
- **Status**: Ready for profile picture

### 3. **Avril** (Parent Three Parent)
- **Email**: parent3@example.com
- **Password**: your_configured_parent_password
- **Profile Image**: `avril.jpg` or `avril.png`
- **Status**: Ready for profile picture

---

## 📥 How to Add Profile Pictures

### **Step 1: Save Images**
1. Take the three profile images provided
2. Save them to: `C:\Users\Admin\Desktop\SCMCIES APP\backend\app\static\profiles\`
3. Name them:
   - `kent.jpg` (or .png)
   - `archie.jpg` (or .png)
   - `avril.jpg` (or .png)

### **Step 2: Update Database**
The images will be automatically served when accessing user profiles.

Access paths:
- Kent: `http://172.21.244.38:8000/static/profiles/kent.jpg`
- Archie: `http://172.21.244.38:8000/static/profiles/archie.jpg`
- Avril: `http://172.21.244.38:8000/static/profiles/avril.jpg`

---

## 🔄 Database Update
Run this command to update user profiles with images (optional backend configuration):

```bash
# Navigate to backend
cd backend

# Activate virtual environment
venv\Scripts\activate

# Run custom script to link images to users (create if needed)
python update_profile_images.py
```

---

## ✅ Verification
Once images are saved:
1. Start the backend: `backend/run.bat`
2. Login as each parent
3. Their profile picture should display automatically

---

*Note: Images should be in JPG or PNG format, ideally 400x400 pixels or larger for best quality.*