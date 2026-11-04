import React, { useState, useEffect } from 'react';
import { logAPI } from '../../services/api';
import { useAuth } from '../../context/AuthContext';

function ParentLogs() {
  const { user } = useAuth();
  const [logs, setLogs] = useState([]);
  const [filteredLogs, setFilteredLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedChild, setSelectedChild] = useState('');
  const [children, setChildren] = useState([]);

  useEffect(() => {
    const fetchLogs = async () => {
      try {
        setLoading(true);
        const res = await logAPI.getParentLogs(user.parentId);
        setLogs(res.data);

        // Extract unique children
        const uniqueChildren = [
          ...new Map(
            res.data.map((log) => [
              log.student_id,
              {
                student_id: log.student_id,
                name: `${log.first_name} ${log.last_name}`,
              },
            ])
          ).values(),
        ];
        setChildren(uniqueChildren);
        setFilteredLogs(res.data);
      } catch (err) {
        setError('Failed to load logs');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    if (user?.parentId) {
      fetchLogs();
    }
  }, [user]);

  // Filter logs when selected child changes
  useEffect(() => {
    if (selectedChild) {
      setFilteredLogs(logs.filter((log) => log.student_id === selectedChild));
    } else {
      setFilteredLogs(logs);
    }
  }, [selectedChild, logs]);

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center h-screen">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-800 mb-8">Entry/Exit Logs</h1>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-lg mb-6">
          {error}
        </div>
      )}

      {/* Filter */}
      {children.length > 1 && (
        <div className="bg-white rounded-lg shadow p-4 mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Filter by Child
          </label>
          <select
            value={selectedChild}
            onChange={(e) => setSelectedChild(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg"
          >
            <option value="">All Children</option>
            {children.map((child) => (
              <option key={child.student_id} value={child.student_id}>
                {child.name}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Logs Table */}
      <div className="bg-white rounded-lg shadow overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Photo</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Student Name</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Student ID</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Grade</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Event</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Date & Time</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {filteredLogs.length === 0 ? (
              <tr>
                <td colSpan="6" className="px-6 py-4 text-center text-gray-500">
                  No logs found
                </td>
              </tr>
            ) : (
              filteredLogs.map((log) => (
                <tr key={log.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    {log.image_path && (
                      <img
                        src={`http://localhost:8000${log.image_path}`}
                        alt={log.first_name}
                        className="w-10 h-10 rounded-full object-cover"
                        onError={(e) => (e.target.style.display = 'none')}
                      />
                    )}
                  </td>
                  <td className="px-6 py-4 font-medium">
                    {log.first_name} {log.last_name}
                  </td>
                  <td className="px-6 py-4">{log.student_id}</td>
                  <td className="px-6 py-4">{log.grade_level}</td>
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
  );
}

export default ParentLogs;
