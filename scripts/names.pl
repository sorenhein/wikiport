#!perl

use strict;
use warnings;


sub set_MIG
{
  my ($names_ref, $mails_ref) = @_;

  my @archive =
  (
    # Dr. Axel Thierauf
    [ 'MIG: AT',
      [ "Axel Thierauf", "Thierauf, Axel", "Thierauf Axel",
        "AT (intern)", "Axel' 'Thierauf"],
      [ 'at@mig.ag', 'a.t@mig.ag', 'a@mig.ag', 'thierauf@mig.ag', 
        'axel.thierauf@mig.ag',
        'axcel.thierauf@mig.ag', 'xt@mig.ag', 'at@hs984.hostedoffice.ag' ]
    ],

    # Boris Bernstein
    [ 'MIG: BB',
      [ "Bernstein, Boris"],
      [ 'bb@mig.ag']
    ],

    # Cecil Motschmann
    [ 'MIG: CM',
      [ ],
      [ 'cm@mig.ag', 'cecil.motschmann@mig.ag']
    ],

    # Dr. Klaus Feix
    [ 'MIG: KF',
      [ "Dr. Klaus Feix", "Klaus Feix"],
      [ 'kf@mig.ag', 'klaus.feix@mig.ag', 'kf@hs984.hostedoffice.ag']
    ],

    # Jürgen Kosch
    [ 'MIG: JK',
      [ "Jürgen Kosch", "JK (intern)", "Jürgen Kosch (E-Mail)",
        "Jürgen Kosch/MIG Verwaltungs AG", "Kosch, Juergen", 
        "Dipl. Ing. Jürgen Kosch", "JürgenKosch" ],
      [ 'jk@mig.ag', 'juergen.kosch@mig.ag', 'j.kosch@mig.ag', 
        'jurgen.kosch@mig.ag', 'kosch@mig.ag', 'jg@mig.ag', 
        'jko@mig.ag', 'kj@mig.ag', 'jk@hs984.hostedoffice.ag' ]
    ],

    # Kristian Schmidt-Garve
    [ 'MIG: KSG',
      [ "Schmidt-Garve, Kristian"],
      [ 'ksg@mig.ag', 'kristian.schmidt-garve@mig.ag', 
        'kristian.schmidtgarve@mig.ag', 'ksg@hs984.hostedoffice.ag']
    ],

    # Matthias Guth
    [ 'MIG: MG',
      [ "Guth, Matthias", "Matthias"],
      [ 'mg@mig.ag', 'matthias.guth@mig.ag', 'mguth@mig.ag',
        'mg@hs984.hostedoffice.ag']
    ],

    # Dr. Matthias Kromayer
    [ 'MIG: MK',
      [ "Matthias Kromayer", "Kromayer, Matthias", "Kromayer Matthias",
        "Matthias Kromayer (extern)", "Dr. Kromayer (extern) Matthias" ],
      [ 'mk@mig.ag', 'm.k@mig.ag', 'matthias.kromayer@mig.ag', 
        'kromayer@mig.ag', 'mkr@mig.ag', 'mk@hs984.hostedoffice.ag']
    ],

    # Michael Motschmann
    [ 'MIG: MM',
      [ "Michael Motschmann", "Michael Motschmann - MIG AG Fond",
        "Motschmann, Michael"],
      [ 'mm@mig.ag', 'michael.motschmann@mig.ag', 'michael@mig.ag',
        'motschmann@mig.ag', 'mmo@mig.ag', 'mm@hs984.hostedoffice.ag']
    ],

    # Dr. Oliver Kahl
    [ 'MIG: OK',
      [ "Kahl, Oliver"],
      [ 'ok@mig.ag']
    ],

    # Dr. Sören Hein
    [ 'MIG: SH',
      [ "Sören Hein", "Hein, Sören", "Hein, SÃ¶ren"],
      [ 'sh@mig.ag', 'soren.hein@mig.ag', 'soeren.hein@mig.ag', 
        'sh@hs984.hostedoffice.ag']
    ],



    # Anna Chojnacka
    [ 'MIG: ac',
      [ "Chojnacka, Anna"],
      [ 'ac@mig.ag']
    ],

    # Brigitte Eckmaier
    [ 'MIG: be',
      [ "Eckmaier, Brigitte"],
      [ 'be@mig.ag']
    ],

    # Barbara Steingruber-Dotterweich
    [ 'MIG: bs',
      [ "Steingruber-Dotterweich, Barbara"],
      [ 'bs@mig.ag']
    ],

    # Doreen Roebert
    [ 'MIG: dr',
      [ "Roebert, Doreen"],
      [ 'dr@mig.ag']
    ],

    # Gero Fiedler
    [ 'MIG: gf',
      [ "Fiedler, Gero"],
      [ 'gf@mig.ag']
    ],

    # Holger Hinz, AR
    [ 'MIG: hh',
      [ "Holger Clemens Hinz"],
      [ 'hh@mig.ag', 'hch@mig.ag', 'holger.hinz@mig.ag']
    ],

    # Janine Jaschke
    [ 'MIG: jj',
      [ ],
      [ 'jj@mig.ag']
    ],

    # Johannes Musiol
    [ 'MIG: jm',
      [ "Johannes Musiol"],
      [ 'jm@mig.ag']
    ],

    # Katharina Adam
    [ 'MIG: ka',
      [ "Adam, Katharina", "Katharina", "ka"],
      [ 'ka@mig.ag', 'ka.@mig.ag', 'adam@mig.ag']
    ],

    # Lea Gartner
    [ 'MIG: lg',
      [ ],
      [ 'lg@mig.ag']
    ],

    # Marta Berendsen
    [ 'MIG: mb',
      [ "Berendsen, Marta"],
      [ 'mb@mig.ag']
    ],

    # Maria Betz, née Huttner
    [ 'MIG: mbe',
      [ "Maria Huttner", "Betz, Maria"],
      [ 'mbe@mig.ag', 'mh@mig.ag']
    ],

    # Michael Dahm, ehem. AR
    [ 'MIG: md',
      [ ],
      [ 'md@mig.ag']
    ],

    # Martina Fuchs
    [ 'MIG: mf',
      [ ],
      [ 'mf@mig.ag']
    ],

    # Michelle Schmitt
    [ 'MIG: ms',
      [ ],
      [ 'ms@mig.ag', 'ms.@mig.ag']
    ],

    # Milena Simon Schulze
    [ 'MIG: msg',
      [ ],
      [ 'msg@mig.ag']
    ],

    # Monika Stadler
    [ 'MIG: mst',
      [ "Stadler, Monika", "MST Intern"],
      [ 'mst@mig.ag']
    ],

    # Montana Nick
    [ 'MIG: mn',
      [ ],
      [ 'mn@mig.ag', 'mw@mig.ag']
    ],

    # Praktikant
    [ 'MIG: praktikant',
      [ ],
      [ 'praktikant@mig.ag']
    ],

    # Renata Csapo
    [ 'MIG: rc',
      [ "Csapo, Renata"],
      [ 'rc@mig.ag']
    ],

    # Sabine Kosch
    [ 'MIG: sk',
      [ "Sabine Kosch" ],
      [ 'sk@mig.ag']
    ],

    # Theresa Mauer
    [ 'MIG: tm',
      [ "Mauer, Theresa"],
      [ 'tm@mig.ag'],
    ],

    # Yasmin Petermeier, née Horst
    [ 'MIG: yp',
      [ "Petermeier, Yasmin"],
      [ 'yp@mig.ag', 'yh@mig.ag']
    ],



    # businessplan
    [ 'MIG: businessplan',
      [ "business plan"],
      [ 'businessplan@mig.ag', 'business@mig.ag', 'businesplan@mig.ag',
        'businesssplan@mig.ag', 'www.businesslan@mig.ag',
        'beteiligung@mig.ag', 'beteiligungsanfrage@mig.ag', 
        'beiteiligungsanfrage@mig.ag', 
        'beteiligunmgsanfrage@mig.ag', 'beteiligungfanfrage@mig.ag',
        'beteiligungungsanfrage@mig.ag',
        'beteiligunsganfrage@mig.ag',
        'beteiligunsanfrage@mig.ag', 'beteiligungsanfrag@mig.ag',
        'beteiligungsanfragen@mig.ag', 'beteiligungsantrag@mig.ag',
        'beteiligungsgesellschaft@mig.ag']
    ],

    # info
    [ 'MIG: info',
      [ ],
      [ 'info@mig.ag', 'infok@mig.ag', 'iinfo@mig.ag', 'nfo@mig.ag']
    ],

    # fonds
    [ 'MIG: fonds',
      [ ],
      [ 'fonds@mig.ag']
    ],

    # wiki
    [ 'MIG: wiki',
      [ ],
      [ 'wiki@mig.ag']
    ]
  );

  for my $key (@archive)
  {
    my $abbr = $key->[0];
    my $name_ref = $key->[1];
    my $mail_ref = $key->[2];

    $names_ref->{$_} = $abbr for @{$key->[1]};
    $mails_ref->{$_} = $abbr for @{$key->[2]};
  }
}

1;
