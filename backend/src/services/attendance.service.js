
const db = require('../../config/database');

  const recordAttendance = async (userId) => {
    const query = 'INSERT INTO attendance (user_id) VALUES ($1) RETURNING *';
    const values = [userId];
    const { rows } = await db.query(query, values);
    return rows[0];
    };

module.exports = {
    recordAttendance,
};
