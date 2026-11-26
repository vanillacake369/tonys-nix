let
  english = "en_US.UTF-8";
  korean = "ko_KR.UTF-8";

  categoryLocales = {
    LC_ADDRESS = korean;
    LC_COLLATE = english;
    LC_CTYPE = english;
    LC_IDENTIFICATION = korean;
    LC_MEASUREMENT = korean;
    LC_MESSAGES = english;
    LC_MONETARY = korean;
    LC_NAME = korean;
    LC_NUMERIC = korean;
    LC_PAPER = korean;
    LC_TELEPHONE = korean;
    LC_TIME = korean;
  };
in {
  defaultLocale = english;
  supportedLocales = [
    "${english}/UTF-8"
    "${korean}/UTF-8"
  ];
  inherit categoryLocales;

  homeSessionVariables =
    {
      LANG = english;
    }
    // categoryLocales;
}
