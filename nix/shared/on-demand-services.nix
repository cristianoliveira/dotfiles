{ ... }: {
  environment.etc."process-compose/services.yaml".source = ./on-demand-services.yaml;
}
