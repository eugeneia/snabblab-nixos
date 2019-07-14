{ config, pkgs, lib, ... }:
with lib;
with pkgs;

let
  snabb_doc = writeScript "snabb_doc.sh" (readFile (fetchurl {
    url = "https://raw.githubusercontent.com/eugeneia/snabb/a9ec5e1e36550bc61e898b95a54743274bdb2773/src/scripts/snabb_doc.sh";
    sha256 = "b5fd831b6d2656313aaf24f5f54b5253af2dca52e9b4bb597367d388a2d1368f";
  }));
in {
  options = {

    services.snabb_doc = {

      credentials = lib.mkOption {
        type = types.str;
        default = "";
        description = ''
          GitHub credentials for SnabbDoc instance.
        '';
        example = ''
          username:password
        '';
      };

      dir = lib.mkOption {
        type = types.str;
        default = "/tmp/snabb_doc";
        description = ''
          Target GitHub repository for SnabbDoc instance.
        '';
      };

      repo = lib.mkOption {
        type = types.str;
        default = "SnabbCo/snabb";
        description = ''
          Target GitHub repository for SnabbDoc instance.
        '';
      };


      docrepo = lib.mkOption {
        type = types.str;
        default = "snabbco/snabbco.github.com";
        description = ''
          GitHub pages repository to host documentation.
        '';
      };

      url = lib.mkOption {
        type = types.str;
        default = "https://snabbco.github.com";
        description = ''
          URL of documentation site.
        '';
      };

      period = lib.mkOption {
        type = types.str;
        default = "*/30 * * * *";
        description = ''
          This option defines (in the format used by cron) when the
          SnabbDoc runs. The default is every minute.
        '';
      };

    };

  };

  config = {

    systemd.services.snabb_doc =
      { description = "Run SnabbDoc";
        path  = [(pkgs.buildEnv {
          name = "snabb_doc-env";
          paths = [ bash curl git jq gnumake findutils gcc ditaa pandoc coreutils busybox
                    (texlive.combine {
                      inherit (texlive) scheme-small luatex luatexbase sectsty titlesec cprotect bigfoot titling droid;
                  })];
          ignoreCollisions = true;
        })];
        script =
          ''
            export GITHUB_CREDENTIALS=${config.services.snabb_doc.credentials}
            export SNABBDOCDIR=${config.services.snabb_doc.dir}
            export REPO=${config.services.snabb_doc.repo}
            export DOCREPO=${config.services.snabb_doc.docrepo}
            export DOCURL=${config.services.snabb_doc.url}

            exec flock -x -n /var/lock/snabb_doc ${snabb_doc}
          '';
        environment.SSL_CERT_FILE = config.environment.sessionVariables.SSL_CERT_FILE;
      };

    services.cron.systemCronJobs =
      [ "${config.services.snabb_doc.period} root ${config.systemd.package}/bin/systemctl start snabb_doc.service" ];

  };
}
