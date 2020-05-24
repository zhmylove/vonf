package vonf::Model::Session;
use Mojo::Base -base;

has 'pg';

# Private
my $generate_id = sub {
   #TODO 
   return 12345;
};

my $destroy_session = sub {
   #TODO
   my ($id) = @_;
   return 1;
};

# Public
sub create_session {
   #TODO
   my ($c, $password, $files_limit, $peers_limit) = @_;

   my $id = $generate_id->();
   return undef unless defined $id;
   
   return $id;
}

sub check_password {
   #TODO
   my ($c, $id, $password) = @_;
   
   return 1;
}

sub check_file_available {
   #TODO
   my ($c, $id) = @_;
   
   return 1;
}

sub check_peer_available {
   #TODO
   my ($c, $id) = @_;
   
   return 1;
}

sub get_file_info {
   #TODO
   my ($c, $id, $file_id) = @_;
   
   return ["filename", "filepath");
}

sub get_message {
   #TODO
   my ($c, $id, $msg_id) = @_;

   return "message";
}

sub send_message {
   #TODO
   my ($c, $id, $msg) = @_;

   return 1;
}

sub send_file {
   #TODO
   my ($c, $id, $filename, $filepath) = @_;

   return 1;
}

sub attach_peer_ws {
   #TODO
   my ($c, $id, $callback) = @_;

   return 1;
}

sub detach_peer_ws {
   #TODO
   my ($c, $id) = @_;

   return 1;
}

1;
