const { Hono } = require('hono');
const { z } = require('zod');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');

const router = new Hono();

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