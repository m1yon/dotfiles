{
  autoPatchelfHook,
  buildNpmPackage,
  fetchurl,
  jq,
  lib,
  nodejs_24,
  stdenv,
}:

# Plain npm on a machine with Node 22 silently installs todoist-cli 2.1.0, so the
# version, the dependency tree and Node 24 are all pinned here.
buildNpmPackage (finalAttrs: {
  pname = "todoist-cli";
  version = "5.10.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@doist/todoist-cli/-/todoist-cli-${finalAttrs.version}.tgz";
    hash = "sha512-vLRKKWZ36epOONb9hpHk834Q+DjXN/K/yFKncxiGX5GfqIVn1hK6rS4ZQGdX6yybT5v53XQquz28Qwa4/VOr7A==";
  };

  nodejs = nodejs_24;

  # package-lock.json came from `npm install --package-lock-only` on this
  # package.json minus devDependencies and scripts. Dropping the scripts also
  # drops the postinstall that writes into the user's home.
  postPatch = ''
    ${lib.getExe jq} 'del(.devDependencies, .scripts)' package.json > package.json.pruned
    mv package.json.pruned package.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-SDmjqGHYutkL7Qmru/72p2Lkk7y7lLFYJR9cG3yXiY4=";
  dontNpmBuild = true;

  # The keyring dependency ships a prebuilt native module for each platform.
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  meta = {
    description = "Command line client for Todoist";
    homepage = "https://github.com/Doist/todoist-cli";
    license = lib.licenses.mit;
    mainProgram = "td";
  };
})
