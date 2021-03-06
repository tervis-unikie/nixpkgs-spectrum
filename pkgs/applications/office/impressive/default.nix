{ fetchurl, stdenv, python2, makeWrapper, lib
, SDL, ghostscript, pdftk, dejavu_fonts }:

let
  version = "0.12.1";
  pythonEnv = python2.withPackages (ps: with ps; [pyopengl pygame pillow]);
in stdenv.mkDerivation {
    # This project was formerly known as KeyJNote.
    # See http://keyj.emphy.de/apple-lawsuit/ for details.

    pname = "impressive";
    inherit version;

    src = fetchurl {
      url = "mirror://sourceforge/impressive/Impressive-${version}.tar.gz";
      sha256 = "1r7ihv41awnlnlry1kymb8fka053wdhzibfwcarn78rr3vs338vl";
    };

    nativeBuildInputs = [ makeWrapper ];
    buildInputs = [ pythonEnv ];

    configurePhase = ''
      # Let's fail at build time if the library we're substituting in doesn't
      # exist/isn't marked as executable
      test -x ${SDL}/lib/libSDL.so
      sed -i "impressive.py" \
          -e '/^__website__/a SDL_LIBRARY = "${SDL}/lib/libSDL.so"' \
          -e 's/sdl = CDLL.*/sdl = CDLL(SDL_LIBRARY)/' \
          -e 's^FontPath =.*/usr/.*$^FontPath = ["${dejavu_fonts}/share/fonts", ""]^'
    '';

    installPhase = ''
      mkdir -p "$out/bin" "$out/share/doc/impressive" "$out/share/man/man1"
      mv impressive.py "$out/bin/impressive"
      mv impressive.1 "$out/share/man/man1"
      mv changelog.txt impressive.html license.txt "$out/share/doc/impressive"

      wrapProgram "$out/bin/impressive" \
         --prefix PATH ":" "${ghostscript}/bin:${pdftk}/bin"
    '';

    meta = {
      description = "Impressive, an effect-rich presentation tool for PDFs";

      longDescription = ''
        Impressive is a program that displays presentation slides.
        But unlike OpenOffice.org Impress or other similar
        applications, it does so with style.  Smooth alpha-blended
        slide transitions are provided for the sake of eye candy, but
        in addition to this, Impressive offers some unique tools that
        are really useful for presentations.  Read below if you want
        to know more about these features.

        Creating presentations for Impressive is very simple: You just
        need to export a PDF file from your presentation software.
        This means that you can create slides in the application of
        your choice and use Impressive for displaying them.  If your
        application does not support PDF output, you can alternatively
        use a set of pre-rendered image files ??? or you use Impressive
        to make a slideshow with your favorite photos.
      '';

      homepage = "http://impressive.sourceforge.net/";

      license = lib.licenses.gpl2;

      maintainers = with lib.maintainers; [ lheckemann ];
      platforms = lib.platforms.mesaPlatforms;
    };
  }
