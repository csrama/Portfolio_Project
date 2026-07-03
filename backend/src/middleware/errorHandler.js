function errorHandler(err, c) {
  console.error(err);
  const statusCode = err.statusCode || 500;
  return c.json(
    {
      error: err.message || 'Unexpected server error'
    },
    statusCode
  );
}

module.exports = { errorHandler };

