{ config, pkgs, lib, ... }:
with lib;
with pkgs;

let
  snabb_doc = writeScript "snabb_doc.sh" (readFile (fetchurl {
    url = "https://raw.githubusercontent.com/eugeneia/snabb/44f6ab0492b7d69708905b4c9560bdba6c456882/src/scripts/snabb_doc.sh";
    sha256 = "ac34a4ac8a5cb0d0dad24ed2934150aa2d216c64ca7f89049c73265ca0774004";
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
