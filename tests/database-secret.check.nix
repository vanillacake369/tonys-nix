{pkgs, ...}: {
  database-secret-encrypted =
    pkgs.runCommand "database-secret-encrypted" {
      nativeBuildInputs = [
        pkgs.jq
        pkgs.sops
        pkgs.yq-go
      ];
    } ''
          test "$(sops filestatus ${../secrets/database.yaml} | jq -r .encrypted)" = true
        yq eval --exit-status \
          'has("production") and has("development") and (has("data") | not) and (.production | tag == "!!map") and (.development | tag == "!!map")' \
          ${../secrets/database.yaml} >/dev/null
      yq eval --exit-status \
        '([.production, .development] | [.. | select(tag != "!!map" and tag != "!!seq") | ((tag == "!!str") and ((. == "") or test("^ENC\\[")))] | all)' \
        ${../secrets/database.yaml} >/dev/null
          touch "$out"
    '';
}
