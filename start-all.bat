@echo off
REM Start backend server
cd backend-node
echo Starting Backend Server on port 8000...
start npm start
cd ..

timeout /t 3 /nobreak

REM Start frontend
cd frontend
echo Starting Frontend on port 3000...
start npm start
cd ..

timeout /t 3 /nobreak

REM Start Mini PC client
cd mini_pc_client
echo Starting Mini PC Face Recognition Client...
python main.py

pause
