package vonf::Model::Session;
use Mojo::Base -base;
use Mojo::JSON qw( encode_json decode_json j );
use Mojo::Util qw( b64_encode b64_decode xml_escape );

has 'pg';
has 'config';

# PRIVATE
my $id_encrypt = sub {
   #TODO
   my ($id) = @_;
   #TODO get from config
   my $len = 5;
   return unless $len >= 1;
   return sprintf "%0${len}d", $id;
};

my $id_decrypt = sub {
   #TODO
   my ($id) = @_;
   #TODO get from config
   my $len = 5;
   return int $id;
};

my $db_notify = sub {
   my ($c, $id, $type, $src, $payload) = @_;
   return 0 unless defined $payload;
   $c->pg->pubsub->notify($id => encode_json {
         type => $type, src => $src, payload => $payload
      });
};

# PUBLIC
sub generate_pw {
   #TODO
   my $password = int(10**5 * rand());
   print STDERR "PW: $password\n";
   return $password;
}

sub destroy_session {
   my ($c, $id) = @_;
   return unless defined $id;

   my $result = $c->pg->db->select('Session', ['peers_ws'],
      { id => $id_decrypt->($id) })->array;
   return unless defined $result;

   my $peers_ws = $result->[0];
   return unless defined $peers_ws and $peers_ws == 0;

   # TODO cleanup filesystem

   $c->pg->db->delete('Files', { session_id => $id_decrypt->($id) });

   $c->pg->db->delete('Session', { id => $id_decrypt->($id) });

   return 1;
};

sub create_session {
   #TODO
   my ($c, $password, $files_limit, $peers_limit) = @_;

   defined $_[$_] or return for (0..3);

   return unless $files_limit >= 0;
   return unless $peers_limit > 0;

   my $id = $c->pg->db->insert('Session', {
         password => $password,
         files_limit => $files_limit,
         files_current => 0,
         peers_limit => $peers_limit,
         peers_current => 1,
         peers_ws => 0
      }, { returning => 'id' })->array->[0];
   
   return $id_encrypt->($id);
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

sub get_password {
   my ($c, $id) = @_;

   my $result = $c->pg->db->select('Session', ['password'],
      { id => $id_decrypt->($id) })->array;
   return unless defined $result and length $result->[0];

   return $result->[0];
}

sub check_password {
   my ($c, $id, $password) = @_;

   return unless defined $id and defined $password;
   my $real_password = $c->get_password($id);
   return unless defined $real_password;

   return $password eq $real_password;
}

sub get_file_info {
   #TODO
   my ($c, $id, $file_id) = @_;
   
   return ["filename", "filepath"];
}

sub get_message {
   my ($c, $id, $msg_id) = @_;

   # Extract message from DB
   my $result = $c->pg->db->select('Messages', ['text'],
      { id => $msg_id, session_id => $id_decrypt->($id) })->array;
   return unless defined $result;

   return xml_escape b64_decode $result->[0];
}

sub send_message {
   my ($c, $id, $src, $msg) = @_;

   # Escape the message
   $msg = b64_encode $msg;

   # Store message to DB
   my $msg_id = $c->pg->db->insert('Messages', {
         session_id => $id_decrypt->($id),
         text => $msg
      }, { returning => 'id' })->array->[0];

   # Send DB notification
   return $c == $db_notify->($c, $id, "text", $src, $msg_id);
}

sub send_file {
   #TODO
   my ($c, $id, $filename, $filepath) = @_;

   return 1;
}

sub attach_peer {
   my ($c, $id) = @_;

   my $result;
   eval {
      $result = $c->pg->db->query('UPDATE "Session" SET peers_current = ' .
         'peers_current + 1 WHERE id = ?', $id_decrypt->($id));
   };
   print STDERR "($@)($!)\n";
   return unless defined $result;

   return $result->rows;
}

sub attach_peer_ws {
   my ($c, $id, $uid, $ws_callback) = @_;

   defined $_[$_] or return for (0..3);
   eval {
      $c->pg->db->query(
         'UPDATE "Session" SET peers_ws = peers_ws + 1 WHERE id = ?',
         $id_decrypt->($id)
      );
   };
   my $ret = $c->pg->pubsub->listen($id => $ws_callback);
   $db_notify->($c, $id, "peer", $uid, 1);
   return $ret;
}

sub detach_peer_ws {
   my ($c, $id, $uid, $ps_callback) = @_;

   defined $_[$_] or return for (0..3);
   eval {
      $c->pg->db->query(
         'UPDATE "Session" SET peers_ws = peers_ws - 1 WHERE id = ?',
         $id_decrypt->($id)
      );
   };
   $db_notify->($c, $id, "peer", $uid, 0);
   return $c->pg->pubsub->unlisten($id => $ps_callback);
}

1;
