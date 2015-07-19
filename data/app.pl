use Mojolicious::Lite;
use Mango;
use Mango::BSON ':bson';

my $uri = 'mongodb://localhost:27017/test';
helper mango => sub { state $mango = Mango->new($uri) };

# Store and retrieve information non-blocking
get '/' => sub {
  my $c = shift;

  my $collection = $c->mango->db->collection('visitors');
  my $ip         = $c->tx->remote_address;

  # Store information about current visitor
  $collection->insert({when => bson_time, from => $ip} => sub {
    my ($collection, $err, $oid) = @_;

    return $c->render_exception($err) if $err;

    # Retrieve information about previous visitors
    $collection->find->sort({when => -1})->fields({_id => 0})->all(sub {
      my ($collection, $err, $docs) = @_;

      return $c->render_exception($err) if $err;

      # And show it to current visitor
      $c->render(json => $docs);
    });
  });
};

app->start;