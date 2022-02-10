# Generated by rebar3_nix
let fetchOnly = { src, ... }: src;
in { builder ? fetchOnly, fetchHex, fetchgit, fetchFromGitHub, overrides ? (x: y: { }) }:
let
  self = packages // (overrides self packages);
  packages = with self; {
    getopt = builder {
      name = "getopt";
      version = "1.0.1";
      src = fetchHex {
        pkg = "getopt";
        version = "1.0.1";
        sha256 = "sha256-U+Grg7nOtlyWctPno1uAkum9ybPugHIUcaFhwQxZlZw=";
      };
      beamDeps = [ ];
    };
    zipper = builder {
      name = "zipper";
      version = "1.0.1";
      src = fetchHex {
        pkg = "zipper";
        version = "1.0.1";
        sha256 = "sha256-ah/T4fDMHR31ZCyaDOIXgDZBGwpclkKFHR2idr1zfC0=";
      };
      beamDeps = [ ];
    };
    quickrand = builder {
      name = "quickrand";
      version = "2.0.1";
      src = fetchHex {
        pkg = "quickrand";
        version = "2.0.1";
        sha256 = "sha256-FNtn1K72uIFYEOyfPM714yS3O1bK42h/mddSuFvdTJY=";
      };
      beamDeps = [ ];
    };
    providers = builder {
      name = "providers";
      version = "1.8.1";
      src = fetchHex {
        pkg = "providers";
        version = "1.8.1";
        sha256 = "sha256-5FdFrenEdqmkaeoIQOQYqxk2DcRPAaIzME4RikRIa6A=";
      };
      beamDeps = [ getopt ];
    };
    katana_code = builder {
      name = "katana_code";
      version = "0.2.1";
      src = fetchHex {
        pkg = "katana_code";
        version = "0.2.1";
        sha256 = "sha256-hEitP1bZgU+YoovmUPcZG91QZXXjRcwW1YZmCxD26ZI=";
      };
      beamDeps = [ ];
    };
    bucs = builder {
      name = "bucs";
      version = "1.0.16";
      src = fetchHex {
        pkg = "bucs";
        version = "1.0.16";
        sha256 = "sha256-/2pccqUArXrsHuO6FkrjxFDq3uiYsNFR4frKGKyNDWI=";
      };
      beamDeps = [ ];
    };
    yamerl = builder {
      name = "yamerl";
      version = "git";
      src = fetchFromGitHub {
        owner = "erlang-ls";
        repo = "yamerl";
        rev = "9a9f7a2e84554992f2e8e08a8060bfe97776a5b7";
        sha256 = "1gb44v27paxwxm443m5f554wiziqi2kd300hgjjdg6fyvy3mvhss";
      };
      beamDeps = [ ];
    };
    uuid = builder {
      name = "uuid";
      version = "2.0.1";
      src = fetchHex {
        pkg = "uuid_erl";
        version = "2.0.1";
        sha256 = "sha256-q1fKzNUfFwAR5fREzoZfhLQWBeSDqe/MRowa+uyHVTs=";
      };
      beamDeps = [ quickrand ];
    };
    tdiff = builder {
      name = "tdiff";
      version = "0.1.2";
      src = fetchHex {
        pkg = "tdiff";
        version = "0.1.2";
        sha256 = "sha256-4MLhaPmSUqWIl2jVyPHmUQoYRZLUz6BrIneKGNM9eHU=";
      };
      beamDeps = [ ];
    };
    redbug = builder {
      name = "redbug";
      version = "2.0.6";
      src = fetchHex {
        pkg = "redbug";
        version = "2.0.6";
        sha256 = "sha256-qtlJhnH0q5HqylCZ/oWmFhgVimNuYoaJLE989K8XHQQ=";
      };
      beamDeps = [ ];
    };
    rebar3_format = builder {
      name = "rebar3_format";
      version = "0.8.2";
      src = fetchHex {
        pkg = "rebar3_format";
        version = "0.8.2";
        sha256 = "sha256-yo/ydjjCFpWT0USdrL6IlWNBk+0zNOkGtU/JfwgfUhM=";
      };
      beamDeps = [ katana_code ];
    };
    jsx = builder {
      name = "jsx";
      version = "3.0.0";
      src = fetchHex {
        pkg = "jsx";
        version = "3.0.0";
        sha256 = "sha256-N77KBDX1yoovRfdqRiEedkGPvvgMNvA2HCSfx1BZ3G0=";
      };
      beamDeps = [ ];
    };
    gradualizer = builder {
      name = "gradualizer";
      version = "git";
      src = fetchFromGitHub {
        owner = "josefs";
        repo = "gradualizer";
        rev = "6e89b4e1cd489637a848cc5ca55058c8a241bf7d";
        sha256 = "1ix0xgd0267ibx6y68fx4pq8q3j0y7rjs7j3cv3v2gdiy190psy9";
      };
      beamDeps = [ ];
    };
    erlfmt = builder {
      name = "erlfmt";
      version = "git";
      src = fetchFromGitHub {
        owner = "gomoripeti";
        repo = "erlfmt";
        rev = "d4422d1fd79a73ef534c2bcbe5b5da4da5338833";
        sha256 = "07jp4g6a41w7318lh8ndsvgivkj0ahz3spnrsnx4cqkdb97yjaid";
      };
      beamDeps = [ ];
    };
    ephemeral = builder {
      name = "ephemeral";
      version = "2.0.4";
      src = fetchHex {
        pkg = "ephemeral";
        version = "2.0.4";
        sha256 = "sha256-Syk9gPdfnEV1/0ucjoiaVoAvQLAYv1fnTxlkTv7myFA=";
      };
      beamDeps = [ bucs ];
    };
    elvis_core = builder {
      name = "elvis_core";
      version = "1.3.1";
      src = fetchHex {
        pkg = "elvis_core";
        version = "1.3.1";
        sha256 = "sha256-eoiQv4GFoyUs1OvYJv5fita5MCTt+IV26yeunl3BnWk=";
      };
      beamDeps = [ katana_code zipper ];
    };
    docsh = builder {
      name = "docsh";
      version = "0.7.2";
      src = fetchHex {
        pkg = "docsh";
        version = "0.7.2";
        sha256 = "sha256-Tn20YbsHVA0rw9NmuFE/AZdxLQSVu4V0TzZ9OBUHYTQ=";
      };
      beamDeps = [ providers ];
    };
    proper_contrib = builder {
      name = "proper_contrib";
      version = "0.2.0";
      src = fetchHex {
        pkg = "proper_contrib";
        version = "0.2.0";
        sha256 = "sha256-jFRRL1zr9JKaG1eqMDfcKk2xe93uOrXUenB14icVCBU=";
      };
      beamDeps = [ proper ];
    };
    proper = builder {
      name = "proper";
      version = "1.3.0";
      src = fetchHex {
        pkg = "proper";
        version = "1.3.0";
        sha256 = "sha256-SqGS/M3dA/2+UP72IL6dTS+SY1tU9V+4OuwYWZRAPLw=";
      };
      beamDeps = [ ];
    };
    meck = builder {
      name = "meck";
      version = "0.9.0";
      src = fetchHex {
        pkg = "meck";
        version = "0.9.0";
        sha256 = "sha256-+BPpDdC4myUWoCAaNV6EsavHi1dRqgy/ZpqdhagQrGM=";
      };
      beamDeps = [ ];
    };
    coveralls = builder {
      name = "coveralls";
      version = "2.2.0";
      src = fetchHex {
        pkg = "coveralls";
        version = "2.2.0";
        sha256 = "sha256-zVTbCqjGS1OSgBicVhns7hOkaiiw8ct3RUTdzBZiBKM=";
      };
      beamDeps = [ jsx ];
    };
  };
in self
