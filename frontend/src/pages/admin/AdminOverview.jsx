import React, { useState, useEffect } from 'react';
import { adminAPI, logAPI } from '../../services/api';
import { FaUsers, FaRoad, FaArrowUp, FaArrowDown } from 'react-icons/fa';

function AdminOverview() {
  const [stats, setStats] = useState({
    totalStudents: 0,
    studentsOnCampus: 0,
    entriestoday: 0,
    exitsToday: 0,
  });
  const [recentLogs, setRecentLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [statsRes, logsRes] = await Promise.all([
        adminAPI.getStatistics(),
        adminAPI.getRecentLogs(),
      ]);

      setStats(statsRes.data);
      setRecentLogs(logsRes.data);
    } catch (err) {
      setError('Failed to load dashboard data');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center h-screen">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-800 mb-8">Dashboard</h1>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-lg mb-6">
          {error}
        </div>
      )}

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard
          icon={<FaUsers />}
          label="Total Students"
          value={stats.totalStudents}
          color="blue"
        />
        <StatCard
          icon={<FaRoad />}
          label="On Campus"
          value={stats.studentsOnCampus}
          color="green"
        />
        <StatCard
          icon={<FaArrowUp />}
          label="Entries Today"
          value={stats.entriestoday}
          color="purple"
        />
        <StatCard
          icon={<FaArrowDown />}
          label="Exits Today"
          value={stats.exitsToday}
          color="orange"
        />
      </div>

      {/* Recent Logs Table */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-800">Recent Activity (Last 10)</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Student</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">ID</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Grade</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Parent Email</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Event</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Time</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {recentLogs.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-6 py-4 text-center text-gray-500">
                    No logs yet
                  </td>
                </tr>
              ) : (
                recentLogs.map((log) => (
                  <tr key={log.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        {log.image_path && (
                          <img
                            src={`http://localhost:8000${log.image_path}`}
                            alt={log.first_name}
                            className="w-10 h-10 rounded-full object-cover"
                            onError={(e) => (e.target.src = 'https://via.placeholder.com/40')}
                          />
                        )}
                        <span className="font-medium">{log.first_name} {log.last_name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm">{log.student_id}</td>
                    <td className="px-6 py-4 text-sm">{log.grade_level}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{log.parent_email}</td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${
                          log.event_type === 'ENTRY'
                            ? 'bg-green-100 text-green-800'
                            : 'bg-red-100 text-red-800'
                        }`}
                      >
                        {log.event_type}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {new Date(log.timestamp).toLocaleString()}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function StatCard({ icon, label, value, color }) {
  const bgColor = {
    blue: 'bg-blue-50',
    green: 'bg-green-50',
    purple: 'bg-purple-50',
    orange: 'bg-orange-50',
  }[color];

  const textColor = {
    blue: 'text-blue-600',
    green: 'text-green-600',
    purple: 'text-purple-600',
    orange: 'text-orange-600',
  }[color];

  return (
    <div
      className={`${bgColor} rounded-lg p-6 flex items-center gap-4 border border-gray-200`}
    >
      <div className={`text-3xl ${textColor}`}>{icon}</div>
      <div>
        <p className="text-gray-600 text-sm">{label}</p>
        <p className="text-2xl font-bold text-gray-800">{value}</p>
      </div>
    </div>
  );
}

export default AdminOverview;
