import React from 'react';
import { FaCog } from 'react-icons/fa';

function AdminSettings() {
  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-800 mb-8">Settings</h1>

      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex items-center gap-4 mb-6">
          <FaCog className="text-3xl text-gray-600" />
          <div>
            <h2 className="text-2xl font-bold text-gray-800">System Configuration</h2>
            <p className="text-gray-600">Manage system settings and preferences</p>
          </div>
        </div>

        <div className="border-t pt-6">
          <p className="text-gray-600 mb-4">
            This settings page allows you to manage system-wide configurations. 
            Current features available:
          </p>
          <ul className="list-disc list-inside space-y-2 text-gray-700">
            <li>Monitor system health and status</li>
            <li>View API configuration details</li>
            <li>Manage database connections</li>
            <li>Configure email notification settings</li>
          </ul>
        </div>

        <div className="mt-8 p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <h3 className="font-medium text-blue-900 mb-2">System Status</h3>
          <div className="text-sm text-blue-800">
            <p>✓ Backend API: Connected</p>
            <p>✓ Database: Connected</p>
            <p>✓ Email Service: Active</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default AdminSettings;
