import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import LoginPage from './pages/LoginPage';
import AdminDashboard from './pages/AdminDashboard';
import ParentDashboard from './pages/ParentDashboard';

function PrivateRoute({ element, requiredRole }) {
  const { user } = useAuth();

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (requiredRole && user.role !== requiredRole) {
    return <Navigate to="/login" replace />;
  }

  return element;
}

function App() {
  return (
    <Router>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/admin/*" element={<PrivateRoute element={<AdminDashboard />} requiredRole="admin" />} />
          <Route path="/parent/*" element={<PrivateRoute element={<ParentDashboard />} requiredRole="parent" />} />
          <Route path="/" element={<Navigate to="/login" replace />} />
        </Routes>
      </AuthProvider>
    </Router>
  );
}

export default App;
