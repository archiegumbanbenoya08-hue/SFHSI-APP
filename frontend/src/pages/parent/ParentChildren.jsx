import React, { useState, useEffect } from 'react';
import { parentAPI } from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import { FaClock } from 'react-icons/fa';

function ParentChildren() {
  const { user } = useAuth();
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchChildren = async () => {
      try {
        setLoading(true);
        const res = await parentAPI.getChildren(user.parentId);
        setChildren(res.data);
      } catch (err) {
        setError('Failed to load children');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    if (user?.parentId) {
      fetchChildren();
    }
  }, [user]);

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center h-screen">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-800 mb-8">My Children</h1>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-lg mb-6">
          {error}
        </div>
      )}

      {children.length === 0 ? (
        <div className="bg-white rounded-lg shadow p-12 text-center">
          <p className="text-gray-600 text-lg">No children registered yet</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {children.map((child) => (
            <div key={child.id} className="bg-white rounded-lg shadow overflow-hidden hover:shadow-lg transition">
              {child.image_path && (
                <img
                  src={`http://localhost:8000${child.image_path}`}
                  alt={child.first_name}
                  className="w-full h-48 object-cover"
                  onError={(e) =>
                    (e.target.src = 'https://via.placeholder.com/300x200')
                  }
                />
              )}
              <div className="p-6">
                <h3 className="text-xl font-bold text-gray-800 mb-2">
                  {child.first_name} {child.last_name}
                </h3>
                <div className="space-y-2 text-sm text-gray-600 mb-4">
                  <p>
                    <strong>Student ID:</strong> {child.student_id}
                  </p>
                  <p>
                    <strong>Grade:</strong> {child.grade_level}
                  </p>
                </div>

                {/* Status */}
                <div
                  className={`rounded-lg p-3 text-center ${
                    child.status === 'IN_CAMPUS'
                      ? 'bg-green-50 border border-green-200'
                      : 'bg-gray-50 border border-gray-200'
                  }`}
                >
                  <p
                    className={`font-bold ${
                      child.status === 'IN_CAMPUS'
                        ? 'text-green-700'
                        : 'text-gray-700'
                    }`}
                  >
                    {child.status === 'IN_CAMPUS' ? '✓ In Campus' : '○ Not In Campus'}
                  </p>
                  {child.last_seen && (
                    <div className="flex items-center justify-center gap-1 text-xs text-gray-600 mt-1">
                      <FaClock />
                      <span>
                        Last seen:{' '}
                        {new Date(child.last_seen).toLocaleTimeString()}
                      </span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default ParentChildren;
