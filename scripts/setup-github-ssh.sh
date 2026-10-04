#!/usr/bin/env bash
set -euo pipefail

ssh_dir="$HOME/.ssh"
private_key="$ssh_dir/id_ed25519"
public_key="$private_key.pub"

if [[ ! -e $private_key && ! -e $public_key ]]; then
  echo 'Generating an Ed25519 key for GitHub authentication...'
  install -d -m 700 "$ssh_dir"
  ssh-keygen -t ed25519 -f "$private_key" -C "$(id -un)@$(hostname)"
elif [[ -f $private_key && ! -e $public_key ]]; then
  echo 'Restoring the public key from the existing private key...'
  temp_key=$(mktemp "$ssh_dir/.id_ed25519.pub.XXXXXX")
  if ! ssh-keygen -y -f "$private_key" > "$temp_key"; then
    rm -f -- "$temp_key"
    exit 1
  fi
  chmod 644 "$temp_key"
  mv -- "$temp_key" "$public_key"
elif [[ ! -f $private_key || ! -f $public_key ]]; then
  echo 'The SSH key pair is incomplete; resolve ~/.ssh/id_ed25519 before retrying.' >&2
  exit 1
fi

if [[ $(awk 'NR == 1 { print $1 }' "$public_key") != ssh-ed25519 ]] ||
   ! ssh-keygen -l -f "$public_key" >/dev/null; then
  echo 'The existing public key is not a valid Ed25519 key.' >&2
  exit 1
fi
key_identity=$(awk 'NR == 1 { print $1 " " $2 }' "$public_key")

if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo 'Sign in to GitHub to check your SSH authentication keys...'
  gh auth login -h github.com -p ssh --skip-ssh-key \
    -s read:public_key,write:public_key
fi

if ! account_keys=$(gh api user/keys --paginate --jq '.[].key'); then
  echo 'Refreshing GitHub CLI key permissions...'
  gh auth refresh -h github.com -s read:public_key,write:public_key
  account_keys=$(gh api user/keys --paginate --jq '.[].key')
fi

if printf '%s\n' "$account_keys" | awk 'NF >= 2 { print $1 " " $2 }' |
   grep -Fxq -- "$key_identity"; then
  echo 'The SSH authentication key is already on your GitHub account.'
else
  echo 'Adding the SSH authentication key to your GitHub account...'
  gh ssh-key add "$public_key" --type authentication \
    --title "$(id -un)@$(hostname) (Arch)"
fi
