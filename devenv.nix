{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  env.UV = "1";

  packages = with pkgs; [
    elan
  ];

  git-hooks.hooks = {
    # shellcheck.enable = true;
    # ruff.enable = true;
    # ruff-format.enable = true;
    alejandra.enable = true;
    lake-build = {
      enable = true;
      name = "lake build";
      entry = "${pkgs.bash}/bin/bash -c 'cd tests/test_project && lake build'";
      language = "system";
      pass_filenames = false;
      stages = ["pre-commit"];
    };
  };

  languages = {
    python = {
      package = pkgs.python312;
      libraries = [
      ];
      enable = true;
      uv = {
        enable = true;
      };
      venv.enable = true;
    };
  };
}
