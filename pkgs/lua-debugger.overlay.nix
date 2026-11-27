_final: prev: {
  # Lua debugger override
  lua54Packages = prev.lua54Packages.overrideScope (luaFinal: _luaPrev: {
    mobdebug = luaFinal.callPackage (
      {
        buildLuarocksPackage,
        fetchFromGitHub,
        fetchurl,
        luaAtLeast,
        luaOlder,
        luasocket,
      }:
        buildLuarocksPackage {
          pname = "mobdebug";
          version = "0.80-1";
          knownRockspec =
            (fetchurl {
              url = "https://luarocks.org/mobdebug-0.80-1.rockspec";
              hash = "sha256-FxtnsnQDm1ok8fki4sWR3AHPUPWOUGucEcoJsIFoMfk=";
            }).outPath;
          src = fetchFromGitHub {
            owner = "pkulchenko";
            repo = "MobDebug";
            rev = "0.80";
            hash = "sha256-Z3OoDXK5t1MQUHx8Muvp9Fl43yqDgxnWBuAQxEUYwrk=";
          };

          disabled = luaOlder "5.1" || luaAtLeast "5.5";
          propagatedBuildInputs = [luasocket];

          meta = {
            homepage = "https://github.com/pkulchenko/MobDebug";
            description = "Remote debugger for the Lua programming language";
            license.fullName = "MIT/X11";
          };
        }
    ) {};
  });
}
