# Working with API, in few simple self explaining commands

1. Create user

(`putit-auth` needs to run in background)

```bash
$ curl -H "Content-Type: application/json" -X POST http://localhost:3000/users --data $(jo user=$(jo email=test11@putit.io password=123qwe password_confirmation=123qwe))
```

2. Authenticate user

```bash
$ curl -H "Content-Type: application/json" -X POST http://localhost:3000/users/sign_in --data $(jo user=$(jo email=test11@putit.io password=123qwe))
```

3. Query `putit-core` for applications

```bash
$ curl -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoidGVzdDEyQHB1dGl0LmlvIiwidXNlcl90eXBlIjoid2ViIiwiZXhwIjoxNjg2MTI4MDk3LCJpYXQiOjE2ODYwODQ4OTcsImp0aSI6IjI1Y2IyZDIwNTM1NjAwMmM0NDhiZjY2ZGExNzdkNjkyYTg4ZTAyNjJhMGZlNzQ5OTE4OTFmMmM0NGIxYjVjOTAifQ.bPKxX9qof7rhQY0uMaKFziiVgVJOGA69X9XyzX2hrxw" localhost:9292/application 
```