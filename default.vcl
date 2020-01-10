vcl 4.0;
# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
#
# Default backend definition.  Set this to point to your content
# server.
#
backend default {
    .host = "127.0.0.1";
    .port = "8080";
    .connect_timeout = 3s;
    .first_byte_timeout = 120s;
    .between_bytes_timeout = 120s;
}
acl purge {
    "127.0.0.1";
}
#
# Below is a commented-out copy of the default VCL logic.  If you
# redefine any of these subroutines, the built-in logic will be
# appended to your code.
sub vcl_recv {
    # Handle compression correctly. Different browsers send different
    # "Accept-Encoding" headers, even though they mostly all support the same
    # compression mechanisms. By consolidating these compression headers into
    # a consistent format, we can reduce the size of the cache and get more hits.
    # @see: http:// varnish.projects.linpro.no/wiki/FAQ/Compression
    if (req.http.Accept-Encoding) {
      if (req.http.Accept-Encoding ~ "gzip") {
        # If the browser supports it, we'll use gzip.
        set req.http.Accept-Encoding = "gzip";
      }
      else if (req.http.Accept-Encoding ~ "deflate") {
        # Next, try deflate if it is supported.
        set req.http.Accept-Encoding = "deflate";
      }
      else {
        # Unknown algorithm. Remove it and send unencoded.
        unset req.http.Accept-Encoding;
      }
    }
    if (req.restarts == 0) {
        if (req.http.x-forwarded-for) {
            set req.http.X-Forwarded-For =
            req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }
    if (req.method == "BAN") {
        if (!client.ip ~ purge) {
            return (synth(405, "Not allowed."));
        }
        # This option is to clear any cached object containing the req.url
        if (req.http.x-ban-url) {
            ban("req.url ~ "+req.http.x-ban-url);
        } else {
            ban("req.url ~ "+req.url);
        }
        # This option is to clear any cached object matches the exact req.url
        # ban("req.url == "+req.url);
        # This option is to clear any cached object containing the req.url
        # AND matching the hostname.
        # ban("req.url ~ "+req.url+" && req.http.host == "+req.http.host);
        return (synth(200, "Cache Cleared Successfully."));
    }
    if (req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }
    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pass);
    }
    #if (req.url ~ "^/") {
    #    return (pass);
    # }
    if (req.url ~ "^/skin"
    || req.url ~ "^/configurator/init/getPrices"
    || req.url ~ "^/configurator/init/getConfiguratorOptions"
    || req.url ~ "^/configurator/init/getDeviceStock"
    || req.url ~ "^/configurator/init/getAccessoriesStock"
    || req.url ~ "^/configurator/init/getProductpopupdata"
    || req.url ~ "^/configurator/init/getProducts"
    || req.url ~ "^/configurator/cart/getRules"
    || req.url ~ "^/js"
    || req.url ~ "^/media"
    || req.url ~ "^/dist"
    || req.url ~ "^/proxy.php?url=/api/v1/customer/search/config")
   {
        unset req.http.Cookie;
    }
    if (req.http.Authorization || req.http.Cookie) {
        /* Not cacheable by default */
        return (pass);
    }
    return (hash);
}
sub vcl_pipe {
    # Note that only the first request to the backend will have
    # X-Forwarded-For set.  If you use X-Forwarded-For and want to
    # have it set for all requests, make sure to have:
    # set bereq.http.connection = "close";
    # here.  It is not set by default as it might break some broken web
    # applications, like IIS with NTLM authentication.
    return (pipe);
}
sub vcl_pass {
    return (fetch);
}
sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }
    return (lookup);
}
sub vcl_hit {
    return (deliver);
}
sub vcl_miss {
    return (fetch);
}
sub vcl_backend_response {
    if (bereq.url ~ "^/skin"
    || bereq.url ~ "^/configurator/init/getPrices"
    || bereq.url ~ "^/configurator/init/getConfiguratorOptions"
    || bereq.url ~ "^/configurator/init/getDeviceStock"
    || bereq.url ~ "^/configurator/init/getAccessoriesStock"
    || bereq.url ~ "^/configurator/init/getProductpopupdata"
    || bereq.url ~ "^/configurator/init/getProducts"
    || bereq.url ~ "^/configurator/cart/getRules"
    || bereq.url ~ "^/js"
    || bereq.url ~ "~/media"
    || bereq.url ~ "~/dist"
    || bereq.url ~ "~/proxy.php?url=/api/v1/customer/search/config") {
        if(bereq.url ~ "~/media" || bereq.url ~ "^/js" || bereq.url ~ "^/skin" || bereq.url ~ "^/dist" || bereq.url ~ "^/proxy.php?url=/api/v1/customer/search/config" || bereq.url ~ "^/configurator/init/getPrices"  || bereq.url ~ "^/configurator/init/getConfiguratorOptions" || bereq.url ~ "^/configurator/init/getDeviceStock" || bereq.url ~ "^/configurator/init/getProductpopupdata" || bereq.url ~ "^/configurator/init/getProducts" || bereq.url ~ "^/configurator/cart/getRules"){
            # Handle custom assets cache
        } else{
            unset beresp.http.Cache-Control;
            unset beresp.http.Expires;
            unset beresp.http.Pragma;
        }
        unset beresp.http.Cache;
        unset beresp.http.Server;
        unset beresp.http.Set-Cookie;
        unset beresp.http.Age;
        set beresp.ttl = 21d;
        set beresp.http.X-Cacheable = "Cachable";
    }
    if (beresp.ttl <= 0s ||
        beresp.http.Set-Cookie ||
        beresp.http.Vary == "*") {
        /*
         * Mark as "Hit-For-Pass" for the next 2 minutes
         */
        set beresp.ttl = 120 s;
        # set beresp.ttl = 120s;
        set beresp.uncacheable = true;
        return (deliver);
    }
    if (beresp.status != 200 && !(bereq.url ~ "^/media")) {
        # set beresp.ttl = 120s;
        set beresp.uncacheable = true;
        return (deliver);
    }
    return (deliver);
}
sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
    return (deliver);
}
sub vcl_backend_error {
    set beresp.http.Content-Type = "text/html; charset=utf-8";
    set beresp.http.Retry-After = "5";
    synthetic({"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>"} + beresp.status + " " + beresp.reason + {"</title>
  </head>
  <body>
    <h1>Error "} + beresp.status + " " + beresp.reason + {"</h1>
    <p>"} + beresp.reason + {"</p>
    <h3>Guru Meditation:</h3>
    <p>XID: "} + bereq.xid + {"</p>
    <hr>
    <p>Varnish cache server</p>
  </body>
</html>
"});
    return (deliver);
}
sub vcl_synth {
    set resp.http.Content-Type = "text/html; charset=utf-8";
    set resp.http.Retry-After = "5";
    synthetic({"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>"} + resp.status + " " + resp.reason + {"</title>
  </head>
  <body>
    <h1>Error "} + resp.status + " " + resp.reason + {"</h1>
    <p>"} + resp.reason + {"</p>
    <h3>Guru Meditation:</h3>
    <p>XID: "} + req.xid + {"</p>
    <hr>
    <p>Varnish cache server</p>
  </body>
</html>
"});
    return (deliver);
}
sub vcl_init {
    return (ok);
}
sub vcl_fini {
    return (ok);
}
