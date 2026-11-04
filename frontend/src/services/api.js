import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

export const authAPI = {
  adminLogin: (email, password) =>
    apiClient.post('/auth/admin/login', { email, password }),
  parentLogin: (email, password) =>
    apiClient.post('/auth/parent/login', { email, password }),
};

export const studentAPI = {
  getAllStudents: () => apiClient.get('/students'),
  registerStudent: (formData) =>
    apiClient.post('/students', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),
  updateStudent: (id, data) => apiClient.put(`/students/${id}`, data),
  deleteStudent: (id) => apiClient.delete(`/students/${id}`),
};

export const logAPI = {
  getAdminLogs: (params = {}) =>
    apiClient.get('/logs/admin/all', { params }),
  getParentLogs: (parentId) =>
    apiClient.get(`/logs/parent/${parentId}`),
};

export const adminAPI = {
  getStatistics: () => apiClient.get('/admin/statistics'),
  getRecentLogs: () => apiClient.get('/admin/recent-logs'),
};

export const parentAPI = {
  getChildren: (parentId) =>
    apiClient.get(`/parents/${parentId}/children`),
};
