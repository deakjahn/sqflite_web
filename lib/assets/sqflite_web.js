requirejs.config({
  baseUrl: 'https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.2.2/dist',
  paths: {
    'initSqlJs': 'sql-wasm',
  }
});

var sqflite_web;

requirejs(['initSqlJs'], function(initSqlJs) {
  initSqlJs({
    locateFile: file => 'https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.2.2/dist/sql-wasm.wasm',
  }).then(function(SQL) {
    sqflite_web = {
      db: null,

      create: function() {
        sqflite_web.db = new SQL.Database();
      },

      open: function(data) {
        sqflite_web.db = new SQL.Database(data);
      },

      close: function() {
        sqflite_web.db.close();
        sqflite_web.db = null;
      },

      run: function(sql, params) {
        sqflite_web.db.run(sql, params);
      },

      execute: function(sql) {
        var result = sqflite_web.db.exec(sql);
// This supposes we never pass more than one SQL statement at once (it's prohibited if we pass arguments in, anyway). Is this OK?
        return result[0];
      },

      executeScalar: function(sql) {
        var result = sqflite_web.db.exec(sql);
        return result[0].values[0];
      },

      prepare: function(sql, params) {
        return sqflite_web.db.prepare(sql, params);
      },

      bind: function(statement, values) {
        return statement.bind(values);
      },

      step: function(statement) {
        return statement.step();
      },

      get: function(statement, params) {
        return statement.get(params);
      },

      getColumnNames: function(statement) {
        return statement.getColumnNames();
      },

      free: function(statement) {
        return statement.free();
      },

      getRowsModified: function() {
        return sqflite_web.db.getRowsModified();
      },
    };

    window.dispatchEvent(new Event('sqflite_web_ready'));
  });
});