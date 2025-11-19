{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.imapgoose;

  accountType = lib.types.submodule {
    options = {
      server = lib.mkOption {
        type = lib.types.str;
        example = "imap.example.com:993";
        description = "IMAP server address and port.";
      };

      username = lib.mkOption {
        type = lib.types.str;
        example = "user@example.com";
        description = "IMAP username/email address.";
      };

      passwordCmd = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "pass show email/work";
        description = "Command to retrieve the password. Its output is used as the password.";
      };

      localPath = lib.mkOption {
        type = lib.types.str;
        example = "~/mail/example";
        description = "Local path where mail will be stored.";
      };

      maxConnections = lib.mkOption {
        type = lib.types.int;
        default = 3;
        example = 5;
        description = "Maximum concurrent IMAP connections for this account.";
      };

      postSyncCmd = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "notmuch new";
        description = "Command to run after syncing mail.";
      };
    };
  };

  configFile = pkgs.writeText "imapgoose.conf" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: account: ''
        account ${name} {
            server ${account.server}
            username ${account.username}
            ${lib.optionalString (account.passwordCmd != null) "password-cmd ${account.passwordCmd}"}
            local-path ${account.localPath}
            max-connections ${toString account.maxConnections}
            ${lib.optionalString (account.postSyncCmd != null) "post-sync-cmd ${account.postSyncCmd}"}
        }
      '') cfg.accounts
    )
  );
in
{
  options.services.imapgoose = {
    enable = lib.mkEnableOption "ImapGoose, an IMAP to Maildir synchronization daemon";

    package = lib.mkPackageOption pkgs "imapgoose" { };

    accounts = lib.mkOption {
      type = lib.types.attrsOf accountType;
      default = { };
      example = lib.literalExpression ''
        {
          personal = {
            server = "imap.example.com:993";
            username = "user@example.com";
            passwordCmd = "pass show email/personal";
            localPath = "~/mail/personal";
            maxConnections = 3;
            postSyncCmd = "notmuch new";
          };
          work = {
            server = "imap.work.com:993";
            username = "work@work.com";
            passwordCmd = "pass show email/work";
            localPath = "~/mail/work";
            maxConnections = 5;
          };
        }
      '';
      description = "IMAP accounts to synchronize.";
    };

  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.user.services.imapgoose = {
      description = "ImapGoose: IMAP to Maildir synchronization daemon";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/imapgoose -config ${configFile}";
        Restart = "always";
        RestartSec = "10s";
      };
    };
  };
}
