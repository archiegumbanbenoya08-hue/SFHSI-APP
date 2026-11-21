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
  await conn.query(
    `INSERT INTO activity_log
      (actor_role, actor_id, actor_email, action, entity_type, entity_id, parent_id, details)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
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
