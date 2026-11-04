import React, { useState, useEffect } from 'react';
import { studentAPI, parentAPI, apiClient } from '../../services/api';
import { FaPlus, FaEdit, FaTrash, FaTimes } from 'react-icons/fa';

function AdminStudents() {
  const [students, setStudents] = useState([]);
  const [parents, setParents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [formData, setFormData] = useState({
    student_id: '',
    first_name: '',
    last_name: '',
    grade_level: '',
    section: '',
    parent_id: '',
  });
  const [photoPreview, setPhotoPreview] = useState('');
  const [photoFile, setPhotoFile] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const studentsRes = await studentAPI.getAllStudents();
      setStudents(studentsRes.data);
    } catch (err) {
      setError('Failed to load students');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchParents = async () => {
    try {
      const res = await apiClient.get('/parents');
      setParents(res.data || []);
    } catch (err) {
      console.error('Failed to load parents');
    }
  };

  const handleOpenModal = async () => {
    setEditingId(null);
    setFormData({
      student_id: '',
      first_name: '',
      last_name: '',
      grade_level: '',
      section: '',
      parent_id: '',
    });
    setPhotoPreview('');
    setPhotoFile(null);
    await fetchParents();
    setShowModal(true);
  };

  const handlePhotoChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setPhotoFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setPhotoPreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);

    try {
      if (editingId) {
        // Update
        await studentAPI.updateStudent(editingId, {
          first_name: formData.first_name,
          last_name: formData.last_name,
          grade_level: formData.grade_level,
          section: formData.section,
        });
      } else {
        // Create
        if (!photoFile) {
          setError('Please select a photo');
          setSubmitting(false);
          return;
        }

        const formDataToSend = new FormData();
        Object.keys(formData).forEach((key) => {
          formDataToSend.append(key, formData[key]);
        });
        formDataToSend.append('photo', photoFile);

        await studentAPI.registerStudent(formDataToSend);
      }

      setShowModal(false);
      fetchData();
      setError('');
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to save student');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this student?')) {
      try {
        await studentAPI.deleteStudent(id);
        fetchData();
      } catch (err) {
        setError('Failed to delete student');
      }
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
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-gray-800">Students</h1>
        <button
          onClick={handleOpenModal}
          className="flex items-center gap-2 bg-blue-500 hover:bg-blue-600 text-white px-6 py-2 rounded-lg transition"
        >
          <FaPlus /> Register Student
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-lg mb-6">
          {error}
        </div>
      )}

      {/* Students Table */}
      <div className="bg-white rounded-lg shadow overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Photo</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Name</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Student ID</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Grade</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Parent Email</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Status</th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {students.length === 0 ? (
              <tr>
                <td colSpan="7" className="px-6 py-4 text-center text-gray-500">
                  No students registered yet
                </td>
              </tr>
            ) : (
              students.map((student) => (
                <tr key={student.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    {student.image_path && (
                      <img
                        src={`http://localhost:8000${student.image_path}`}
                        alt={student.first_name}
                        className="w-10 h-10 rounded-full object-cover"
                        onError={(e) => (e.target.style.display = 'none')}
                      />
                    )}
                  </td>
                  <td className="px-6 py-4 font-medium">
                    {student.first_name} {student.last_name}
                  </td>
                  <td className="px-6 py-4">{student.student_id}</td>
                  <td className="px-6 py-4">{student.grade_level}</td>
                  <td className="px-6 py-4 text-sm">{student.parent_email}</td>
                  <td className="px-6 py-4">
                    <span
                      className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${
                        student.status === 'IN_CAMPUS'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}
                    >
                      {student.status === 'IN_CAMPUS' ? 'In Campus' : 'Not In Campus'}
                    </span>
                  </td>
                  <td className="px-6 py-4 flex gap-2">
                    <button
                      onClick={() => {
                        setEditingId(student.id);
                        setFormData({
                          student_id: student.student_id,
                          first_name: student.first_name,
                          last_name: student.last_name,
                          grade_level: student.grade_level,
                          section: student.section,
                          parent_id: student.parent_id,
                        });
                        setShowModal(true);
                      }}
                      className="text-blue-600 hover:text-blue-800"
                    >
                      <FaEdit />
                    </button>
                    <button
                      onClick={() => handleDelete(student.id)}
                      className="text-red-600 hover:text-red-800"
                    >
                      <FaTrash />
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-2xl font-bold text-gray-800">
                {editingId ? 'Edit Student' : 'Register New Student'}
              </h2>
              <button onClick={() => setShowModal(false)} className="text-gray-500 hover:text-gray-700">
                <FaTimes />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              {!editingId && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Photo
                  </label>
                  <input
                    type="file"
                    onChange={handlePhotoChange}
                    accept="image/*"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                  />
                  {photoPreview && (
                    <img
                      src={photoPreview}
                      alt="Preview"
                      className="w-24 h-24 rounded-lg object-cover mt-2"
                    />
                  )}
                </div>
              )}

              <input
                type="text"
                placeholder="Student ID"
                value={formData.student_id}
                onChange={(e) =>
                  setFormData({ ...formData, student_id: e.target.value })
                }
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                required
              />

              <input
                type="text"
                placeholder="First Name"
                value={formData.first_name}
                onChange={(e) =>
                  setFormData({ ...formData, first_name: e.target.value })
                }
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                required
              />

              <input
                type="text"
                placeholder="Last Name"
                value={formData.last_name}
                onChange={(e) =>
                  setFormData({ ...formData, last_name: e.target.value })
                }
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                required
              />

              <input
                type="text"
                placeholder="Grade Level"
                value={formData.grade_level}
                onChange={(e) =>
                  setFormData({ ...formData, grade_level: e.target.value })
                }
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                required
              />

              <input
                type="text"
                placeholder="Section"
                value={formData.section}
                onChange={(e) =>
                  setFormData({ ...formData, section: e.target.value })
                }
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                required
              />

              {!editingId && (
                <select
                  value={formData.parent_id}
                  onChange={(e) =>
                    setFormData({ ...formData, parent_id: e.target.value })
                  }
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                  required
                >
                  <option value="">Select Parent</option>
                  {parents.map((parent) => (
                    <option key={parent.id} value={parent.id}>
                      {parent.name} ({parent.email})
                    </option>
                  ))}
                </select>
              )}

              <div className="flex gap-2 pt-4">
                <button
                  type="submit"
                  disabled={submitting}
                  className="flex-1 bg-blue-500 hover:bg-blue-600 disabled:bg-gray-400 text-white font-medium py-2 rounded-lg transition"
                >
                  {submitting ? 'Saving...' : 'Save'}
                </button>
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-800 font-medium py-2 rounded-lg transition"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default AdminStudents;
