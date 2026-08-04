const databaseName = process.env.MONGO_APP_DATABASE;
const username = process.env.MONGO_APP_USER;
const password = process.env.MONGO_APP_PASSWORD;

if (!databaseName || !username || !password) {
  throw new Error('MongoDB application account environment variables are required');
}

const applicationDatabase = db.getSiblingDB(databaseName);
if (!applicationDatabase.getUser(username)) {
  applicationDatabase.createUser({
    user: username,
    pwd: password,
    roles: [{ role: 'readWrite', db: databaseName }]
  });
}
