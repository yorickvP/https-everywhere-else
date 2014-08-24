[https-everywhere-rules](https://github.com/fmap/https-everywhere-rules)
========================================================================

![](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTqn7bFPbRaxk-XU6PWLnbTvo7MtjGMFQw4RA4SZ0u23vzUS7AD5Q)

Haskell package providing high-level access to [HTTPS Everywhere][1]
rulesets. This makes it easier to tell other programs: "I'd like if you
used secure HTTP connections when possible."

```haskell
λ: :m + Data.HTTPSEverywhere.Rules Network.URI
λ: let Just eff = parseURI "http://www.eff.org/document/eff-and-aclu-amicus-brief-klayman"
λ: rewriteURL eff
Just https://www.eff.org/document/eff-and-aclu-amicus-brief-klayman
λ: :m + Web.Cookie Network.HTTP.Client Data.Time.Clock Control.Applicative
λ: :set -XOverloadedStrings
λ: (now, req) <- (,) <$> getCurrentTime <*> parseUrl "https://github.com"
λ: let (Just gh, Just ck) = (parseURI "https://github.com", generateCookie (def{setCookieDomain=Just "github.com"}) req now True)
λ: rewriteCookie gh ck
Cookie {cookie_name = "name", cookie_value = "value", cookie_expiry_time = 3013-12-25 00:00:00 UTC, cookie_domain = "github.com", cookie_path = "/", cookie_creation_time = 2014-08-24 05:58:20.691866 UTC, cookie_last_access_time = 2014-08-24 05:58:20.691866 UTC, cookie_persistent = False, cookie_host_only = False, cookie_secure_only = True, cookie_http_only = False}
```

  [1]: https://www.eff.org/https-everywhere
