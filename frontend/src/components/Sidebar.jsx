import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { FaSignOutAlt, FaHome, FaUsers, FaBook, FaCog } from 'react-icons/fa';

function AdminSidebar() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout } = useAuth();

  const isActive = (path) => location.pathname.includes(path);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="w-64 bg-gray-800 text-white h-screen fixed left-0 top-0 flex flex-col">
      <div className="p-6 border-b border-gray-700">
        <h1 className="text-2xl font-bold">SCMCIES</h1>
        <p className="text-sm text-gray-400">Admin Panel</p>
      </div>

      <nav className="flex-1 px-4 py-6 space-y-2">
        <NavLink
          icon={<FaHome />}
          label="Dashboard"
          path="/admin"
          isActive={isActive('/admin') && location.pathname === '/admin'}
          onClick={() => navigate('/admin')}
        />
        <NavLink
          icon={<FaUsers />}
          label="Students"
          path="/admin/students"
          isActive={isActive('/students')}
          onClick={() => navigate('/admin/students')}
        />
        <NavLink
          icon={<FaBook />}
          label="Logs"
          path="/admin/logs"
          isActive={isActive('/logs')}
          onClick={() => navigate('/admin/logs')}
        />
        <NavLink
          icon={<FaCog />}
          label="Settings"
          path="/admin/settings"
          isActive={isActive('/settings')}
          onClick={() => navigate('/admin/settings')}
        />
      </nav>

      <div className="p-6 border-t border-gray-700">
        <div className="text-sm mb-4">
          <p className="text-gray-400">Logged in as:</p>
          <p className="font-medium">{user?.email}</p>
        </div>
        <button
          onClick={handleLogout}
          className="w-full flex items-center justify-center gap-2 bg-red-600 hover:bg-red-700 px-4 py-2 rounded-lg transition"
        >
          <FaSignOutAlt />
          Logout
        </button>
      </div>
    </div>
  );
}

function ParentSidebar() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout } = useAuth();

  const isActive = (path) => location.pathname.includes(path);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="w-64 bg-gray-800 text-white h-screen fixed left-0 top-0 flex flex-col">
      <div className="p-6 border-b border-gray-700">
        <h1 className="text-2xl font-bold">SCMCIES</h1>
        <p className="text-sm text-gray-400">Parent Portal</p>
      </div>

      <nav className="flex-1 px-4 py-6 space-y-2">
        <NavLink
          icon={<FaHome />}
          label="My Children"
          path="/parent/children"
          isActive={isActive('/children')}
          onClick={() => navigate('/parent/children')}
        />
        <NavLink
          icon={<FaBook />}
          label="Logs"
          path="/parent/logs"
          isActive={isActive('/logs')}
          onClick={() => navigate('/parent/logs')}
        />
      </nav>

      <div className="p-6 border-t border-gray-700">
        <div className="text-sm mb-4">
          <p className="text-gray-400">Logged in as:</p>
          <p className="font-medium">{user?.name}</p>
        </div>
        <button
          onClick={handleLogout}
          className="w-full flex items-center justify-center gap-2 bg-red-600 hover:bg-red-700 px-4 py-2 rounded-lg transition"
        >
          <FaSignOutAlt />
          Logout
        </button>
      </div>
    </div>
  );
}

function NavLink({ icon, label, isActive, onClick }) {
  return (
    <button
      onClick={onClick}
      className={`w-full flex items-center gap-3 px-4 py-2 rounded-lg transition ${
        isActive
          ? 'bg-blue-600 text-white'
          : 'text-gray-300 hover:bg-gray-700'
      }`}
    >
      {icon}
      <span>{label}</span>
    </button>
  );
}

export { AdminSidebar, ParentSidebar };
