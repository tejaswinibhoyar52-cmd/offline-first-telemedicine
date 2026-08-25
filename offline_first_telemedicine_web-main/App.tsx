import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AuthProvider } from '@/hooks/useAuth'
import { SyncProvider } from '@/hooks/useSync'
import { ToastProvider } from '@/components/ui/Toast'
import { ProtectedRoute } from '@/components/layout/ProtectedRoute'

import LandingPage from '@/pages/LandingPage'
import LoginPage from '@/pages/LoginPage'
import RegisterPage from '@/pages/RegisterPage'

import PatientDashboard from '@/pages/patient/Dashboard'
import PatientAppointments from '@/pages/patient/Appointments'
import PatientRecords from '@/pages/patient/Records'
import PatientPrescriptions from '@/pages/patient/Prescriptions'
import PatientConsultation from '@/pages/patient/Consultation'
import PatientMessages from '@/pages/patient/Messages'
import PatientSync from '@/pages/patient/Sync'
import PatientHealthAssistant from '@/pages/patient/HealthAssistant'

import DoctorDashboard from '@/pages/doctor/Dashboard'
import DoctorPatients from '@/pages/doctor/Patients'
import DoctorAppointments from '@/pages/doctor/Appointments'
import DoctorConsultations from '@/pages/doctor/Consultations'
import DoctorPrescriptions from '@/pages/doctor/Prescriptions'
import DoctorMessages from '@/pages/doctor/Messages'
import DoctorSync from '@/pages/doctor/Sync'

import AdminDashboard from '@/pages/admin/Dashboard'
import AdminPatients from '@/pages/admin/Patients'
import AdminDoctors from '@/pages/admin/Doctors'
import AdminAppointments from '@/pages/admin/Appointments'
import AdminRecords from '@/pages/admin/Records'
import AdminPrescriptions from '@/pages/admin/Prescriptions'
import AdminSync from '@/pages/admin/Sync'
import AdminReports from '@/pages/admin/Reports'
import AdminSettings from '@/pages/admin/Settings'

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <ToastProvider>
          <SyncProvider>
            <Routes>
              <Route path="/" element={<LandingPage />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<RegisterPage />} />

              <Route path="/patient/dashboard" element={<ProtectedRoute role="patient"><PatientDashboard /></ProtectedRoute>} />
              <Route path="/patient/appointments" element={<ProtectedRoute role="patient"><PatientAppointments /></ProtectedRoute>} />
              <Route path="/patient/records" element={<ProtectedRoute role="patient"><PatientRecords /></ProtectedRoute>} />
              <Route path="/patient/prescriptions" element={<ProtectedRoute role="patient"><PatientPrescriptions /></ProtectedRoute>} />
              <Route path="/patient/consultation" element={<ProtectedRoute role="patient"><PatientConsultation /></ProtectedRoute>} />
              <Route path="/patient/messages" element={<ProtectedRoute role="patient"><PatientMessages /></ProtectedRoute>} />
              <Route path="/patient/sync" element={<ProtectedRoute role="patient"><PatientSync /></ProtectedRoute>} />
              <Route path="/patient/health-assistant" element={<ProtectedRoute role="patient"><PatientHealthAssistant /></ProtectedRoute>} />

              <Route path="/doctor/dashboard" element={<ProtectedRoute role="doctor"><DoctorDashboard /></ProtectedRoute>} />
              <Route path="/doctor/patients" element={<ProtectedRoute role="doctor"><DoctorPatients /></ProtectedRoute>} />
              <Route path="/doctor/appointments" element={<ProtectedRoute role="doctor"><DoctorAppointments /></ProtectedRoute>} />
              <Route path="/doctor/consultations" element={<ProtectedRoute role="doctor"><DoctorConsultations /></ProtectedRoute>} />
              <Route path="/doctor/prescriptions" element={<ProtectedRoute role="doctor"><DoctorPrescriptions /></ProtectedRoute>} />
              <Route path="/doctor/messages" element={<ProtectedRoute role="doctor"><DoctorMessages /></ProtectedRoute>} />
              <Route path="/doctor/sync" element={<ProtectedRoute role="doctor"><DoctorSync /></ProtectedRoute>} />

              <Route path="/admin/dashboard" element={<ProtectedRoute role="admin"><AdminDashboard /></ProtectedRoute>} />
              <Route path="/admin/patients" element={<ProtectedRoute role="admin"><AdminPatients /></ProtectedRoute>} />
              <Route path="/admin/doctors" element={<ProtectedRoute role="admin"><AdminDoctors /></ProtectedRoute>} />
              <Route path="/admin/appointments" element={<ProtectedRoute role="admin"><AdminAppointments /></ProtectedRoute>} />
              <Route path="/admin/records" element={<ProtectedRoute role="admin"><AdminRecords /></ProtectedRoute>} />
              <Route path="/admin/prescriptions" element={<ProtectedRoute role="admin"><AdminPrescriptions /></ProtectedRoute>} />
              <Route path="/admin/sync" element={<ProtectedRoute role="admin"><AdminSync /></ProtectedRoute>} />
              <Route path="/admin/reports" element={<ProtectedRoute role="admin"><AdminReports /></ProtectedRoute>} />
              <Route path="/admin/settings" element={<ProtectedRoute role="admin"><AdminSettings /></ProtectedRoute>} />

              <Route path="*" element={<LandingPage />} />
            </Routes>
          </SyncProvider>
        </ToastProvider>
      </AuthProvider>
    </BrowserRouter>
  )
}
