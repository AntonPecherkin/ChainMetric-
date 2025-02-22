#!/usr/bin/env bash

node_count=$1
start_peer_port=6331
start_public_port=8000
path_to_app=~/.cargo/bin/exonum-cryptocurrency-advanced

cd backend && mkdir example && cd example
echo "Working directory: $(pwd)"

$path_to_app generate-template common.toml --validators-count $node_count

for i in $(seq 0 $((node_count - 1)))
do
  peer_port=$((start_peer_port + i))
  $path_to_app generate-config common.toml $((i + 1)) --peer-address 127.0.0.1:${peer_port} -n
done

for i in $(seq 0 $((node_count - 1)))
do
  public_port=$((start_public_port + i))
  private_port=$((public_port + node_count))
  eval $path_to_app finalize --public-api-address 0.0.0.0:${public_port} \
      --private-api-address 0.0.0.0:${private_port} $((i + 1))/sec.toml $((i + 1))/node.toml \
      --public-configs {1..$node_count}/pub.toml
done

for i in $(seq 0 $((node_count - 1)))
do
  public_port=$((start_public_port + i))
  private_port=$((public_port + node_count))
  $path_to_app run --node-config $((i + 1))/node.toml --db-path $((i + 1))/db --public-api-address 0.0.0.0:${public_port} --consensus-key-pass pass --service-key-pass pass | tee $((i)).log &
  echo "new node with ports: $public_port (public) and $private_port (private)"
  sleep 1
done

cd ../../frontend
npm start -- --port=$((start_public_port + 2 * node_count)) --api-root=http://127.0.0.1:${start_public_port}
