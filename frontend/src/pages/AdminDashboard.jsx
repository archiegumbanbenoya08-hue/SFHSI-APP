import React, { useState, useEffect } from 'react';
import { Routes, Route } from 'react-router-dom';
import { AdminSidebar } from '../components/Sidebar';
import AdminOverview from './admin/AdminOverview';
import AdminStudents from './admin/AdminStudents';
import AdminLogs from './admin/AdminLogs';
import AdminSettings from './admin/AdminSettings';

function AdminDashboard() {
  return (
    <div className="flex">
      <AdminSidebar />
      <div className="ml-64 flex-1 bg-gray-50 min-h-screen">
        <Routes>
          <Route path="/" element={<AdminOverview />} />
          <Route path="/students" element={<AdminStudents />} />
          <Route path="/logs" element={<AdminLogs />} />
          <Route path="/settings" element={<AdminSettings />} />
        </Routes>
      </div>
    </div>
  );
}

export default AdminDashboard;
