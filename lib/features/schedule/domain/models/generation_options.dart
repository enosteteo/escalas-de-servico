class GenerationOptions {
  final bool requireAgeGroupPairing;
  final int volunteersPerDay;

  const GenerationOptions({
    this.requireAgeGroupPairing = false,
    this.volunteersPerDay = 1,
  });
}
