
const mPool = {
  query: jest.fn(),
};

class Pool {
  constructor() {
    return mPool;
  }
}

module.exports = {
  Pool,
};
