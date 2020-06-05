package vonf::Controller::Vonf;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw( encode_json decode_json j );
use Mojo::Util qw( b64_encode b64_decode encode decode );

my $err = sub {
   # Invalidate session on any errors
   $_[0]->session->{room_pw} = 0;
   $_[0]->session(expires => 1);
   $_[0]->render('vonf/error', msg => $_[1] // 'Fail', status => $_[2] // 418);
};

my $try_cleanup = sub {
   my ($c, $id) = @_;
   return unless defined $id;
   #TODO implement storage for timers to cancel them on peer connection
   Mojo::IOLoop->timer($c->config->{id_timeout} => sub {
         $c->model_session->destroy_session($id);
      });
};

sub welcome {
   # Just render welcome page
   $_[0]->render();
}

sub logout {
   # Invalidate session
   $try_cleanup->($_[0], $_[0]->session->{room_id});
   $_[0]->session->{room_pw} = 0;
   $_[0]->session(expires => 1);
   $_[0]->redirect_to('/');
}

sub connect {
   my ($c) = @_;

   my $id = $c->stash('id');
   my $uid;

   # Handle possible page reload
   if (
      defined $c->session->{room_id} and $c->session->{room_id} == $id and
      $c->model_session->check_password($id, $c->session->{room_pw})
   ) {
      # Existing conection
      $uid = $c->session->{room_uid};
   } else {
      # Here we suppose new connection
      my $password = $c->model_session->get_password($id);
      return $err->($c, 'No such session...') unless defined $password;

      if ($uid = $c->model_session->attach_peer($id)) {
         # Update HTTP session
         $c->session(expiration => $c->config->{session_timeout});
         $c->session->{room_id} = $id;
         $c->session->{room_pw} = $password;
         $c->session->{room_uid} = $uid;
      } else {
         return $err->($c, 'No free slots');
      }
   }

   $c->render(session_id => $id, peer_id => $uid);
}

sub start {
   my ($c) = @_;
   my $id;

   # Handle possible page reload
   if (defined $c->session->{room_uid} and $c->session->{room_uid} == 0 and
      $c->model_session->check_password(
         $c->session->{room_id}, $c->session->{room_pw})) {
      # Session doesn't require creation
      $id = $c->session->{room_id};
      return $err->($c, 'Your browser overloaded...') unless defined $id;
      return $c->render(session_id => $id);
   }

   # Session creation steps
   my $password = $c->model_session->generate_pw();

   # TODO change limits to configurable values
   $id = $c->model_session->create_session($password, 1, 2);
   return $err->($c, 'Try later...') unless defined $id;

   # Unless nobody connected
   $try_cleanup->($c, $id);

   # Update HTTP session
   $c->session(expiration => $c->config->{session_timeout});
   $c->session->{room_id} = $id;
   $c->session->{room_pw} = $password;
   $c->session->{room_uid} = 0;

   $c->render(session_id => $id);
}

sub auth {
   my ($c) = @_;
   my $room_id = $c->session->{room_id};
   my $room_pw = $c->session->{room_pw};

   return $err->($c, 'Not authenticated'), undef unless
   $c->model_session->check_password($room_id, $room_pw);

   return 1;
}

sub ws {
   my ($c) = @_;
   my $id = $c->session->{room_id};
   my $uid = $c->session->{room_uid};

   $c->inactivity_timeout($c->config->{session_timeout});

   my $ps_callback = $c->model_session->attach_peer_ws($id, $uid, sub {
         my $json = decode_json($_[1]);
         # Callback for any notifications DB -> WS
         if ($json->{type} eq "text") {
            # TODO implement on client-side to avoid one extra transmission?
            # Skip self messages
            #return if $json->{src} eq $uid;

            # Get message from DB
            my $msg = $c->model_session->get_message($id, $json->{payload});
            return $err->($c, 'Message not found') unless defined $msg;

            return $c->send(j({type => "text", payload => $msg}));
         } elsif ($json->{type} eq "peer" ) {
            # Skip self messages
            return if $json->{payload} == 0 and $json->{src} eq $uid;

            return $c->send(j({type => "peer", payload => [
                        $json->{src}, $json->{payload}
                     ]}));
         } elsif ($json->{type} eq "file" ) {
            return $c->send(j({type => "file", payload => $json->{payload}}));
         } elsif ($json->{type} eq "link" ) {
            my $url = $c->url_for("/s/f/$id/" . $json->{payload})->to_abs;
            $c->send(j({type => "link", payload => $url}));
         } else {
            return $err->($c, 'PSM unknown');
         }
      });

   return $err->($c, 'Subscription failed') unless defined $ps_callback;

   $c->on(json => sub {
         my $json = $_[1];
         return $err->($c, 'WSM unknown') unless $json->{type} eq "text";
         # TODO handle errors?
         $c->model_session->send_message($id, $uid, $json->{payload});
      });

   $c->on(finish => sub {
         # Unsubscribe pubsub
         $c->model_session->detach_peer_ws($id, $uid, $ps_callback);

         $try_cleanup->($c, $id);
      });
}

sub upload {
   my ($c) = @_;
   my $id = $c->session->{room_id};
   my $uid = $c->session->{room_uid};
   my $base = $c->config->{file_base};
   my $left = @{$c->req->uploads('file')};

   mkdir "$base/$id" unless -d "$base/$id";

   for my $file (@{$c->req->uploads('file')}) {
      my $name = b64_encode encode 'UTF-8', $file->filename;

      my $file_id = $c->model_session->send_file($id, $uid, $name, "//id") ;
      return $err->($c, 'File upload failed') unless defined $file_id;

      my $path = "$base/$id/$file_id";
      return $err->($c, 'File save failed') if $file != $file->move_to($path);
      $left--;
   }

   if ($left == 0) {
      # Successfully uploaded all files
      return $c->render(text => 'All files saved!');
   } else {
      # Some errors found
      return $c->render(text => 'Unable to save all files!', status => 418);
   }
}

sub download {
   my ($c) = @_;
   my $id = $c->session->{room_id};
   my $file_id = $c->stash('file_id');
   my $file_info = $c->model_session->get_file_info($id, $file_id);
   return $err->($c, 'File not found', 404) unless defined $file_info;

   my ($file_name, $file_path) = @{$file_info};
   $file_name = b64_decode $file_name;

   # In general, there is an architectural solution to store the filepath
   # inside file_info to be able to store files in distributed DB.
   # So far, the storage is FS and the path is constructed manually:
   if ($file_path eq "//id") {
      # Special case to store file on FS
      $file_path = $c->config->{file_base} . "/$id/$file_id";
   }
   
   my $rc = $c->render_file(filepath => $file_path, filename => $file_name);
   return $err->($c, 'Unable to find', 404) unless defined $rc;
}

1;
