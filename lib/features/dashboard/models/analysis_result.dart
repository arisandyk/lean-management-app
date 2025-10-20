class AnalysisResult {
  final int servedCount;
  final double avgTotalTime;
  final double avgPendaftaran;
  final double avgKonsultasi;
  final double avgApotek;
  final Map<String, double> bottleneckChart;

  AnalysisResult({
    required this.servedCount,
    required this.avgTotalTime,
    required this.avgPendaftaran,
    required this.avgKonsultasi,
    required this.avgApotek,
    required this.bottleneckChart,
  });
}