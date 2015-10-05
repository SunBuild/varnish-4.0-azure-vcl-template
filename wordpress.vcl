vcl 4.0;
backend default {
    .host = "myapp.domain.com";
    .port = "80";
}

sub vcl_recv {
  set req.http.host = "myapp.domain.com";
  
  if (req.http.Accept-Encoding) {
#revisit this list
    if (req.url ~ "\.(gif|jpg|jpeg|swf|flv|mp3|mp4|pdf|ico|png|gz|tgz|bz2)(\?.*|)$") {
      remove req.http.Accept-Encoding;
    } elsif (req.http.Accept-Encoding ~ "gzip") {
      set req.http.Accept-Encoding = "gzip";
    } elsif (req.http.Accept-Encoding ~ "deflate") {
      set req.http.Accept-Encoding = "deflate";
    } else {
      remove req.http.Accept-Encoding;
    }
  }
  if (req.url ~ "\.(gif|jpg|jpeg|swf|css|js|flv|mp3|mp4|pdf|ico|png)(\?.*|)$") {
    unset req.http.cookie;
    set req.url = regsub(req.url, "\?.*$", "");
  }
  if (req.url ~ "\?(utm_(campaign|medium|source|term)|adParams|client|cx|eid|fbid|feed|ref(id|src)?|v(er|iew))=") {
    set req.url = regsub(req.url, "\?.*$", "");
  }
  if (req.http.cookie) {
    if (req.http.cookie ~ "(wordpress_|wp-settings-)") {
      return(pass);
    } else {
      unset req.http.cookie;
    }
  }
}

sub vcl_fetch {
  if (req.url ~ "wp-(login|admin)" || req.url ~ "preview=true" || req.url ~ "xmlrpc.php") {
    return (hit_for_pass);
  }
  if ( (!(req.url ~ "(wp-(login|admin)|login)")) || (req.request == "GET") ) {
    unset beresp.http.set-cookie;
  }
  if (req.url ~ "\.(gif|jpg|jpeg|swf|css|js|flv|mp3|mp4|pdf|ico|png)(\?.*|)$") {
    set beresp.ttl = 365d;
  }
}

sub vcl_deliver {
# multi-server webfarm? set a variable here so you can check
# the headers to see which frontend served the request
#   set resp.http.X-Server = "server-01";
   if (obj.hits > 0) {
     set resp.http.X-Cache = "HIT";
   } else {
     set resp.http.X-Cache = "MISS";
   }
}
