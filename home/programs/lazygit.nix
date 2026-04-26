{ ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=iso --pretty=medium {{branchName}} --";
        allBranchesLogCmds = [
          "git log --all --graph --color=always --abbrev-commit --decorate --date=iso --pretty=medium"
        ];
        pagers = [
          {
            pager = "delta --dark --paging=never --line-numbers --tabs=2";
            colorArg = "always";
          }
          {
            externalDiffCommand = "difft --color=always";
          }
        ];
      };
      update.method = "never";
      notARepository = "quit";
      promptToReturnFromSubprocess = false;
      gui = {
        scrollHeight = 10;
        timeFormat = "2006-01-02 15:04:05 MST";
        theme = {
          selectedLineBgColor = [ "reverse" ];
          selectedRangeBgColor = [ "reverse" ];
        };
        showFileTree = false;
        nerdFontsVersion = 3;
        skipRewordInEditorWarning = true;
        border = "double";
        showCommandLog = false;
        tabWidth = 1;
      };
      keybinding.files = {
        commitChanges = "C";
        commitChangesWithEditor = "c";
      };
      customCommands = [
        {
          key = "<c-a>";
          description = "pick AI commit";
          command = "git commit -m '{{.Form.Msg}}'";
          context = "files";
          prompts = [
            {
              type = "menuFromCommand";
              title = "AI Commit Messages";
              key = "Msg";
              command = "lazycommit commit";
              filter = "^(?P<raw>.+)$";
              valueFormat = "{{ .raw }}";
              labelFormat = "{{ .raw | green }}";
            }
          ];
        }
        {
          key = "<c-b>";
          description = "pick AI commit (edit before committing)";
          context = "files";
          output = "terminal";
          command = "bash -c 'msg=\"{{.Form.Msg}}\"; echo \"$msg\" > .git/COMMIT_EDITMSG && \${EDITOR:-nvim} .git/COMMIT_EDITMSG && if [ -s .git/COMMIT_EDITMSG ]; then git commit -F .git/COMMIT_EDITMSG; else echo \"Commit message is empty, commit aborted.\"; fi'";
          prompts = [
            {
              type = "menuFromCommand";
              title = "AI Commit Messages";
              key = "Msg";
              command = "lazycommit commit";
              filter = "^(?P<raw>.+)$";
              valueFormat = "{{ .raw }}";
              labelFormat = "{{ .raw | green }}";
            }
          ];
        }
        {
          key = "D";
          description = "force remove worktree and branch";
          context = "worktrees";
          command = "git worktree remove --force {{.SelectedWorktree.Path | quote}} && git branch -D {{.SelectedWorktree.Branch | quote}}";
          prompts = [
            {
              type = "confirm";
              title = "Force remove worktree and branch";
              body = "Force remove worktree '{{.SelectedWorktree.Path}}' and delete branch '{{.SelectedWorktree.Branch}}'?";
            }
          ];
        }
      ];
    };
  };
}
