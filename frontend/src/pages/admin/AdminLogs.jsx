import React, { useState, useEffect } from 'react';
import { logAPI } from '../../services/api';
import { FaSync } from 'react-icons/fa';

function AdminLogs() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filters, setFilters] = useState({
    student_id: '',
    event_type: '',
    startDate: '',
    endDate: '',
  });
  const [stats, setStats] = useState({
    totalEntries: 0,
    totalExits: 0,
  });

  useEffect(() => {
    const fetchLogs = async () => {
      try {
        setLoading(true);
        const res = await logAPI.getAdminLogs(filters);
        setLogs(res.data);

        // Calculate stats
        const entries = res.data.filter((log) => log.event_type === 'ENTRY').length;
        const exits = res.data.filter((log) => log.event_type === 'EXIT').length;
        setStats({ totalEntries: entries, totalExits: exits });
      } catch (err) {
        setError('Failed to load logs');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchLogs();

    // Auto-refresh every 30 seconds
    const interval = setInterval(fetchLogs, 30000);
    return () => clearInterval(interval);
  }, [filters]);

  const handleFilterChange = (field, value) => {
    setFilters((prev) => ({ ...prev, [field]: value }));
  };

  const handleRefresh = async () => {
    try {
      setLoading(true);
      const res = await logAPI.getAdminLogs(filters);
      setLogs(res.data);
    } catch (err) {
      setError('Failed to refresh logs');
    } finally {
      setLoading(false);
    }
  };

  const resetFilters = () => {
    setFilters({
      student_id: '',
      event_type: '',
      startDate: '',
      endDate: '',
    });
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-gray-800">Entry/Exit Logs</h1>
        <button
          onClick={handleRefresh}
          disabled={loading}
          className="flex items-center gap-2 bg-blue-500 hover:bg-blue-600 disabled:bg-gray-400 text-white px-6 py-2 rounded-lg transition"
        >
          <FaSync className={loading ? 'animate-spin' : ''} /> Refresh
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-lg mb-6">
          {error}
        </div>
      )}

      {/* Stats Cards */}
      <div className="grid grid-cols-2 gap-4 mb-8">
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <p className="text-green-700 font-medium">Total Entries Today</p>
          <p className="text-3xl font-bold text-green-600">{stats.totalEntries}</p>
        </div>
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-700 font-medium">Total Exits Today</p>
          <p className="text-3xl font-bold text-red-600">{stats.totalExits}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <h2 className="text-lg font-bold text-gray-800 mb-4">Filters</h2>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <input
            type="text"
            placeholder="Student ID"
            value={filters.student_id}
            onChange={(e) => handleFilterChange('student_id', e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg"
          />
          <select
            value={filters.event_type}
            onChange={(e) => handleFilterChange('event_type', e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg"
          >
            <option value="">All Events</option>
            <option value="ENTRY">Entry</option>
            <option value="EXIT">Exit</option>
          </select>
          <input
            type="date"
            value={filters.startDate}
            onChange={(e) => handleFilterChange('startDate', e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg"
          />
          <input
            type="date"
            value={filters.endDate}
            onChange={(e) => handleFilterChange('endDate', e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg"
          />
        </div>
        <button
          onClick={resetFilters}
          className="mt-4 px-4 py-2 bg-gray-300 hover:bg-gray-400 text-gray-800 rounded-lg transition"
        >
          Reset Filters
        </button>
      </div>

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
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Location</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {logs.length === 0 ? (
              <tr>
                <td colSpan="7" className="px-6 py-4 text-center text-gray-500">
                  No logs found
                </td>
              </tr>
            ) : (
              logs.map((log) => (
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
                  <td className="px-6 py-4 text-sm">{log.location}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default AdminLogs;
