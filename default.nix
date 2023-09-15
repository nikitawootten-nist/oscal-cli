{ pkgs ? let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
  in
  import nixpkgs { }
, ...
}: pkgs.maven.buildMavenPackage (
  let
    # Extract the version number from the pom file
    version = pkgs.lib.readFile
      (pkgs.runCommand "versionXpath" { } ''
        # XPath expression that extracts the version from the pom file
        ${pkgs.xmlstarlet}/bin/xml sel \
          -N 'm=http://maven.apache.org/POM/4.0.0' \
          -t -m '/m:project/m:version' -v . ${./pom.xml} \
            > $out
      '');
  in
  {
    pname = "oscal-cli";
    inherit version;

    src = ./.;
    mvnHash = "sha256-9JXHHNSYieWIOS6N8nNyurw9UXyhYaWPu3AD1QO28oM=";

    nativeBuildInputs = with pkgs; [ makeWrapper ];

    installPhase = ''
      mkdir -p $out/bin
      cp -r target/cli-core-${version}-oscal-cli/{lib,SWIDTAG,LICENSE*,README*} $out/

      makeWrapper ${pkgs.jre}/bin/java $out/bin/oscal-cli \
        --add-flags "-classpath $out/lib/'*'" \
        --add-flags "gov.nist.secauto.oscal.tools.cli.core.CLI"
    '';
  }
)
