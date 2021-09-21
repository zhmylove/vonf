package vonf;
use Mojo::Base 'Mojolicious';

use vonf::Model::Session;
use Mojo::Pg;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Load plugins
  $self->plugin('RenderFile');

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});

  # Postgres helper
  $self->helper(pg => sub { state $pg = Mojo::Pg->new($_[0]->config('pg')) });

  # Instantiate DB
  my $sql_file = $self->home->child('sql', 'vonf.sql');
  $self->pg->auto_migrate(1)->migrations->from_file($sql_file)->migrate;

  # TODO maybe from confug?
  # Folder for file uploads
  $config->{file_base} = $self->home->child('upload');
  die "$config->{file_base}: no such directory" unless -d $config->{file_base};

  # Model helper
  $self->helper(model_session => sub {
        state $model_session = vonf::Model::Session->new(
           pg => $_[0]->pg,
           config => $config,
        )
     });

  # Regex for ID validation
  my $re_id = qr/\d{$config->{id_len}}/;

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('vonf#welcome');
  $r->get('/c/#id' => [id => $re_id])->to('vonf#connect');
  $r->get('/start')->to('vonf#start');

  my $auth = $r->under('/s')->to('vonf#auth');
  $auth->websocket('ws/#id' => [id => $re_id])->to('vonf#ws');
  $auth->post('up/#id' => [id => $re_id])->to('vonf#upload');
  $auth->get('f/#id/<file_id:num>' => [id => $re_id])->to('vonf#download');
  $auth->get('logout')->to('vonf#logout');
  $auth->get('p/#id' => [id => $re_id])->to('vonf#peers');
}

1;
