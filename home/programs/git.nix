{
  pkgs,
  ...
}:
{
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };

  programs.delta = {
    enable = true;
  };

  programs.git = {
    enable = true;
    ignores = [
      ".ignore/"
      ".worktrees/"
    ];

    settings = {
      user.name = "Michael Lyon";
      user.email = "mlyon360@gmail.com";

      core = {
        editor = "nvim -f";
        pager = "delta";
      };

      interactive.diffFilter = "delta --color-only";

      merge = {
        conflictStyle = "zdiff3";
        ff = "only";
      };

      push.autoSetupRemote = true;

      delta = {
        navigate = true;
        dark = true;
        minus-style = "syntax \"#4a272f\"";
        minus-non-emph-style = "syntax \"#4a272f\"";
        minus-emph-style = "syntax \"#713137\"";
        minus-empty-line-marker-style = "syntax \"#4a272f\"";
        line-numbers-minus-style = "#914c54";
        plus-style = "syntax \"#243e4a\"";
        plus-non-emph-style = "syntax \"#243e4a\"";
        plus-emph-style = "syntax \"#2c5a66\"";
        plus-empty-line-marker-style = "syntax \"#243e4a\"";
        line-numbers-plus-style = "#449dab";
        line-numbers-zero-style = "#3b4261";
      };
    };
  };
}
