export async function recordActivity(
  conn,
  {
    actorRole,
    actorId = null,
    actorEmail = null,
    action,
    entityType = null,
    entityId = null,
    parentId = null,
    details = {},
  },
) {
  await conn.execute(
    `INSERT INTO activity_log
      (actor_role, actor_id, actor_email, action, entity_type, entity_id, parent_id, details)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      actorRole,
      actorId,
      actorEmail,
      action,
      entityType,
      entityId === null ? null : String(entityId),
      parentId,
      JSON.stringify(details),
    ],
  );
}
