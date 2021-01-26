# sqflite_web

These are the first steps to start a web version of [sqflite](https://pub.dev/packages/sqflite). Right now, it already runs and creates a test database and writes a few records.

Please, note that this is experimental. It's not on pub.dev and not automatically endorsed by Sqflite as the web implementation because these are just the first steps to see if it's feasible at all.

While the code itself is functional, the database stays in the memory. There is no persistence and copies of the same app running in different browser tabs would see different, separate databases.
Use it if it fits your requirements and suggest solutions to the missing functionality if you have ideas but don't expect it to be a full Sqflite implementation on the web.

## Install

Add this line in `index.html`:
```html
<body>
  <script src="assets/packages/sqflite_web/assets/require.js" type="application/javascript"></script>
  (...)
</body>
```

Note: The `require.js` library will be added dynamically if you forget to add this line in `index.html`
(but this will imply users do a 'refresh' of the web page every time they want to access it because of dynamic include issues).
