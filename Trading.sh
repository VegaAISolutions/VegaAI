docker build . -f Dockerfile.Trading  -t "phillmac/vega-trading:latest"
docker run -it --rm -p 5001:5001 --name VegaIS \
-e "telegram_bot_token=" \
-e "apiai_bearer=" \
-e "quandl_key=" \
-e "pol_key=" \
-e "pol_secret=" \
phillmac/vega-trading:latest
