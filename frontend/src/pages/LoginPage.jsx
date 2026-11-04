import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { authAPI } from '../services/api';
import { FaUser, FaLock, FaExclamationCircle } from 'react-icons/fa';

function LoginPage() {
  const [role, setRole] = useState('admin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const { login } = useAuth();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      let response;
      if (role === 'admin') {
        response = await authAPI.adminLogin(email, password);
      } else {
        response = await authAPI.parentLogin(email, password);
      }

      const { token, ...userData } = response.data;
      login(token, { ...userData, role });

      // Redirect based on role
      navigate(role === 'admin' ? '/admin' : '/parent');
    } catch (err) {
      setError(
        err.response?.data?.error || 'Login failed. Please try again.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-500 to-blue-700 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-2xl p-8 w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-800 mb-2">SCMCIES</h1>
          <p className="text-gray-600">Campus Entry/Exit Monitoring System</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Role Selector */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Login As
            </label>
            <div className="flex gap-4">
              <label className="flex items-center cursor-pointer">
                <input
                  type="radio"
                  value="admin"
                  checked={role === 'admin'}
                  onChange={(e) => setRole(e.target.value)}
                  className="mr-2"
                />
                <span className="text-gray-700">Administrator</span>
              </label>
              <label className="flex items-center cursor-pointer">
                <input
                  type="radio"
                  value="parent"
                  checked={role === 'parent'}
                  onChange={(e) => setRole(e.target.value)}
                  className="mr-2"
                />
                <span className="text-gray-700">Parent</span>
              </label>
            </div>
          </div>

          {/* Error Message */}
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3 flex items-center gap-3 text-red-700">
              <FaExclamationCircle />
              <span>{error}</span>
            </div>
          )}

          {/* Email Input */}
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
              Email Address
            </label>
            <div className="relative">
              <FaUser className="absolute left-3 top-3 text-gray-400" />
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Enter your email"
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>
          </div>

          {/* Password Input */}
          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
              Password
            </label>
            <div className="relative">
              <FaLock className="absolute left-3 top-3 text-gray-400" />
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-500 hover:bg-blue-600 disabled:bg-gray-400 text-white font-medium py-2 rounded-lg transition duration-200"
          >
            {loading ? 'Logging in...' : 'Login'}
          </button>
        </form>

      </div>
    </div>
  );
}

export default LoginPage;
