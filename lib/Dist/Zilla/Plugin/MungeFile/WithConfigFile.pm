use strict;
use warnings;
package Dist::Zilla::Plugin::MungeFile::WithConfigFile;
# ABSTRACT: Modify files in the build, with templates and config data from a file
# KEYWORDS: plugin file content injection modification template configuration file
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.005';

use Moose;
extends 'Dist::Zilla::Plugin::MungeFile';
with 'MooseX::SimpleConfig';
use namespace::autoclean;

has configfile => (
    is => 'ro', isa => 'Str',
    required => 1,
);

has _config_data => (
    is => 'ro', isa => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->get_config_from_file($self->configfile);
    },
);

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{'' . __PACKAGE__} = {
        configfile => $self->configfile,
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};

sub munge_file
{
    my ($self, $file) = @_;

    $self->next::method(
        $file,
        { config_data => \($self->_config_data) },
    );
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [MungeFile::WithConfigFile]
    file = lib/My/Module.pm
    house = maison
    configfile = data.json

And during the build, F<lib/My/Module.pm>:

    my $some_string = '{{ expensive_build_time_sub($config_data{some_field}) }}';
    my ${{ $house }} = 'my castle';

Is transformed to:

    my $some_string = 'something derived from data in config file';
    my $maison = 'my castle';

=head1 DESCRIPTION

=for stopwords FileMunger

This is a L<FileMunger|Dist::Zilla::Role::FileMunger> plugin for
L<Dist::Zilla> that passes a file(s)
through a L<Text::Template>, with a variable provided that contains data
read from the provided config file.

L<Text::Template> is used to transform the file by making the C<< $config_data >>
variable available to all code blocks within C<< {{ }} >> sections.

This data is extracted from the provided C<configfile> using L<Config::Any>,
so a variety of file formats are supported, including C<JSON>, C<YAML> and
C<INI>.

The L<Dist::Zilla> object (as C<$dist>) and this plugin (as C<$plugin>) are
also made available to the template, for extracting other information about
the build.

Additionally, any extra keys and values you pass to the plugin are passed
along in variables named for each key.

=for Pod::Coverage munge_files munge_file mvp_aliases

=head1 OPTIONS

=head2 C<finder>

=for stopwords FileFinder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
files to modify.

Other pre-defined finders are listed in
L<Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> plugin.

There is no default.

=head2 C<file>

Indicates the filename in the dist to be operated upon; this file can exist on
disk, or have been generated by some other plugin.  Can be included more than once.

B<At least one of the C<finder> or C<file> options is required.>

=head2 C<arbitrary option>

All other keys/values provided will be passed to the template as is.

=head1 CAVEATS

Presently, the config file is not read with any sort of file decoding (e.g.
UTF-8), so any extracted strings should be appropriately decoded first. This
is an issue that needs to be resolved in L<Config::Any> (perhaps by having the
caller, in our case L<MooseX::SimpleConfig>, to pass the desired decoding).

=head1 SEE ALSO

=for :list
* L<Dist::Zilla::Plugin::Substitute>
* L<Dist::Zilla::Plugin::GatherDir::Template>
* L<Dist::Zilla::Plugin::MungeFile>
* L<Dist::Zilla::Plugin::MungeFile::WithDataSection>

=cut
