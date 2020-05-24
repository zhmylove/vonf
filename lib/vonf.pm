package vonf;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});

  # Postgres helper
  $self->helper(pg => sub { state $pg = Mojo::Pg->new($_[0]->config('pg')) });

  # Model helper
  $self->helper(model_session => sub {
        state $model_session = vonf::Model::Session->new(pg => $_[0]->pg)
     });

  # Regex for ID validation
  my $re_id = qr/\d{$config->{id_len}}/;

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('vonf#welcome');
  $r->get('/connect/#id' => [id => $re_id])->to('vonf#connect');
  $r->get('/start')->to('vonf#start');

  my $auth = $r->under('/s/')->to('vonf#auth');
  $auth->websocket('ws/#id' => [id => $re_id])->to('vonf#ws');
  $auth->post('up/#id' => [id => $re_id])->to('vonf#upload');
  $auth->get('f/#id' => [id => $re_id])->to('vonf#download');
}

1;
