import api from './axios'

export const rolesApi = {
  // Roles
  getRoles: () => api.get('/roles'),
  getRole: (id) => api.get(`/roles/${id}`),
  createRole: (data) => api.post('/roles', data),
  updateRole: (id, data) => api.put(`/roles/${id}`, data),
  deleteRole: (id) => api.delete(`/roles/${id}`),

  // Permissions
  getPermissions: () => api.get('/roles/permissions'),
}
