{ config, pkgs, lib, ... }:
with lib;
with pkgs;

{
  options = {

    services.snabb_bot = {

      script = lib.mkOption {
        type = types.path;
        description = "Snabbbot script executed when snabbot is ran.";
        default = writeScript "snabb_bot.sh" (readFile (fetchurl {
            url = "https://raw.githubusercontent.com/eugeneia/snabb/6d1594aeeaad64d216d76712a3e204f59bd3785a/src/scripts/snabb_bot.sh";
            sha256 = "2d680584695756050f46735a20532fd03232aa89ea624525867749fb23eb1a12";
        }));
      };

      credentials = lib.mkOption {
        type = types.str;
        default = "";
        description = ''
          GitHub credentials for SnabbBot instance.
        '';
        example = ''
          username:password
        '';
      };

      repo = lib.mkOption {
        type = types.str;
        default = "SnabbCo/snabb";
        description = ''
          Target GitHub repository for SnabbBot instance.
        '';
      };

      test_image = lib.mkOption {
        type = types.str;
        default = "eugeneia/snabb-nfv-test";
        description = ''
          Docket test image.
        '';
      };

      dir = lib.mkOption {
        type = types.str;
        default = "/tmp/snabb_bot";
        description = ''
          Target GitHub repository for SnabbBot instance.
        '';
      };

      current = lib.mkOption {
        type = types.str;
        default = "master";
        description = ''
          The branch to merge pull requests with.
        '';
      };

      period = lib.mkOption {
        type = types.str;
        default = "* * * * *";
        description = ''
          This option defines (in the format used by cron) when the
          SnabbBot runs. The default is every minute.
        '';
      };

      environment = lib.mkOption {
        type = types.str;
        default = "";
        description = ''
          This option defines (in shell format, e.g.: `export FOO=bar; ...')
          which additional environment variables will be set when
          SnabbBot runs.
          ''; };

    };

  };

  config = {

    systemd.services.snabb_bot =
      { description = "Run SnabbBot";
        path  = [ coreutils bash curl git docker jq pciutils busybox ];
        script =
          ''
            export GITHUB_CREDENTIALS=${config.services.snabb_bot.credentials}
            export REPO=${config.services.snabb_bot.repo}
            export SNABB_TEST_IMAGE=${config.services.snabb_bot.test_image}
            export SNABBBOTDIR=${config.services.snabb_bot.dir}
            export CURRENT=${config.services.snabb_bot.current}

            export SNABB_IPSEC_SKIP_E2E_TEST=yes

            ${config.services.snabb_bot.environment}

            exec flock -x -n /var/lock/lab ${config.services.snabb_bot.script}
          '';
        environment.SSL_CERT_FILE = config.environment.sessionVariables.SSL_CERT_FILE;
      };

    services.cron.systemCronJobs =
      [ "${config.services.snabb_bot.period} root ${config.systemd.package}/bin/systemctl start snabb_bot.service" ];

  };
}
