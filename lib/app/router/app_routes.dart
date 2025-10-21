class AppRoutes {
  static const login = '/login';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const patientHome = '/patient-home';
  static const doctorHome = '/doctor-home';
  static const testeMemoria = '/teste-memoria';
  static const tmtA = '/teste-tmt-a';
  static const tmtB = '/teste-tmt-b';
  static const stroopTest = '/stroop-test';
  static const resultadoTeste = '/resultado-teste';
  static const accountSettings = '/account';
  static const editAccount = '/account/edit';
  static const changePassword = '/account/password';
  static const patientsList = '/patients';
  static const addPatient = '/patients/add';
  static const confirmPatientAccess = '/confirm';

  static const lineChart = '/line_chart';
  
  // Doctor routes for patient tests
  static const doctorPatientTests = '/doctor/patient-tests';
  static const doctorPatientMemoryTest = '/doctor/patient/teste-memoria';
  static const doctorPatientTmtA = '/doctor/patient/teste-tmt-a';
  static const doctorPatientTmtB = '/doctor/patient/teste-tmt-b';
  static const doctorPatientStroopTest = '/doctor/patient/stroop-test';
  static const doctorPatientHistory = '/doctor/patient/history';
  
  // Deeplink routes
  static const auth = '/auth';
}
