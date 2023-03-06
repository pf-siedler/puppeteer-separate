FROM nixos/nix:2.9.2

WORKDIR /workdir

RUN nix-env -iA nixpkgs.tini
RUN nix-env -iA nixpkgs.nodejs-16_x
RUN nix-env -iA nixpkgs.yarn


COPY . .

RUN \
  nix-build -o result && \
  nix-collect-garbage -d

WORKDIR /workdir/result

ENTRYPOINT ["/root/.nix-profile/bin/tini", "--"]

CMD ["node", "dest"]
