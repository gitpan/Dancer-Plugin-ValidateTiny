package Dancer::Plugin::ValidateTiny;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use Validate::Tiny ':all';
use Email::Valid;


our $VERSION = '0.01';

my $settings = plugin_setting;


register validator => sub
{
	my ($params, $rules_file) = @_;

	my $result = {};

	# Loading rules from file
	my $rules = _load_rules($rules_file);

	# Validating
	my $validator = Validate::Tiny->new($params, $rules);

	# If you need a full Validate::Tiny object
	if($settings->{is_full} eq 1)
	{
		return $validator;
	}

	if($validator->success)
	{
		# All ok
		$result = {
			result => $validator->data,
			valid => $validator->success
			};
	}
	else
	{
		# Returning errors
		if(exists $settings->{error_prefix})
		{
			# With error prefixes from config
			$result = {
				result => _set_error_prefixes($validator->error),
				valid => $validator->success
				};
		}
		else
		{
			# Without error prefixes
			$result = {
				result => $validator->error,
				valid => $validator->success
				};
		}
	}

	# Combining filtered params and validation results
	%{$result->{result}} = (%{$result->{result}}, %{$validator->data});

	# Returning validated data
	return $result;
};

sub _set_error_prefixes
{
	my $errors = shift;

	foreach my $error (keys %{$errors})
	{
		# Replacing keys with prefix. O_o
		$errors->{$settings->{error_prefix} . $error} = delete $errors->{$error};
	}

	return $errors;
}

sub _load_rules
{
	my $rules_file = shift;

	# Checking plugin settings and rules file for existing
	die "Rules directory not specified in plugin settings!" if !$settings->{rules_dir};
	die "Rules file not specified!" if !$rules_file;

	# Making full path to rules file
	$rules_file = setting('appdir') . '/' . $settings->{rules_dir} . "/" . $rules_file;

	# Putting rules from file to $rules
	my $rules = do $rules_file || die $! . "\n" . $@;

	return $rules;
}


sub check_email
{
	my ($email, $message) = @_;
	Email::Valid->address($email) ? undef : $message;
}


register_plugin;


1;
__END__

=head1 NAME

Dancer::Plugin::ValidateTiny - Validate::Tiny dancer plugin.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Easy and pretty cool validating data with Validate::Tiny module:

    use Dancer::Plugin::ValidateTiny;
    
    post '/' => sub {
        my $params = params;
        my $data_valid = 0;
    
        # Validating params with rule file
        my $data = validator($params, 'form.pl');
    
        if($data->{valid}) { ... }
    };

Rule file is pretty too:

    {
        # Fields for validating
        fields => [qw/login email password password2/],
        filters => [
            # Remove spaces from all
            qr/.+/ => filter(qw/trim strip/),
    
            # Lowercase email
            email => filter('lc'),
        ],
        checks => [
            [qw/login email password password2/] => is_required("Field required!"),
            
            login => is_long_between( 2, 25, 'Your login should have between 2 and 25 characters.' ),
            email => sub {
                # Note, that @_ contains value to be checked
                # and a reference to the filtered input hash
                check_email($_[0], "Please enter a valid email address.");
                },
            password => is_long_between( 4, 40, 'Your password should have between 4 and 40 characters.' ),
            password2 => is_equal("password", "Passwords don't match"),
        ],
    }

=head1 DESCRIPTION

Dancer::Plugin::ValidateTiny - is a simple wrapper for use Validate::Tiny module.

=head1 CONFIG

In your config you can use there options:

    plugins:
      ValidateTiny:
        rules_dir: validation
        error_prefix: err_
        is_full: 0

=head2 Config options

=over

=item rules_dir

Directory, where you can store your rule files with .pl extension.

=item error_prefix

Prefix, that used to separate error fields from normal values in resulting hash

=item is_full

If this option is set to 1, call of C<validator> returning
an object, that you can use as standart Validate::Tiny object.

=back

=head1 AUTHOR

Alexey Kolganov, <akalgan at gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Alexey Kolganov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
