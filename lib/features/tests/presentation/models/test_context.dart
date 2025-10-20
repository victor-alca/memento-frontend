class TestContext {
  final String? patientId;
  final String? doctorId;
  final bool isDoctorPerforming;

  const TestContext({
    this.patientId,
    this.doctorId,
    this.isDoctorPerforming = false,
  });
}
