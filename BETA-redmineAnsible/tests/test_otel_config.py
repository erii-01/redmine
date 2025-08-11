#!/usr/bin/env python3
"""
Tests for OpenTelemetry Collector configuration
"""
import yaml
import pytest
from pathlib import Path

class TestOTelConfig:
    @pytest.fixture
    def otel_config(self):
        """Load the OTEL configuration from vars file"""
        config_path = Path(__file__).parent.parent / "vars" / "otel_vars.yml"
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)

    def test_receivers_configuration(self, otel_config):
        """Test OTLP receivers are properly configured"""
        receivers = otel_config['otel_collector_receivers']
        
        assert 'otlp' in receivers
        assert 'protocols' in receivers['otlp']
        
        protocols = receivers['otlp']['protocols']
        assert 'grpc' in protocols
        assert 'http' in protocols
        
        assert protocols['grpc']['endpoint'] == "0.0.0.0:4317"
        assert protocols['http']['endpoint'] == "0.0.0.0:4318"

    def test_processors_configuration(self, otel_config):
        """Test processors are configured"""
        processors = otel_config['otel_collector_processors']
        assert 'batch' in processors

    def test_exporters_configuration(self, otel_config):
        """Test exporters for Grafana Cloud"""
        exporters = otel_config['otel_collector_exporters']
        
        # Test traces exporter
        assert 'otlp/grafanacloud_traces' in exporters
        traces_exporter = exporters['otlp/grafanacloud_traces']
        assert traces_exporter['endpoint'] == "tempo-prod-17-prod-sa-east-1.grafana.net:443"
        assert traces_exporter['auth']['authenticator'] == "basicauth/grafanacloud"
        
        # Test metrics exporter
        assert 'prometheusremotewrite/grafanacloud_metrics' in exporters
        metrics_exporter = exporters['prometheusremotewrite/grafanacloud_metrics']
        assert metrics_exporter['endpoint'] == "https://prometheus-prod-40-prod-sa-east-1.grafana.net/api/prom/push"
        assert metrics_exporter['auth']['username'] == "2251285"
        assert "{{ grafana_metrics_api_token }}" in str(metrics_exporter['auth']['password'])

    def test_connectors_configuration(self, otel_config):
        """Test spanmetrics connector configuration"""
        connectors = otel_config['otel_collector_connectors']
        
        assert 'spanmetrics' in connectors
        spanmetrics = connectors['spanmetrics']
        
        assert 'histogram' in spanmetrics
        assert 'namespace' in spanmetrics
        assert spanmetrics['namespace'] == 'traces.spanmetrics'
        
        buckets = spanmetrics['histogram']['explicit']['buckets']
        expected_buckets = ['100ms', '250ms', '500ms', '1s', '2s', '5s']
        assert buckets == expected_buckets

    def test_extensions_configuration(self, otel_config):
        """Test authentication extensions"""
        extensions = otel_config['otel_collector_extensions']
        
        assert 'basicauth/grafanacloud' in extensions
        auth_ext = extensions['basicauth/grafanacloud']
        
        assert 'client_auth' in auth_ext
        assert auth_ext['client_auth']['username'] == "1115635"
        assert "{{ grafana_tempo_api_token }}" in str(auth_ext['client_auth']['password'])

    def test_service_configuration(self, otel_config):
        """Test service pipelines configuration"""
        service = otel_config['otel_collector_service']
        
        # Test extensions
        assert 'extensions' in service
        assert 'basicauth/grafanacloud' in service['extensions']
        
        # Test pipelines
        assert 'pipelines' in service
        pipelines = service['pipelines']
        
        # Test traces pipeline
        assert 'traces' in pipelines
        traces_pipeline = pipelines['traces']
        assert traces_pipeline['receivers'] == ['otlp']
        assert traces_pipeline['processors'] == ['batch']
        assert set(traces_pipeline['exporters']) == {'otlp/grafanacloud_traces', 'spanmetrics'}
        
        # Test metrics pipeline
        assert 'metrics' in pipelines
        metrics_pipeline = pipelines['metrics']
        assert set(metrics_pipeline['receivers']) == {'otlp', 'spanmetrics'}
        assert metrics_pipeline['processors'] == ['batch']
        assert metrics_pipeline['exporters'] == ['prometheusremotewrite/grafanacloud_metrics']

    def test_grafana_endpoints_format(self, otel_config):
        """Test Grafana Cloud endpoints are properly formatted"""
        exporters = otel_config['otel_collector_exporters']
        
        # Test Tempo endpoint
        tempo_endpoint = exporters['otlp/grafanacloud_traces']['endpoint']
        assert tempo_endpoint.endswith(':443')
        assert 'tempo-prod' in tempo_endpoint
        assert 'grafana.net' in tempo_endpoint
        
        # Test Prometheus endpoint
        prom_endpoint = exporters['prometheusremotewrite/grafanacloud_metrics']['endpoint']
        assert prom_endpoint.startswith('https://')
        assert 'prometheus-prod' in prom_endpoint
        assert '/api/prom/push' in prom_endpoint

if __name__ == "__main__":
    pytest.main([__file__, "-v"])