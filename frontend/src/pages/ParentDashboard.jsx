import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { ParentSidebar } from '../components/Sidebar';
import ParentChildren from './parent/ParentChildren';
import ParentLogs from './parent/ParentLogs';

function ParentDashboard() {
  return (
    <div className="flex">
      <ParentSidebar />
      <div className="ml-64 flex-1 bg-gray-50 min-h-screen">
        <Routes>
          <Route path="/children" element={<ParentChildren />} />
          <Route path="/logs" element={<ParentLogs />} />
          <Route path="/" element={<ParentChildren />} />
        </Routes>
      </div>
    </div>
  );
}

export default ParentDashboard;
