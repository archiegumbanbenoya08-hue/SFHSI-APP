import assert from 'node:assert/strict';
import test from 'node:test';
import { recordActivity } from '../services/activityLog.js';

test('recordActivity writes structured activity using bound values', async () => {
  let recordedQuery;
  let recordedValues;
  const connection = {
    async execute(query, values) {
      recordedQuery = query;
      recordedValues = values;
    },
  };

  await recordActivity(connection, {
    actorRole: 'admin',
    actorId: 7,
    actorEmail: 'admin@example.com',
    action: 'student.updated',
    entityType: 'student',
    entityId: 15,
    parentId: 4,
    details: { changed_fields: ['grade_level'] },
  });

  assert.match(recordedQuery, /INSERT INTO activity_log/);
  assert.deepEqual(recordedValues, [
    'admin',
    7,
    'admin@example.com',
    'student.updated',
    'student',
    '15',
    4,
    '{"changed_fields":["grade_level"]}',
  ]);
});

test('recordActivity supports system events without an account or student', async () => {
  let recordedValues;
  const connection = {
    async execute(_query, values) {
      recordedValues = values;
    },
  };

  await recordActivity(connection, {
    actorRole: 'system',
    action: 'admin.created',
    entityType: 'admin',
    entityId: 2,
  });

  assert.deepEqual(recordedValues, [
    'system',
    null,
    null,
    'admin.created',
    'admin',
    '2',
    null,
    '{}',
  ]);
});
