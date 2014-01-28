use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Config::Tiny;   # to read .ini files

my $tzil = Builder->from_config(
    { dist_root => 't/does_not_exist' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                [ GatherDir => ],
                [ 'MungeFile::WithConfigFile' => { finder => ':MainModule', configfile => 'config.ini', house => 'maison' } ],
            ),
            'source/config.ini' => <<'CONFIG',
dog = chien
cat = chat
bird = oiseau
CONFIG
            'source/lib/Module.pm' => <<'MODULE'
package Module;

my $string = {{
'"our config data is:' . "\n"
. join("\n", map { $_ . ' => ' . $config_data->{$_} } sort keys %$config_data)
. "\n" . 'And that\'s just great!\n"'
}};
my ${{ $house }} = 'my castle';
1;
MODULE
        },
    },
);

$tzil->build;

my $content = $tzil->slurp_file('build/lib/Module.pm');

is(
    $content,
    <<'NEW_MODULE',
package Module;

my $string = "our config data is:
bird => oiseau
cat => chat
dog => chien
And that's just great!\n";
my $maison = 'my castle';
1;
NEW_MODULE
    'module content is transformed',
);

done_testing;
