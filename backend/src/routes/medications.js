const { Hono } = require('hono');
const { z } = require('zod');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');

const router = new Hono();
router.use('*', authMiddleware);
const medicationSchema = z.object({
  name: z.string().trim().min(1),
  dosage: z.string().optional(),
  form: z.string().optional(),
  instructions: z.string().optional(),
  total_quantity: z.number().int().positive().optional(),

  dependent_id: z.coerce.number().int().positive().optional(),

  type: z.number().int().optional(),
  days_of_week: z.array(z.string()).optional(),
  period: z.string().optional(),
  time: z.string().optional(),
  doses_per_day: z.number().int().positive().optional()
});


// ===================================
// GET MEDICATIONS
// ===================================
router.get('/', async (c) => {

  const user = c.get('user');

  const dependentId =
    c.req.query('dependent_id');


  let result;



  // ===================================
  // طلب أدوية تابع
  // ===================================
  if (dependentId) {


    // تأكد أن المستخدم هو صاحب التابع
    const dependent = await pool.query(
      `
      SELECT id
      FROM dependents
      WHERE id=$1
      AND caregiver_user_id=$2
      `,
      [
        Number(dependentId),
        user.id
      ]
    );



    if (dependent.rows.length === 0) {

      return c.json(
        {
          error: 'ليس لديك صلاحية لهذا التابع'
        },
        403
      );

    }



    result = await pool.query(
      `
      SELECT *
      FROM medications
      WHERE dependent_id=$1
      ORDER BY created_at DESC
      `,
      [
        Number(dependentId)
      ]
    );


  }


  // ===================================
  // أدوية المستخدم الحالي فقط
  // ===================================
  else {


    result = await pool.query(
      `
      SELECT *
      FROM medications
      WHERE user_id=$1
      AND dependent_id IS NULL
      ORDER BY created_at DESC
      `,
      [
        user.id
      ]
    );


  }



  return c.json(result.rows);


});






// ===================================
// ADD MEDICATION
// ===================================
router.post('/', async (c) => {


  const user = c.get('user');


  const body =
    await c.req.json()
      .catch(() => ({}));



  const parsed =
    medicationSchema.safeParse(body);



  if (!parsed.success) {

    return c.json(
      {
        error: parsed.error.issues[0].message
      },
      400
    );

  }




  // ===================================
  // إذا الدواء للتابع
  // ===================================
  if (parsed.data.dependent_id) {


    const check =
      await pool.query(
        `
        SELECT id
        FROM dependents
        WHERE id=$1
        AND caregiver_user_id=$2
        `,
        [
          parsed.data.dependent_id,
          user.id
        ]
      );



    if (check.rows.length === 0) {

      return c.json(
        {
          error: 'تابع غير صالح'
        },
        403
      );

    }


  }
  const medication =
    await pool.createMedication({

      ...parsed.data,

      user_id: user.id,

      dependent_id:
        parsed.data.dependent_id || null

    });

  return c.json(
    medication,
    201
  );


});



module.exports = router;
// ===================================
// DELETE MEDICATION
// ===================================
router.delete('/:id', async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id');

    // 1. تحقق من وجود الدواء وصلاحية المستخدم
    const checkResult = await pool.query(
      `
      SELECT id, user_id, dependent_id
      FROM medications
      WHERE id = $1
      `,
      [id]
    );

    if (checkResult.rows.length === 0) {
      return c.json({ error: 'الدواء غير موجود' }, 404);
    }

    const medication = checkResult.rows[0];

    // 2. التحقق من الصلاحية
    // إذا كان الدواء للمستخدم الحالي
    if (medication.user_id === user.id) {
      // مسموح
    }
    // إذا كان الدواء لتابع
    else if (medication.dependent_id) {
      // تحقق أن المستخدم هو مالك التابع
      const dependentCheck = await pool.query(
        `
        SELECT id
        FROM dependents
        WHERE id = $1
        AND caregiver_user_id = $2
        `,
        [medication.dependent_id, user.id]
      );

      if (dependentCheck.rows.length === 0) {
        return c.json(
          { error: 'ليس لديك صلاحية لحذف هذا الدواء' },
          403
        );
      }
    }
    // ليس للمستخدم ولا لتابع
    else {
      return c.json(
        { error: 'ليس لديك صلاحية لحذف هذا الدواء' },
        403
      );
    }

    // 3. حذف الـ Schedules المرتبطة بالدواء أولاً
    await pool.query(
      `
      DELETE FROM schedules
      WHERE medication_id = $1
      `,
      [id]
    );

    // 4. حذف الدواء
    await pool.query(
      `
      DELETE FROM medications
      WHERE id = $1
      `,
      [id]
    );

    return c.json({
      message: 'تم حذف الدواء وجدولته بنجاح'
    });

  } catch (error) {
    console.error('Error deleting medication:', error);
    return c.json(
      { error: 'حدث خطأ أثناء حذف الدواء' },
      500
    );
  }
});
// ===================================
// UPDATE MEDICATION (PUT)
// ===================================
router.put('/:id', async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id');
    const body = await c.req.json().catch(() => ({}));

    console.log(`🔍 Updating medication ID: ${id} for user: ${user.id}`);
    console.log(`📦 Update data:`, body);

    // 1. تحقق من وجود الدواء وصلاحية المستخدم
    const checkResult = await pool.query(
      `
      SELECT id, user_id, dependent_id
      FROM medications
      WHERE id = $1
      `,
      [id]
    );

    if (checkResult.rows.length === 0) {
      console.log(`❌ Medication ${id} not found`);
      return c.json({ error: 'الدواء غير موجود' }, 404);
    }

    const medication = checkResult.rows[0];

    // 2. التحقق من الصلاحية
    if (medication.user_id === user.id) {
      console.log(`✅ User owns this medication`);
    } else if (medication.dependent_id) {
      const dependentCheck = await pool.query(
        `
        SELECT id
        FROM dependents
        WHERE id = $1
        AND caregiver_user_id = $2
        `,
        [medication.dependent_id, user.id]
      );

      if (dependentCheck.rows.length === 0) {
        console.log(`❌ User does not own dependent: ${medication.dependent_id}`);
        return c.json(
          { error: 'ليس لديك صلاحية لتعديل هذا الدواء' },
          403
        );
      }
      console.log(`✅ User owns the dependent`);
    } else {
      console.log(`❌ User has no permission`);
      return c.json(
        { error: 'ليس لديك صلاحية لتعديل هذا الدواء' },
        403
      );
    }

    // 3. بناء كائن التحديث (فقط الحقول المرسلة)
    const updates = {};
    const allowedFields = [
      'name', 'dosage', 'form', 'instructions', 
      'total_quantity', 'type', 'days_of_week', 
      'period', 'time', 'doses_per_day'
    ];

    for (const field of allowedFields) {
      if (body[field] !== undefined) {
        updates[field] = body[field];
      }
    }

    if (Object.keys(updates).length === 0) {
      return c.json({ error: 'لا توجد بيانات للتحديث' }, 400);
    }

    // 4. تنفيذ التحديث
    const setClause = Object.keys(updates)
      .map((key, index) => `${key} = $${index + 1}`)
      .join(', ');

    const values = [...Object.values(updates), id];

    const result = await pool.query(
      `
      UPDATE medications
      SET ${setClause}, updated_at = NOW()
      WHERE id = $${values.length}
      RETURNING *
      `,
      values
    );

    if (result.rows.length === 0) {
      return c.json({ error: 'فشل تحديث الدواء' }, 500);
    }

    console.log(`✅ Medication ${id} updated successfully`);
    return c.json(result.rows[0]);

  } catch (error) {
    console.error('❌ Error updating medication:', error);
    return c.json(
      { error: 'حدث خطأ أثناء تحديث الدواء' },
      500
    );
  }
});

// ===================================
// PATCH MEDICATION (تحديث جزئي)
// ===================================
router.patch('/:id', async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id');
    const body = await c.req.json().catch(() => ({}));

    console.log(`🔍 Patching medication ID: ${id} for user: ${user.id}`);
    console.log(`📦 Patch data:`, body);

    // 1. تحقق من وجود الدواء وصلاحية المستخدم
    const checkResult = await pool.query(
      `
      SELECT id, user_id, dependent_id
      FROM medications
      WHERE id = $1
      `,
      [id]
    );

    if (checkResult.rows.length === 0) {
      console.log(`❌ Medication ${id} not found`);
      return c.json({ error: 'الدواء غير موجود' }, 404);
    }

    const medication = checkResult.rows[0];

    // 2. التحقق من الصلاحية
    if (medication.user_id === user.id) {
      console.log(`✅ User owns this medication`);
    } else if (medication.dependent_id) {
      const dependentCheck = await pool.query(
        `
        SELECT id
        FROM dependents
        WHERE id = $1
        AND caregiver_user_id = $2
        `,
        [medication.dependent_id, user.id]
      );

      if (dependentCheck.rows.length === 0) {
        console.log(`❌ User does not own dependent: ${medication.dependent_id}`);
        return c.json(
          { error: 'ليس لديك صلاحية لتعديل هذا الدواء' },
          403
        );
      }
      console.log(`✅ User owns the dependent`);
    } else {
      console.log(`❌ User has no permission`);
      return c.json(
        { error: 'ليس لديك صلاحية لتعديل هذا الدواء' },
        403
      );
    }

    // 3. بناء كائن التحديث (فقط الحقول المرسلة)
    const updates = {};
    const allowedFields = [
      'name', 'dosage', 'form', 'instructions', 
      'total_quantity', 'type', 'days_of_week', 
      'period', 'time', 'doses_per_day'
    ];

    for (const field of allowedFields) {
      if (body[field] !== undefined) {
        updates[field] = body[field];
      }
    }

    if (Object.keys(updates).length === 0) {
      return c.json({ error: 'لا توجد بيانات للتحديث' }, 400);
    }

    // 4. تنفيذ التحديث
    const setClause = Object.keys(updates)
      .map((key, index) => `${key} = $${index + 1}`)
      .join(', ');

    const values = [...Object.values(updates), id];

    const result = await pool.query(
      `
      UPDATE medications
      SET ${setClause}, updated_at = NOW()
      WHERE id = $${values.length}
      RETURNING *
      `,
      values
    );

    if (result.rows.length === 0) {
      return c.json({ error: 'فشل تحديث الدواء' }, 500);
    }

    console.log(`✅ Medication ${id} patched successfully`);
    return c.json(result.rows[0]);

  } catch (error) {
    console.error('❌ Error patching medication:', error);
    return c.json(
      { error: 'حدث خطأ أثناء تحديث الدواء' },
      500
    );
  }
});