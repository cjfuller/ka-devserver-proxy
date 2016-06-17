## ka-devserver-proxy

A HTTP proxy taken from https://github.com/josevalim/proxy, with custom configuration for proxying the KA devserver.

This configuration:
- serves images and fonts directly
- passes anything containing `_kake` or `genfiles` directly to kake (assumed to be on port 5000; TODO: allow other ports)
- sends everything else on to the devserver (assumed to be on port 8080)

TODO: handle the websocket for the react hotloader

### Installation

You'll need elixir >= 1.0:
http://elixir-lang.org/install.html
Mac OS users, it's just: `brew install elixir`

Then, clone this repository (`git clone https://github.com/cjfuller/ka-devserver-proxy.git`).

`cd ka-devserver-proxy`

Install dependencies:
`mix deps.get`

### Running

`mix serve`

Then access the devserver on port 8081 instead of 8080 to get the proxying.

### License

The proxy code is copyright by Jose Valim and licenced under the MIT License.
Original code is at https://github.com/josevalim/proxy

My modifications are also MIT Licensed.
