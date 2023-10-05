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
$ curl -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoidGVzdDExQHB1dGl0LmlvIiwidXNlcl90eXBlIjoid2ViIiwiZXhwIjoxNjk2NTc5MzAxLCJpYXQiOjE2OTY1MzYxMDEsImp0aSI6IjMxOWNiMzdiMzRkZDc0NGIyNTM1ZTczYTU3ZjhmNzViZjVmNTdmM2ZlMjI5OGJkNjgyYmJlMDAxMWE0OTlkNjcifQ.KFSuSmlUoaEfE4qZYz5IqW1rj8t11rpuNRrWOSbmb24" localhost:9292/application 
```